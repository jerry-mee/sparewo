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
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';

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
  final _vinController = TextEditingController();
  final _colourController = TextEditingController();
  final _engineSizeController = TextEditingController();

  static const List<String> _transmissionOptions = <String>[
    'Automatic',
    'Manual',
    'CVT',
    'Semi-automatic',
    'Dual-clutch',
    'Single-speed',
    'Other',
  ];

  // Vehicle Selection
  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;
  String? _selectedTransmission;

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
      _vinController.text = car.vin ?? '';
      _colourController.text = car.color ?? '';
      _engineSizeController.text = car.engineType ?? '';
      _selectedTransmission = car.transmission;
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
    _vinController.dispose();
    _colourController.dispose();
    _engineSizeController.dispose();
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
    } on FirebaseException catch (e, st) {
      AppLogger.error(
        'AddCarScreen',
        'Upload failed',
        error: '${e.code}: ${e.message}',
        stackTrace: st,
        extra: {'path': path},
      );
      return null;
    } catch (e) {
      AppLogger.error(
        'AddCarScreen',
        'Upload failed',
        error: e,
        extra: {'path': path},
      );
      // Return null on failure, we handle this in save to avoid crash
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(currentUserProvider);
    final user = authState.asData?.value;

    Widget buildScaffold({required bool isDesktop}) {
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
        body: authState.isLoading && !authState.hasValue
            ? const Center(child: CircularProgressIndicator())
            : user == null
            ? _buildGuestGate(context)
            : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 920 : 9999),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 28 : 24),
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
                            label: 'Number Plate',
                            hint: 'UBB 123A',
                            icon: Icons.tag,
                            textCapitalization: TextCapitalization.characters,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _vinController,
                            label: 'VIN',
                            hint: '17-character VIN',
                            icon: Icons.confirmation_number_outlined,
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _colourController,
                            label: 'Colour',
                            hint: 'e.g. Alpine White',
                            icon: Icons.palette_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTransmissionField(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _engineSizeController,
                            label: 'Engine Size',
                            hint: 'e.g. 2.0L',
                            icon: Icons.settings_input_component_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _mileageController,
                            label: 'Current Mileage (km)',
                            hint: 'e.g. 85,000',
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
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
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
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.8),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 520;
                              if (isNarrow) {
                                return Column(
                                  children: [
                                    _buildImagePicker(
                                      label: 'Front View (Required)',
                                      file: _frontImageFile,
                                      existingUrl: _existingFrontUrl,
                                      onTap: () => _showImageSourceSheet(true),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildImagePicker(
                                      label: 'Side View',
                                      file: _sideImageFile,
                                      existingUrl: _existingSideUrl,
                                      onTap: () => _showImageSourceSheet(false),
                                    ),
                                  ],
                                );
                              }

                              return Row(
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
                              );
                            },
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
                              if (picked != null) {
                                setState(() => _lastServiceDate = picked);
                              }
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
                                    DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _insuranceExpiryDate = picked);
                              }
                            },
                          ),

                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _saveCar,
                              child: Text(
                                isEditing ? 'Update Vehicle' : 'Save Vehicle',
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      );
    }

    return ResponsiveScreen(
      mobile: buildScaffold(isDesktop: false),
      desktop: buildScaffold(isDesktop: true),
    );
  }

  Widget _buildGuestGate(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppShadows.cardShadow,
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.garage_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Save vehicles to your garage',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to add vehicle photos, service dates, and maintenance records that sync across your devices.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.hintColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.6),
                      builder: (context) => AuthGuardModal(
                        title: 'Log in to add a vehicle',
                        message:
                            'Create an account to save your vehicle details and photos securely.',
                        returnTo: GoRouterState.of(context).uri.toString(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Log in / Register'),
                ),
              ],
            ),
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
    bool isRequired = false,
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
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _buildTransmissionField() {
    final options = <String>[..._transmissionOptions];
    final current = _selectedTransmission?.trim();
    if (current != null && current.isNotEmpty && !options.contains(current)) {
      options.insert(0, current);
    }

    return DropdownButtonFormField<String>(
      initialValue:
          (_selectedTransmission != null &&
              _selectedTransmission!.trim().isNotEmpty)
          ? _selectedTransmission
          : null,
      decoration: const InputDecoration(
        labelText: 'Transmission',
        prefixIcon: Icon(Icons.sync_alt_outlined),
      ),
      items: options
          .map(
            (option) =>
                DropdownMenuItem<String>(value: option, child: Text(option)),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedTransmission = value),
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
            Icon(
              Icons.event,
              color: theme.iconTheme.color?.withValues(alpha: 0.7),
            ),
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

    final hasFrontImage =
        _frontImageFile != null ||
        (_existingFrontUrl != null && _existingFrontUrl!.trim().isNotEmpty);
    if (!hasFrontImage) {
      EasyLoading.showError('Please add a front vehicle photo.');
      return;
    }

    EasyLoading.show(status: 'Saving...');
    try {
      String? frontUrl = _existingFrontUrl;
      String? sideUrl = _existingSideUrl;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageBase = 'cars/${user.id}/$timestamp';

      // Upload Front Image
      if (_frontImageFile != null) {
        final uploaded = await _uploadImage(
          _frontImageFile!,
          '${storageBase}_front.jpg',
        );
        if (uploaded != null) {
          frontUrl = uploaded;
        } else {
          EasyLoading.dismiss();
          EasyLoading.showError('Front image upload failed. Please try again.');
          return;
        }
      }

      // Upload Side Image
      if (_sideImageFile != null) {
        final uploaded = await _uploadImage(
          _sideImageFile!,
          '${storageBase}_side.jpg',
        );
        if (uploaded != null) {
          sideUrl = uploaded;
        } else {
          EasyLoading.showInfo('Side image could not be uploaded.');
        }
      }

      final car = CarModel(
        id: isEditing ? widget.carToEdit!.id : '',
        userId: user.id, // Explicitly use user ID
        make: _selectedMake!,
        model: _selectedModel!,
        year: _selectedYear!,
        plateNumber: _plateController.text.trim(),
        vin: _normaliseOptional(_vinController.text),
        color: _normaliseOptional(_colourController.text),
        transmission: _normaliseOptional(_selectedTransmission),
        engineType: _normaliseOptional(_engineSizeController.text),
        mileage: _parseMileage(_mileageController.text),
        lastServiceDate: _lastServiceDate,
        insuranceExpiryDate: _insuranceExpiryDate,
        frontImageUrl: (frontUrl?.trim().isNotEmpty ?? false)
            ? frontUrl!.trim()
            : null,
        sideImageUrl: (sideUrl?.trim().isNotEmpty ?? false)
            ? sideUrl!.trim()
            : null,
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

  String? _normaliseOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  int? _parseMileage(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
}
