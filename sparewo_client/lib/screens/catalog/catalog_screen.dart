import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../constants/theme.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  final String? category;

  const CatalogScreen({super.key, this.category});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String? selectedBrand;
  String? selectedModel;
  String? selectedYear;
  final searchController = TextEditingController();
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    try {
      await Future.wait([
        dataProvider.loadProducts(
          categoryId: getCategoryId(widget.category),
        ),
        dataProvider.loadCarBrands(),
      ]);
    } catch (e) {
      _handleError('Failed to load initial data');
    } finally {
      if (mounted) {
        setState(() => _isInitialLoad = false);
      }
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadInitialData,
        ),
      ),
    );
  }

  int? getCategoryId(String? categoryName) {
    if (categoryName == null) return null;

    const categoryIds = {
      'Body Kits': 9,
      'Tyres': 18,
      'Electricals': 4,
      'Accessories': 12,
      'Chassis': 14,
      'Engine': 7,
    };

    return categoryIds[categoryName];
  }

  Future<void> _onBrandChanged(String? value) async {
    setState(() {
      selectedBrand = value;
      selectedModel = null;
    });

    if (value != null && mounted) {
      await Provider.of<DataProvider>(context, listen: false)
          .loadCarModels(value);
    }
  }

  Future<void> _onModelChanged(String? value) async {
    setState(() {
      selectedModel = value;
    });
    await _refreshProducts();
  }

  Future<void> _onYearChanged(String? value) async {
    setState(() {
      selectedYear = value;
    });
    await _refreshProducts();
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search parts...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: _debounceSearch,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Consumer<DataProvider>(
                builder: (context, provider, _) => _buildBrandFilter(provider),
              ),
              const SizedBox(width: 16),
              Consumer<DataProvider>(
                builder: (context, provider, _) => _buildModelFilter(provider),
              ),
              const SizedBox(width: 16),
              _buildYearFilter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandFilter(DataProvider provider) {
    final brands = provider.carBrands;
    return DropdownButton<String>(
      hint: const Text('Select Brand'),
      value: selectedBrand,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All Brands'),
        ),
        ...brands.map((brand) => DropdownMenuItem<String>(
              value: brand['id']?.toString(),
              child: Text(brand['part_name'] ?? ''),
            )),
      ],
      onChanged: _onBrandChanged,
    );
  }

  Widget _buildModelFilter(DataProvider provider) {
    if (selectedBrand == null) return const SizedBox.shrink();

    final models = provider.carModels;
    return DropdownButton<String>(
      hint: const Text('Select Model'),
      value: selectedModel,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All Models'),
        ),
        ...models.map((model) => DropdownMenuItem<String>(
              value: model['model'] as String?,
              child: Text(model['model'] ?? ''),
            )),
      ],
      onChanged: _onModelChanged,
    );
  }

  Widget _buildYearFilter() {
    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 1950 + 1,
      (index) => (currentYear - index).toString(),
    );

    return DropdownButton<String>(
      hint: const Text('Year'),
      value: selectedYear,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All Years'),
        ),
        ...years.map((year) => DropdownMenuItem<String>(
              value: year,
              child: Text(year),
            )),
      ],
      onChanged: _onYearChanged,
    );
  }

  Widget _buildProductList() {
    return Consumer<DataProvider>(
      builder: (context, provider, _) {
        if (_isInitialLoad) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildErrorState(provider.error!);
        }

        if (provider.products.isEmpty) {
          return Center(
            child: Text('No products found', style: AppTextStyles.body1),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: provider.products.length,
          itemBuilder: (context, index) => ProductCard(
            product: provider.products[index],
            onTap: () => _navigateToProductDetail(provider.products[index]),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppTextStyles.body1.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToProductDetail(Map<String, dynamic> product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  Future<void> _refreshProducts() async {
    if (!mounted) return;
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    try {
      await dataProvider.loadProducts(
        categoryId: getCategoryId(widget.category),
        carModel: selectedModel,
        year: selectedYear,
      );
    } catch (e) {
      _handleError('Failed to refresh products');
    }
  }

  void _debounceSearch(String value) {
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted || searchController.text != value) return;

      await Provider.of<DataProvider>(context, listen: false).loadProducts(
        categoryId: getCategoryId(widget.category),
        search: value,
        carModel: selectedModel,
        year: selectedYear,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category ?? 'All Parts',
          style: AppTextStyles.heading3,
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchAndFilter(),
              const SizedBox(height: 16),
              Expanded(child: _buildProductList()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildProductImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? 'Unknown Product',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UGX ${product['selling_price'] ?? 0}',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(8),
        ),
        image: DecorationImage(
          image: NetworkImage(
            product['product_img'] != null
                ? 'https://sparewo.matchstick.ug/uploads/${product['product_img']}'
                : 'https://via.placeholder.com/150',
          ),
          fit: BoxFit.cover,
          onError: (_, __) =>
              const NetworkImage('https://via.placeholder.com/150'),
        ),
      ),
    );
  }
}
