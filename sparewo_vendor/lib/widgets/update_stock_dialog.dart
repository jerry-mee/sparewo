// lib/widgets/update_stock_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class UpdateStockDialog extends StatefulWidget {
  final int currentQuantity;

  const UpdateStockDialog({
    super.key,
    required this.currentQuantity,
  });

  @override
  State<UpdateStockDialog> createState() => _UpdateStockDialogState();
}

class _UpdateStockDialogState extends State<UpdateStockDialog> {
  late final TextEditingController _controller;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.currentQuantity.toString());
    debugPrint(
        'UpdateStockDialog initialized with quantity: ${widget.currentQuantity}');
  }

  @override
  void dispose() {
    _controller.dispose();
    debugPrint('UpdateStockDialog disposed');
    super.dispose();
  }

  void _validateInput(String value) {
    final number = int.tryParse(value);
    setState(() {
      _isValid = number != null && number >= 0;
    });
    debugPrint(
        'Stock input validation: "$value" is ${_isValid ? "valid" : "invalid"}');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _validateInput,
            decoration: InputDecoration(
              labelText: 'New Quantity',
              errorText: !_isValid ? 'Please enter a valid number' : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current stock: ${widget.currentQuantity}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            debugPrint('UpdateStockDialog cancelled');
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid
              ? () {
                  final newQuantity = int.parse(_controller.text);
                  debugPrint('Stock updated to: $newQuantity');
                  Navigator.of(context).pop(newQuantity);
                }
              : null,
          child: const Text('Update'),
        ),
      ],
    );
  }
}
