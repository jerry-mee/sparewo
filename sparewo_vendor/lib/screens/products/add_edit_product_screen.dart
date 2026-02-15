// lib/screens/products/add_edit_product_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/vendor_product.dart';
import '../../models/product_draft.dart';
import '../../models/vehicle_compatibility.dart';
import '../../providers/providers.dart';
import '../../providers/vendor_product_provider.dart';
import '../../providers/product_draft_provider.dart';
import '../../services/camera_service.dart';
import '../../services/ui_notification_service.dart';
import '../../theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/vehicle_compatibility_selector.dart';
import '../../constants/enums.dart';
import '../../utils/validators.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final VendorProduct? product;
  final String? draftId;

  const AddEditProductScreen({
    super.key,
    this.product,
    this.draftId,
  });

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _uiNotificationService = UINotificationService();

  // Draft management
  Timer? _autoSaveTimer;
  String? _currentDraftId;
  bool _hasUnsavedChanges = false;

  // Currency formatter
  final _currencyFormatter = NumberFormat.currency(
    locale: 'en_UG',
    symbol: '',
    decimalDigits: 0,
  );

  // Camera service instance
  late CameraService _cameraService;

  // Image management
  List<String> _existingImageUrls = [];
  List<String> _allImageUrls = [];

  // Product attributes
  List<VehicleCompatibility> _compatibility = [];
  PartCondition _condition = PartCondition.new_;
  ProductCategory _category = ProductCategory.accessories;
  String _qualityGrade = "A";
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _animationController.forward();

    if (widget.product != null) {
      _initializeProductData();
    } else if (widget.draftId != null) {
      _loadDraft();
    }

    // Initialize camera permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cameraService.initializePermissions();
      _setupAutoSave();
      _setupTextListeners();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _partNumberController.dispose();
    _animationController.dispose();

    // Save draft on dispose if there are unsaved changes
    if (_hasUnsavedChanges && widget.product == null) {
      _saveDraftSilently();
    }

    super.dispose();
  }

  void _initializeProductData() {
    final product = widget.product!;
    _nameController.text = product.partName;
    _descriptionController.text = product.description;
    _priceController.text = _currencyFormatter.format(product.unitPrice);
    _stockController.text = product.stockQuantity.toString();
    _existingImageUrls = List.from(product.images);
    _allImageUrls = List.from(product.images);
    _compatibility = List.from(product.compatibility);
    _condition = product.condition;
    _category = product.category;
    _brandController.text = product.brand;
    _partNumberController.text = product.partNumber ?? '';
    _qualityGrade = product.qualityGrade;
  }

  Future<void> _loadDraft() async {
    if (widget.draftId == null) return;

    final draftService = ref.read(productDraftServiceProvider);
    final draft = await draftService.getDraft(widget.draftId!);

    if (draft != null && mounted) {
      setState(() {
        _currentDraftId = draft.id;
        _nameController.text = draft.partName;
        _descriptionController.text = draft.description;
        _priceController.text = _currencyFormatter.format(draft.unitPrice);
        _stockController.text = draft.stockQuantity.toString();
        _brandController.text = draft.brand;
        _partNumberController.text = draft.partNumber ?? '';
        _allImageUrls = List.from(draft.images);
        _compatibility = List.from(draft.compatibility);
        _condition = draft.condition;
        _category = draft.category;
        _qualityGrade = draft.qualityGrade;
      });

      _uiNotificationService.showInfo('Draft loaded successfully');
    }
  }

  void _setupAutoSave() {
    if (widget.product != null) return;

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasUnsavedChanges) {
        _saveDraftSilently();
      }
    });
  }

  void _setupTextListeners() {
    _nameController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);
    _priceController.addListener(_markAsChanged);
    _stockController.addListener(_markAsChanged);
    _brandController.addListener(_markAsChanged);
    _partNumberController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveDraftSilently() async {
    if (widget.product != null) return;

    try {
      final draftService = ref.read(productDraftServiceProvider);
      await draftService.autoSaveDraft(
        draftId: _currentDraftId,
        partName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        unitPrice:
            double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        images: _allImageUrls,
        compatibility: _compatibility,
        condition: _condition,
        category: _category,
        qualityGrade: _qualityGrade,
        brand: _brandController.text.trim(),
        partNumber: _partNumberController.text.trim(),
      );

      setState(() {
        _hasUnsavedChanges = false;
      });
    } catch (e) {
      // Silent save - don't show errors
    }
  }

  Future<void> _saveDraft() async {
    if (widget.product != null) return;

    EasyLoading.show(status: 'Saving draft...');

    try {
      final draftService = ref.read(productDraftServiceProvider);
      final draft = ProductDraft(
        id: _currentDraftId ?? '',
        vendorId: ref.read(currentVendorIdProvider) ?? '',
        partName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        unitPrice:
            double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        images: _allImageUrls,
        compatibility: _compatibility,
        condition: _condition,
        category: _category,
        qualityGrade: _qualityGrade,
        brand: _brandController.text.trim(),
        partNumber: _partNumberController.text.trim(),
        isComplete: _isFormComplete(),
        lastModified: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final draftId = await draftService.saveDraft(draft);
      setState(() {
        _currentDraftId = draftId;
        _hasUnsavedChanges = false;
      });

      _uiNotificationService.showSuccess('Draft saved successfully');
    } catch (e) {
      _uiNotificationService.showError('Failed to save draft');
    } finally {
      EasyLoading.dismiss();
    }
  }

  bool _isFormComplete() {
    return _nameController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _brandController.text.trim().isNotEmpty &&
        (double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0) > 0 &&
        (int.tryParse(_stockController.text) ?? 0) > 0 &&
        _allImageUrls.isNotEmpty &&
        _compatibility.isNotEmpty;
  }

  Future<void> _takePhoto() async {
    if (!_cameraService.canAddMoreImages(_allImageUrls.length)) {
      _uiNotificationService.showError(
        'Maximum ${CameraService.maxImagesPerProduct} images allowed',
      );
      return;
    }

    EasyLoading.show(status: 'Taking photo...');

    try {
      final vendorId = ref.read(currentVendorIdProvider);
      final imageUrl = await _cameraService.takePhoto(
        productId: widget.product?.id,
        vendorId: vendorId,
      );

      if (imageUrl != null) {
        setState(() {
          _allImageUrls.add(imageUrl);
          _markAsChanged();
        });
        _uiNotificationService.showSuccess('Photo added successfully');
      }
    } catch (e) {
      _uiNotificationService.showError(
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _pickFromGallery() async {
    if (!_cameraService.canAddMoreImages(_allImageUrls.length)) {
      _uiNotificationService.showError(
        'Maximum ${CameraService.maxImagesPerProduct} images allowed',
      );
      return;
    }

    EasyLoading.show(status: 'Selecting images...');

    try {
      final vendorId = ref.read(currentVendorIdProvider);
      final remainingSlots =
          _cameraService.getRemainingImageSlots(_allImageUrls.length);

      if (remainingSlots == 1) {
        final imageUrl = await _cameraService.pickSingleImage(
          productId: widget.product?.id,
          vendorId: vendorId,
        );

        if (imageUrl != null) {
          setState(() {
            _allImageUrls.add(imageUrl);
            _markAsChanged();
          });
          _uiNotificationService.showSuccess('Image added successfully');
        }
      } else {
        final imageUrls = await _cameraService.pickMultipleImages(
          productId: widget.product?.id,
          vendorId: vendorId,
        );

        if (imageUrls.isNotEmpty) {
          setState(() {
            _allImageUrls.addAll(imageUrls);
            if (_allImageUrls.length > CameraService.maxImagesPerProduct) {
              _allImageUrls = _allImageUrls
                  .take(CameraService.maxImagesPerProduct)
                  .toList();
            }
            _markAsChanged();
          });
          _uiNotificationService.showSuccess(
            '${imageUrls.length} image(s) added successfully',
          );
        }
      }
    } catch (e) {
      _uiNotificationService.showError(
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _removeImage(String imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    EasyLoading.show(status: 'Removing image...');

    try {
      if (!_existingImageUrls.contains(imageUrl) &&
          imageUrl.startsWith('http')) {
        await _cameraService.deleteImage(imageUrl);
      }

      setState(() {
        _allImageUrls.remove(imageUrl);
        _markAsChanged();
      });
      _uiNotificationService.showSuccess('Image removed successfully');
    } catch (e) {
      _uiNotificationService.showError('Failed to remove image');
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      _uiNotificationService.showError('Please fix the errors in the form.');
      return;
    }
    if (_allImageUrls.isEmpty) {
      _uiNotificationService
          .showError('Please add at least one product image.');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final vendorId = ref.read(currentVendorIdProvider);
      if (vendorId == null) {
        throw Exception('No vendor ID available. Please sign in again.');
      }

      final productNotifier = ref.read(vendorProductsProvider.notifier);

      if (widget.product == null) {
        final newProduct = VendorProduct(
          id: const Uuid().v4(),
          vendorId: vendorId,
          partName: _nameController.text.trim(),
          brand: _brandController.text.trim(),
          description: _descriptionController.text.trim(),
          partNumber: _partNumberController.text.trim(),
          unitPrice: double.parse(_priceController.text.replaceAll(',', '')),
          stockQuantity: int.parse(_stockController.text),
          condition: _condition,
          category: _category,
          qualityGrade: _qualityGrade,
          images: _allImageUrls,
          compatibility: _compatibility,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ProductStatus.pending,
        );
        await productNotifier.addProductWithUrls(newProduct);

        if (_currentDraftId != null) {
          final draftService = ref.read(productDraftServiceProvider);
          await draftService.deleteDraft(_currentDraftId!);
        }
      } else {
        final updatedProduct = widget.product!.copyWith(
          partName: _nameController.text.trim(),
          brand: _brandController.text.trim(),
          description: _descriptionController.text.trim(),
          partNumber: _partNumberController.text.trim(),
          unitPrice: double.parse(_priceController.text.replaceAll(',', '')),
          stockQuantity: int.parse(_stockController.text),
          condition: _condition,
          category: _category,
          qualityGrade: _qualityGrade,
          images: _allImageUrls,
          compatibility: _compatibility,
          updatedAt: DateTime.now(),
        );
        await productNotifier.updateProductWithUrls(updatedProduct);
      }

      _uiNotificationService.showSuccess('Product saved!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _uiNotificationService
            .showError('Failed to save product: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAddMore = _cameraService.canAddMoreImages(_allImageUrls.length);
    final remainingSlots =
        _cameraService.getRemainingImageSlots(_allImageUrls.length);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                      Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                widget.product == null ? 'Add Product' : 'Edit Product',
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: widget.product == null
                ? [
                    if (_hasUnsavedChanges)
                      Container(
                        margin:
                            const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.save_as, color: Colors.white),
                          onPressed: _saveDraft,
                          tooltip: 'Save Draft',
                        ),
                      ),
                  ]
                : null,
          ),
          // Form Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Basic Information Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Basic Information',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall!
                                      .copyWith(
                                        fontSize: 18,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              controller: _nameController,
                              label: 'Product Name',
                              validator: (v) =>
                                  Validators.notEmpty(v, 'Product Name'),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _descriptionController,
                              label: 'Description',
                              maxLines: 3,
                              validator: (v) =>
                                  Validators.notEmpty(v, 'Description'),
                            ),
                            const SizedBox(height: 16),
                            // Category Dropdown
                            DropdownButtonFormField<ProductCategory>(
                              value: _category,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: const Icon(Icons.category),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardTheme.color ??
                                    Theme.of(context).colorScheme.surface,
                              ),
                              items: ProductCategory.values.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _category = value ?? _category;
                                  _markAsChanged();
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a category';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _brandController,
                                    label: 'Brand',
                                    validator: (v) =>
                                        Validators.notEmpty(v, 'Brand'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _partNumberController,
                                    label: 'Part Number (Optional)',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _priceController,
                                    label: 'Price (UGX)',
                                    prefixIcon: Icons.attach_money,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: false),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      _CurrencyInputFormatter(),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a price';
                                      }
                                      final numValue = int.tryParse(
                                          value.replaceAll(',', ''));
                                      if (numValue == null || numValue <= 0) {
                                        return 'Please enter a valid price';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _stockController,
                                    label: 'Stock Quantity',
                                    prefixIcon: Icons.inventory_2,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (v) =>
                                        Validators.notEmpty(v, 'Stock'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<PartCondition>(
                              value: _condition,
                              decoration: InputDecoration(
                                labelText: 'Condition',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardTheme.color ??
                                    Theme.of(context).colorScheme.surface,
                              ),
                              items: PartCondition.values.map((condition) {
                                return DropdownMenuItem(
                                  value: condition,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: condition == PartCondition.new_
                                              ? Theme.of(context)
                                                  .extension<
                                                      AppColorsExtension>()!
                                                  .success
                                              : Theme.of(context)
                                                  .extension<
                                                      AppColorsExtension>()!
                                                  .pending,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(condition.displayName),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _condition = value ?? _condition;
                                  _markAsChanged();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Vehicle Compatibility Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.directions_car_outlined,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Vehicle Compatibility',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall!
                                      .copyWith(
                                        fontSize: 18,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            VehicleCompatibilitySelector(
                              initialCompatibilities: _compatibility,
                              onChanged: (newCompatibility) {
                                setState(() {
                                  _compatibility = newCompatibility;
                                  _markAsChanged();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Images Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .extension<AppColorsExtension>()!
                                            .success
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.photo_library_outlined,
                                        color: Theme.of(context)
                                            .extension<AppColorsExtension>()!
                                            .success,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Product Images',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displaySmall!
                                              .copyWith(
                                                fontSize: 18,
                                              ),
                                        ),
                                        Text(
                                          '${_allImageUrls.length}/${CameraService.maxImagesPerProduct} images',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (canAddMore)
                                  Text(
                                    '$remainingSlots more',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_allImageUrls.isEmpty)
                              GestureDetector(
                                onTap: _pickFromGallery,
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                      style: BorderStyle.solid,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 40,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to add images',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _allImageUrls.length,
                                  itemBuilder: (context, index) {
                                    return _buildImageThumbnail(
                                        _allImageUrls[index], index);
                                  },
                                ),
                              ),
                            if (canAddMore) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _takePhoto,
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Camera'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        side: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _pickFromGallery,
                                      icon: Icon(kIsWeb
                                          ? Icons.upload_file
                                          : Icons.photo_library),
                                      label: Text(
                                          kIsWeb ? 'Upload Images' : 'Gallery'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        side: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.amber.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Maximum ${CameraService.maxImagesPerProduct} images reached',
                                        style: TextStyle(
                                          color: Colors.amber.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Image Tips:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• First image is the main display',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '• Use clear, well-lit photos',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '• Show different angles',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '• Max 5MB per image',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: LoadingButton(
                          onPressed: _saveProduct,
                          isLoading: _isLoading,
                          label: widget.product == null
                              ? 'Add Product'
                              : 'Save Changes',
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(String imageUrl, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Icon(
                    Icons.broken_image,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Main',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          GestureDetector(
            onTap: () => _removeImage(imageUrl),
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Currency Input Formatter
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all commas for processing
    String newText = newValue.text.replaceAll(',', '');

    // Parse to number
    final number = int.tryParse(newText);
    if (number == null) {
      return oldValue;
    }

    // Format with commas
    final formatter = NumberFormat('#,##0', 'en_US');
    String formattedText = formatter.format(number);

    // Calculate new cursor position
    int cursorPosition = formattedText.length;

    // Adjust cursor position based on comma additions
    int commasBefore = oldValue.text
            .substring(0, oldValue.selection.baseOffset)
            .split(',')
            .length -
        1;
    int commasAfter =
        formattedText.substring(0, cursorPosition).split(',').length - 1;
    int positionAdjustment = commasAfter - commasBefore;

    int newCursorPosition = newValue.selection.baseOffset + positionAdjustment;
    newCursorPosition = newCursorPosition.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }
}
