import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:flutter/material.dart';
import 'package:keyvalue_app/widgets/confirm_slider.dart';

@widgetbook.UseCase(name: 'Default', type: ConfirmSlider)
Widget buildConfirmSliderUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: ConfirmSlider(
      text: 'Slide to Confirm',
      onConfirm: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirmed!')),
        );
      },
    ),
  );
}

@widgetbook.UseCase(name: 'Compact', type: ConfirmSlider)
Widget buildCompactConfirmSliderUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: ConfirmSlider(
      text: 'Slide to Pay',
      isCompact: true,
      color: Colors.green,
      onConfirm: () {},
    ),
  );
}
