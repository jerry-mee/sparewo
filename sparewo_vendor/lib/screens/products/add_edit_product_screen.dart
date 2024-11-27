import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/vehicle_compatibility.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../services/feedback_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/year_range_selector.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final CarPart? product;

  const AddEditProductScreen({
    super.key,
    this.product,
  });

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _feedbackService = FeedbackService();

  List<String> _images = [];
  List<VehicleCompatibility> _compatibleVehicles = [];
  PartCondition _condition = PartCondition.new_;
  bool _isLoading = false;
  bool _hasChanges = false;

  // Brand and model selection state
  String? _selectedBrand;
  String? _selectedModel;
  List<int> _selectedYears = [];

  // List of available brands from the loaded data
  final List<String> _availableBrands = [
    'TOYOTA',
    'HONDA',
    'NISSAN',
    'MAZDA',
    'MITSUBISHI',
    'SUBARU',
    'SUZUKI',
    // Add other brands from your data
  ];

  // Map of brand to their models
  final Map<String, List<String>> _brandModels = {
    'TOYOTA': [
      'COROLLA',
      'CAMRY',
      'RAV4',
      'LAND CRUISER',
      // Add other Toyota models
    ],
    'HONDA': [
      'CIVIC',
      'ACCORD',
      'CR-V',
      // Add other Honda models
    ],
    // Add other brands and their models
  };

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _initializeProductData();
    }
  }

  void _initializeProductData() {
    final product = widget.product!;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _quantityController.text = product.quantity.toString();
    _images = List.from(product.images);
    _compatibleVehicles = List.from(product.compatibleVehicles);
    _condition = product.isNew ? PartCondition.new_ : PartCondition.used;
  }

  Future<void> _pickImages(bool fromCamera) async {
    try {
      final picker = ImagePicker();
      final pickedFile = fromCamera
          ? await picker.pickImage(source: ImageSource.camera)
          : await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _images.add(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _addCompatibility() {
    if (_selectedBrand != null &&
        _selectedModel != null &&
        _selectedYears.isNotEmpty) {
      setState(() {
        _compatibleVehicles.add(
          VehicleCompatibility(
            brand: _selectedBrand!,
            model: _selectedModel!,
            compatibleYears: _selectedYears,
          ),
        );
        _selectedBrand = null;
        _selectedModel = null;
        _selectedYears = [];
        _hasChanges = true;
      });
    }
  }

  void _removeCompatibility(int index) {
    setState(() {
      _compatibleVehicles.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      await _feedbackService.error();
      return;
    }

    if (_compatibleVehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one compatible vehicle'),
          backgroundColor: VendorColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await _feedbackService.buttonTap();

    try {
      final vendorId = ref.read(currentVendorIdProvider);
      if (vendorId == null) throw Exception('No vendor ID available');

      final carPart = CarPart(
        id: widget.product?.id ?? '',
        vendorId: vendorId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        condition: _condition.displayName,
        images: _images,
        compatibleVehicles: _compatibleVehicles,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.product == null) {
        await ref.read(productsProvider.notifier).addProduct(carPart);
      } else {
        await ref.read(productsProvider.notifier).updateProduct(carPart);
      }

      await _feedbackService.success();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      await _feedbackService.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: VendorColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() => _hasChanges = true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInformation(),
            const SizedBox(height: 24),
            _buildCompatibilitySection(),
            const SizedBox(height: 24),
            _buildImagesSection(),
            const SizedBox(height: 32),
            LoadingButton(
              onPressed: _saveProduct,
              isLoading: _isLoading,
              label: widget.product == null ? 'Add Product' : 'Save Changes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information', style: VendorTextStyles.heading3),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _nameController,
          label: 'Part Name',
          prefixIcon: Icons.inventory,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter a part name' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _descriptionController,
          label: 'Description',
          prefixIcon: Icons.description,
          maxLines: 3,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter a description' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _priceController,
                label: 'Price',
                prefixIcon: Icons.attach_money,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter a price';
                  if (double.tryParse(value!) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _quantityController,
                label: 'Quantity',
                prefixIcon: Icons.inventory_2,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter quantity';
                  if (int.tryParse(value!) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<PartCondition>(
          value: _condition,
          decoration: const InputDecoration(
            labelText: 'Condition',
            prefixIcon: Icon(Icons.assessment),
          ),
          items: PartCondition.values.map((condition) {
            return DropdownMenuItem(
              value: condition,
              child: Text(condition.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _condition = value;
                _hasChanges = true;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildCompatibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Compatible Vehicles', style: VendorTextStyles.heading3),
        const SizedBox(height: 16),
        // Brand Dropdown
        DropdownButtonFormField<String>(
          value: _selectedBrand,
          decoration: const InputDecoration(
            labelText: 'Brand',
            prefixIcon: Icon(Icons.directions_car),
          ),
          items: _availableBrands.map((brand) {
            return DropdownMenuItem(value: brand, child: Text(brand));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBrand = value;
              _selectedModel = null; // Reset model when brand changes
            });
          },
        ),
        const SizedBox(height: 16),
        // Model Dropdown
        DropdownButtonFormField<String>(
          value: _selectedModel,
          decoration: const InputDecoration(
            labelText: 'Model',
            prefixIcon: Icon(Icons.model_training),
          ),
          items: _selectedBrand != null
              ? _brandModels[_selectedBrand]?.map((model) {
                  return DropdownMenuItem(value: model, child: Text(model));
                }).toList()
              : [],
          onChanged: _selectedBrand != null
              ? (value) {
                  setState(() {
                    _selectedModel = value;
                  });
                }
              : null,
        ),
        const SizedBox(height: 16),
        // Year Range Selector
        YearRangeSelector(
          selectedYears: _selectedYears,
          onYearsChanged: (years) {
            setState(() {
              _selectedYears = years;
            });
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addCompatibility,
          icon: const Icon(Icons.add),
          label: const Text('Add Compatibility'),
        ),
        const SizedBox(height: 16),
        _buildCompatibilityList(),
      ],
    );
  }

  Widget _buildCompatibilityList() {
    return Column(
      children: [
        for (var i = 0; i < _compatibleVehicles.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                '${_compatibleVehicles[i].brand} ${_compatibleVehicles[i].model}',
              ),
              subtitle: Text(
                'Years: ${_compatibleVehicles[i].compatibleYears.join(", ")}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: VendorColors.error),
                onPressed: () => _removeCompatibility(i),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Images', style: VendorTextStyles.heading3),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImages(false),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _pickImages(true),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_images.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(_images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: VendorColors.error,
                        ),
                        onPressed: () {
                          setState(() {
                            _images.removeAt(index);
                            _hasChanges = true;
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
