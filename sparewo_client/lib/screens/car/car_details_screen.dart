import 'package:flutter/material.dart';
import '../../constants/theme.dart';

class CarDetailsScreen extends StatelessWidget {
  final String model;
  final String year;
  final String mileage;
  final String lastServiceDate;
  final String tyreType;
  final String motorThirdPartyExpiry;

  const CarDetailsScreen({
    super.key,
    required this.model,
    required this.year,
    required this.mileage,
    required this.lastServiceDate,
    required this.tyreType,
    required this.motorThirdPartyExpiry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Details', style: AppTextStyles.heading2),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Model', model),
            _buildDetailRow('Year', year),
            _buildDetailRow('Mileage', mileage),
            _buildDetailRow('Last Service Date', lastServiceDate),
            _buildDetailRow('Tyre Type', tyreType),
            _buildDetailRow('Motor Third-Party Expiry', motorThirdPartyExpiry),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body1,
            ),
          ),
        ],
      ),
    );
  }
}
