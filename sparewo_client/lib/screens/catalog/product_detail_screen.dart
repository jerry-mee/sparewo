import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../constants/theme.dart';
import '../../services/feedback_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int quantity = 1;
  bool _isLoading = false;
  final FeedbackService _feedbackService = FeedbackService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  void _incrementQuantity() {
    final inStock =
        int.tryParse(widget.product['in_stock']?.toString() ?? '0') ?? 0;
    if (quantity < inStock) {
      setState(() {
        quantity++;
      });
    } else {
      _showErrorSnackBar('Cannot exceed available stock ($inStock items)');
    }
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    final errorMessage = message.replaceAll(
      RegExp(r'Exception: |RangeError \(.*?\): |ApiException: '),
      '',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorMessage.length > 100
              ? '${errorMessage.substring(0, 100)}...'
              : errorMessage,
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message, {VoidCallback? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: action != null
            ? SnackBarAction(
                label: 'VIEW CART',
                textColor: Colors.white,
                onPressed: action,
              )
            : null,
      ),
    );
  }

  Future<void> _handleAddToCart(DataProvider dataProvider) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _feedbackService.buttonTap();
      await dataProvider.addToCart(widget.product, quantity);

      if (!mounted) return;

      _showSuccessSnackBar(
        '${widget.product['title']} added to cart',
        action: () => Navigator.pushNamed(context, '/cart'),
      );

      await _feedbackService.success();
    } catch (e) {
      await _feedbackService.error();
      _showErrorSnackBar(e.toString());
      debugPrint('Error adding to cart: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBuyNow(DataProvider dataProvider) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _feedbackService.buttonTap();
      await dataProvider.addToCart(widget.product, quantity);

      if (!mounted) return;

      await Navigator.pushNamed(context, '/cart');
      await _feedbackService.success();
    } catch (e) {
      await _feedbackService.error();
      _showErrorSnackBar(e.toString());
      debugPrint('Error buying now: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inStock =
        int.tryParse(widget.product['in_stock']?.toString() ?? '0') ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product['title'] ?? 'Product Details',
          style: AppTextStyles.heading3,
        ),
        backgroundColor: AppColors.primary,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImage(),
                const SizedBox(height: 16),
                _buildProductInfo(),
                const SizedBox(height: 16),
                _buildQuantitySelector(inStock),
                const SizedBox(height: 16),
                _buildProductDetails(),
                const SizedBox(height: 24),
                if (inStock > 0) _buildActionButtons() else _buildOutOfStock(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final imageUrl = widget.product['product_img'];
    const placeholderUrl =
        'https://via.placeholder.com/300x300/cccccc/000000&text=No+Image';

    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          (imageUrl != null && imageUrl.isNotEmpty)
              ? 'https://sparewo.matchstick.ug/uploads/$imageUrl'
              : placeholderUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product['title'] ?? 'Unknown Product',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'UGX ${widget.product['selling_price'] ?? 0}',
              style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            if (widget.product['original_price'] != null)
              Text(
                'UGX ${widget.product['original_price']}',
                style: AppTextStyles.body2.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Brand: ${widget.product['brand'] ?? 'Unknown'}',
          style: AppTextStyles.body2,
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(int inStock) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quantity:', style: AppTextStyles.body1),
                Text(
                  'In Stock: $inStock',
                  style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _decrementQuantity,
                  padding: const EdgeInsets.all(8),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    quantity.toString(),
                    style: AppTextStyles.body1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _incrementQuantity,
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Details', style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        Text(
          widget.product['product_description'] ?? 'No description available.',
          style: AppTextStyles.body1,
        ),
        if (widget.product['part_number'] != null) ...[
          const SizedBox(height: 8),
          Text(
            'Part Number: ${widget.product['part_number']}',
            style: AppTextStyles.body2,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : () => _handleAddToCart(dataProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  disabledBackgroundColor: AppColors.secondary.withOpacity(0.5),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Add to Cart',
                        style:
                            AppTextStyles.button.copyWith(color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : () => _handleBuyNow(dataProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Buy Now',
                        style:
                            AppTextStyles.button.copyWith(color: Colors.white),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOutOfStock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Out of Stock',
        style: AppTextStyles.button.copyWith(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
