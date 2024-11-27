import 'package:flutter/material.dart';

class YearRangeSelector extends StatefulWidget {
  final List<int> selectedYears;
  final ValueChanged<List<int>> onYearsChanged;
  final int startYear;
  final int endYear;

  const YearRangeSelector({
    super.key,
    required this.selectedYears,
    required this.onYearsChanged,
    this.startYear = 1980,
    this.endYear = 2024,
  });

  @override
  State<YearRangeSelector> createState() => _YearRangeSelectorState();
}

class _YearRangeSelectorState extends State<YearRangeSelector> {
  late RangeValues _yearRange;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _initializeYearRange();
  }

  void _initializeYearRange() {
    if (widget.selectedYears.isEmpty) {
      _yearRange = RangeValues(
        widget.startYear.toDouble(),
        widget.startYear.toDouble(),
      );
    } else {
      _yearRange = RangeValues(
        widget.selectedYears.reduce((a, b) => a < b ? a : b).toDouble(),
        widget.selectedYears.reduce((a, b) => a > b ? a : b).toDouble(),
      );
      _selectAll = widget.selectedYears.length ==
          (widget.endYear - widget.startYear + 1);
    }
  }

  void _updateSelectedYears() {
    final List<int> years = [];
    for (int year = _yearRange.start.round();
        year <= _yearRange.end.round();
        year++) {
      years.add(year);
    }
    widget.onYearsChanged(years);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Compatible Years:'),
            const Spacer(),
            Checkbox(
              value: _selectAll,
              onChanged: (value) {
                setState(() {
                  _selectAll = value ?? false;
                  if (_selectAll) {
                    _yearRange = RangeValues(
                      widget.startYear.toDouble(),
                      widget.endYear.toDouble(),
                    );
                    widget.onYearsChanged(List.generate(
                      widget.endYear - widget.startYear + 1,
                      (i) => widget.startYear + i,
                    ));
                  }
                });
              },
            ),
            const Text('Select All Years'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('${_yearRange.start.round()}'),
            Expanded(
              child: RangeSlider(
                values: _yearRange,
                min: widget.startYear.toDouble(),
                max: widget.endYear.toDouble(),
                divisions: widget.endYear - widget.startYear,
                labels: RangeLabels(
                  _yearRange.start.round().toString(),
                  _yearRange.end.round().toString(),
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _yearRange = values;
                    _selectAll = false;
                    _updateSelectedYears();
                  });
                },
              ),
            ),
            Text('${_yearRange.end.round()}'),
          ],
        ),
      ],
    );
  }
}
