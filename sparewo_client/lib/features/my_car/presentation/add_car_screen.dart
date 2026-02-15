// lib/features/my_car/presentation/add_car_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/my_car/application/car_provider.dart';
import 'package:sparewo_client/features/my_car/domain/car_model.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sparewo_client/features/autohub/presentation/widgets/vehicle_search_widget.dart';

class AddCarScreen extends ConsumerStatefulWidget {
  final CarModel? carToEdit;

  const AddCarScreen({super.key, this.carToEdit});

  @override
  ConsumerState<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends ConsumerState<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _mileageController = TextEditingController();

  // Vehicle Selection
  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;

  DateTime? _lastServiceDate;
  DateTime? _insuranceExpiryDate;

  // Images
  File? _frontImageFile;
  File? _sideImageFile;
  String? _existingFrontUrl;
  String? _existingSideUrl;

  final ImagePicker _picker = ImagePicker();

  bool get isEditing => widget.carToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final car = widget.carToEdit!;
      _selectedMake = car.make;
      _selectedModel = car.model;
      _selectedYear = car.year;
      _plateController.text = car.plateNumber ?? '';
      _mileageController.text = car.mileage?.toString() ?? '';
      _lastServiceDate = car.lastServiceDate;
      _insuranceExpiryDate = car.insuranceExpiryDate;
      _existingFrontUrl = car.frontImageUrl;
      _existingSideUrl = car.sideImageUrl;
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  // --- Image Picking Logic (Camera OR Gallery) ---
  Future<void> _showImageSourceSheet(bool isFront) async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isFront);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isFront);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Compress to save size (~300kb target)
        maxWidth: 1080,
      );

      if (image != null) {
        setState(() {
          if (isFront) {
            _frontImageFile = File(image.path);
          } else {
            _sideImageFile = File(image.path);
          }
        });
        AppLogger.info('AddCarScreen', 'Image picked: ${image.path}');
      }
    } catch (e) {
      AppLogger.error('AddCarScreen', 'Failed to pick image', error: e);
      EasyLoading.showError('Could not select image. Check permissions.');
    }
  }

  Future<String?> _uploadImage(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('AddCarScreen', 'Upload failed', error: e);
      // Return null on failure, we handle this in save to avoid crash
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _deleteCar,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehicle Details', style: AppTextStyles.h3),
              const SizedBox(height: 24),

              VehicleSearchWidget(
                initialBrand: _selectedMake,
                initialModel: _selectedModel,
                initialYear: _selectedYear,
                onVehicleSelected: (brand, model, year) {
                  setState(() {
                    _selectedMake = brand;
                    _selectedModel = model;
                    _selectedYear = year;
                  });
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _plateController,
                label: 'Plate Number',
                hint: 'UBB 123A',
                icon: Icons.tag,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _mileageController,
                label: 'Current Mileage (km)',
                hint: 'e.g. 85000',
                icon: Icons.speed,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),

              // --- UPDATED PHOTOS SECTION ---
              Text('Vehicle Photos', style: AppTextStyles.h3),
              const SizedBox(height: 8),

              // Gentle Guide Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "We verify your plate number against the front photo to ensure total security and accuracy for your orders. A clear side photo helps us match the exact trim!",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.8,
                          ),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildImagePicker(
                      label: 'Front View (Required)',
                      file: _frontImageFile,
                      existingUrl: _existingFrontUrl,
                      onTap: () => _showImageSourceSheet(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImagePicker(
                      label: 'Side View',
                      file: _sideImageFile,
                      existingUrl: _existingSideUrl,
                      onTap: () => _showImageSourceSheet(false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Text('Maintenance', style: AppTextStyles.h3),
              const SizedBox(height: 24),

              _buildDatePicker(
                label: 'Last Service Date',
                date: _lastServiceDate,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _lastServiceDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _lastServiceDate = picked);
                },
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                label: 'Insurance Expiry',
                date: _insuranceExpiryDate,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        _insuranceExpiryDate ??
                        DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null)
                    setState(() => _insuranceExpiryDate = picked);
                },
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _saveCar,
                  child: Text(isEditing ? 'Update Vehicle' : 'Save Vehicle'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    File? file,
    String? existingUrl,
    required VoidCallback onTap,
  }) {
    final hasImage =
        file != null || (existingUrl != null && existingUrl.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                style: hasImage ? BorderStyle.solid : BorderStyle.none,
              ),
              boxShadow: hasImage ? AppShadows.cardShadow : [],
              image: hasImage
                  ? DecorationImage(
                      image: file != null
                          ? FileImage(file)
                          : NetworkImage(existingUrl!) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !hasImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        color: Theme.of(context).hintColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: (value) {
        if ((label == 'Plate Number') && (value == null || value.isEmpty)) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(Icons.event, color: theme.iconTheme.color?.withOpacity(0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date)
                        : 'Not set',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMake == null ||
        _selectedModel == null ||
        _selectedYear == null) {
      EasyLoading.showError('Please select vehicle details');
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      EasyLoading.showError("You must be logged in to add a car.");
      return;
    }

    EasyLoading.show(status: 'Saving...');
    try {
      String? frontUrl = _existingFrontUrl;
      String? sideUrl = _existingSideUrl;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Upload Front Image
      if (_frontImageFile != null) {
        final uploaded = await _uploadImage(
          _frontImageFile!,
          'cars/${timestamp}_front.jpg',
        );
        if (uploaded != null) {
          frontUrl = uploaded;
        } else {
          // Upload failed, but we continue.
          // Note: If CarModel expects non-null, we must ensure we pass empty string or handle it.
        }
      }

      // Upload Side Image
      if (_sideImageFile != null) {
        final uploaded = await _uploadImage(
          _sideImageFile!,
          'cars/${timestamp}_side.jpg',
        );
        if (uploaded != null) sideUrl = uploaded;
      }

      final car = CarModel(
        id: isEditing ? widget.carToEdit!.id : '',
        userId: user.id, // Explicitly use user ID
        make: _selectedMake!,
        model: _selectedModel!,
        year: _selectedYear!,
        plateNumber: _plateController.text.trim(),
        mileage: int.tryParse(_mileageController.text.trim()),
        lastServiceDate: _lastServiceDate,
        insuranceExpiryDate: _insuranceExpiryDate,
        // Ensure strictly NO NULLS for strings to prevent JSON deserialization crashes
        frontImageUrl: frontUrl ?? '',
        sideImageUrl: sideUrl ?? '',
        isDefault: isEditing ? widget.carToEdit!.isDefault : true,
        createdAt: isEditing ? widget.carToEdit!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await ref.read(carNotifierProvider.notifier).updateCar(car);
      } else {
        await ref.read(carNotifierProvider.notifier).addCar(car);
      }

      EasyLoading.dismiss();
      if (mounted) context.pop();
    } catch (e) {
      AppLogger.error('AddCarScreen', 'Save error', error: e);
      EasyLoading.showError('Failed: $e');
    }
  }

  Future<void> _deleteCar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      EasyLoading.show(status: 'Deleting...');
      await ref
          .read(carNotifierProvider.notifier)
          .deleteCar(widget.carToEdit!.id);
      EasyLoading.dismiss();
      if (mounted) context.go('/my-cars');
    }
  }
}
