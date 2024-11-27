// lib/widgets/year_picker.dart
import 'package:flutter/material.dart';

class YearPicker extends StatefulWidget {
  final int initialYear;
  final int firstYear;
  final int lastYear;
  final double height;
  final Function(int) onYearSelected;

  const YearPicker({
    super.key,
    required this.initialYear,
    required this.firstYear,
    required this.lastYear,
    required this.onYearSelected,
    this.height = 48,
  });

  @override
  State<YearPicker> createState() => _YearPickerState();
}

class _YearPickerState extends State<YearPicker> {
  late FixedExtentScrollController _scrollController;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _scrollController = FixedExtentScrollController(
      initialItem: _selectedYear - widget.firstYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListWheelScrollView.useDelegate(
        controller: _scrollController,
        itemExtent: widget.height,
        physics: const FixedExtentScrollPhysics(),
        perspective: 0.005,
        diameterRatio: 1.5,
        onSelectedItemChanged: (index) {
          setState(() {
            _selectedYear = widget.firstYear + index;
            widget.onYearSelected(_selectedYear);
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.lastYear - widget.firstYear + 1,
          builder: (context, index) {
            final year = widget.firstYear + index;
            return Center(
              child: Text(
                year.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: year == _selectedYear
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: year == _selectedYear
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
