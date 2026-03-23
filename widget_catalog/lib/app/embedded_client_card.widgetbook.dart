import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:keyvalue_app/widgets/ai/embedded_client_card.dart';

@widgetbook.UseCase(name: 'Default', type: EmbeddedClientCard)
Widget buildEmbeddedClientCardUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        EmbeddedClientCard(
          data: {
            'name': 'John Doe',
            'email': 'john.doe@example.com',
            'occupation': 'Software Architect',
            'details': 'Interested in cloud native solutions and Kubernetes.',
            'guidelines': 'Contact once a month via email.',
          },
        ),
      ],
    ),
  );
}

@widgetbook.UseCase(name: 'Minimal', type: EmbeddedClientCard)
Widget buildMinimalEmbeddedClientCardUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        EmbeddedClientCard(
          data: {
            'name': 'Jane Smith',
            'email': 'jane.smith@example.com',
            'occupation': 'Venture Capitalist',
          },
        ),
      ],
    ),
  );
}
