// lib/widgets/expandable_year_selector.dart
import 'package:flutter/material.dart';

class ExpandableYearSelector extends StatefulWidget {
  final List<int> selectedYears;
  final Function(List<int>) onYearsChanged;
  final int startYear;
  final int endYear;
  final bool excludeCurrentYear;

  const ExpandableYearSelector({
    super.key,
    required this.selectedYears,
    required this.onYearsChanged,
    this.startYear = 1980,
    this.endYear = 2024,
    this.excludeCurrentYear = false,
  });

  @override
  State<ExpandableYearSelector> createState() => _ExpandableYearSelectorState();
}

class _ExpandableYearSelectorState extends State<ExpandableYearSelector> {
  late final Map<String, List<int>> _yearGroups;
  final Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _initializeYearGroups();
  }

  void _initializeYearGroups() {
    _yearGroups = {};

    // Calculate the actual end year (either specified or current)
    final currentYear = DateTime.now().year;
    final actualEndYear = widget.endYear > currentYear
        ? widget.excludeCurrentYear
            ? currentYear - 1
            : currentYear
        : widget.endYear;

    for (int decade = (widget.startYear ~/ 10) * 10;
        decade <= (actualEndYear ~/ 10) * 10;
        decade += 10) {
      final List<int> years = [];
      final int decadeEnd = decade + 9;

      for (int year = decade;
          year <= decadeEnd && year <= actualEndYear;
          year++) {
        if (year >= widget.startYear) {
          years.add(year);
        }
      }

      if (years.isNotEmpty) {
        _yearGroups['${decade}s'] = years;
        _expandedGroups['${decade}s'] = false;
      }
    }
  }

  void _toggleYear(int year) {
    final List<int> updatedYears = List.from(widget.selectedYears);
    if (updatedYears.contains(year)) {
      updatedYears.remove(year);
    } else {
      updatedYears.add(year);
    }
    updatedYears.sort();
    widget.onYearsChanged(updatedYears);
  }

  void _toggleDecade(String decade, bool? selectAll) {
    final List<int> updatedYears = List.from(widget.selectedYears);
    final years = _yearGroups[decade] ?? [];

    if (selectAll ?? false) {
      updatedYears.addAll(years.where((year) => !updatedYears.contains(year)));
    } else {
      updatedYears.removeWhere((year) => years.contains(year));
    }

    updatedYears.sort();
    widget.onYearsChanged(updatedYears);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Compatible Years',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _yearGroups.length,
            itemBuilder: (context, index) {
              final decade = _yearGroups.keys.elementAt(index);
              final years = _yearGroups[decade]!;
              final selectedInDecade = years
                  .where((year) => widget.selectedYears.contains(year))
                  .length;
              final isAllSelected = selectedInDecade == years.length;
              final isPartiallySelected =
                  selectedInDecade > 0 && selectedInDecade < years.length;

              return Column(
                children: [
                  ListTile(
                    title: Text(
                      decade,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    leading: Checkbox(
                      tristate: true,
                      value: isAllSelected
                          ? true
                          : isPartiallySelected
                              ? null
                              : false,
                      onChanged: (value) => _toggleDecade(decade, value),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        _expandedGroups[decade]!
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() {
                          _expandedGroups[decade] = !_expandedGroups[decade]!;
                        });
                      },
                    ),
                  ),
                  if (_expandedGroups[decade]!)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: years.map((year) {
                          return FilterChip(
                            selected: widget.selectedYears.contains(year),
                            label: Text(year.toString()),
                            onSelected: (selected) => _toggleYear(year),
                            selectedColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            checkmarkColor:
                                Theme.of(context).colorScheme.primary,
                            labelStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: widget.selectedYears.contains(year)
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (index < _yearGroups.length - 1) const Divider(),
                ],
              );
            },
          ),
        ),
        if (widget.selectedYears.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Selected Years: ${_formatSelectedYears()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  String _formatSelectedYears() {
    if (widget.selectedYears.isEmpty) return 'None';
    final years = List<int>.from(widget.selectedYears)..sort();
    List<String> ranges = [];
    if (years.isEmpty) return "";

    int start = years.first;
    int prev = start;

    for (int i = 1; i < years.length; i++) {
      if (years[i] != prev + 1) {
        ranges.add(start == prev ? '$start' : '$start-$prev');
        start = years[i];
      }
      prev = years[i];
    }
    ranges.add(start == prev ? '$start' : '$start-$prev');

    return ranges.join(', ');
  }
}
