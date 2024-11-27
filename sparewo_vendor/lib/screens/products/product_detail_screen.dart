import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/products/edit',
                  arguments: product);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImages(),
            const SizedBox(height: 16),
            _buildProductInfo(),
            const SizedBox(height: 16),
            _buildStockDetails(),
            const SizedBox(height: 16),
            _buildDescription(),
            const SizedBox(height: 16),
            _buildCompatibleModels(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImages() {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: product.images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.images[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          style: VendorTextStyles.heading1,
        ),
        const SizedBox(height: 8),
        Text(
          'UGX ${product.price.toStringAsFixed(2)}',
          style:
              VendorTextStyles.heading2.copyWith(color: VendorColors.primary),
        ),
      ],
    );
  }

  Widget _buildStockDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _DetailRow(
            label: 'Stock Quantity',
            value: '${product.stockQuantity} units',
          ),
          _DetailRow(
            label: 'Car Model',
            value: product.carModel,
          ),
          _DetailRow(
            label: 'Year',
            value: product.yearOfManufacture,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: VendorTextStyles.heading2,
        ),
        const SizedBox(height: 8),
        Text(
          product.description,
          style: VendorTextStyles.body1,
        ),
      ],
    );
  }

  Widget _buildCompatibleModels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compatible Models',
          style: VendorTextStyles.heading2,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: product.compatibleModels.map((model) {
            return Chip(
              label: Text(model),
              backgroundColor: VendorColors.primary.withOpacity(0.1),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: VendorTextStyles.body2),
          Text(value, style: VendorTextStyles.body2),
        ],
      ),
    );
  }
}
