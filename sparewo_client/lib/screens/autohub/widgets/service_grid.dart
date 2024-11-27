// lib/screens/autohub/widgets/service_grid.dart

import 'package:flutter/material.dart';
import '../../../constants/theme.dart';

class ServiceGrid extends StatelessWidget {
  final String selectedService;
  final Function(String) onServiceSelect;

  const ServiceGrid({
    super.key,
    required this.selectedService,
    required this.onServiceSelect,
  });

  // Main services with icons
  static const List<Map<String, dynamic>> mainServices = [
    {'name': 'Car Service', 'icon': Icons.build_circle},
    {'name': 'Body Work', 'icon': Icons.car_repair},
    {'name': 'Suspension Repairs', 'icon': Icons.engineering},
    {'name': 'Breakdown', 'icon': Icons.warning}, // Replaced with Icons.warning
    {'name': 'Electrical Work', 'icon': Icons.electrical_services},
    {'name': 'AC Repairs', 'icon': Icons.ac_unit},
    {'name': 'Car Wash and Detailing', 'icon': Icons.local_car_wash},
    {'name': 'Computerised Diagnostics', 'icon': Icons.computer},
    {
      'name': 'Pre-Purchase Inspection',
      'icon': Icons.search
    }, // Changed icon for clarity
  ];

  // Other services list
  static const List<String> otherServices = [
    'Oil Change',
    'Running Repair',
    'Engine Repairs',
    'Exterior Modifications',
    'Interior Modifications',
    'Tuning and Performance Enhancement',
    'Pre-Purchase Inspection (SafeCar)',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Services Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mainServices.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final service = mainServices[index];
            final isSelected = selectedService == service['name'];

            return GestureDetector(
              onTap: () => onServiceSelect(service['name']),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      service['icon'],
                      size: 32,
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Other Services Dropdown
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Other Services',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          value:
              otherServices.contains(selectedService) ? selectedService : null,
          hint: const Text('Select other service'),
          onChanged: (value) {
            if (value != null) {
              onServiceSelect(value);
            }
          },
          items: otherServices.map((service) {
            return DropdownMenuItem(
              value: service,
              child: Text(service),
            );
          }).toList(),
        ),
      ],
    );
  }
}
