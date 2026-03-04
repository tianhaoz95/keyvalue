import 'package:flutter/material.dart';
import '../../models/customer.dart';

class EmbeddedClientCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const EmbeddedClientCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_search_outlined, size: 20, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                'CLIENT PREVIEW',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('NAME', data['name'] ?? '-'),
          _buildInfoRow('EMAIL', data['email'] ?? '-'),
          _buildInfoRow('OCCUPATION', data['occupation'] ?? '-'),
          if (data['details'] != null && data['details'].toString().isNotEmpty)
            _buildInfoRow('BACKGROUND', 'Available', isMarkdown: true, content: data['details']),
          if (data['guidelines'] != null && data['guidelines'].toString().isNotEmpty)
            _buildInfoRow('GUIDELINES', 'Available', isMarkdown: true, content: data['guidelines']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMarkdown = false, String? content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          if (isMarkdown && content != null)
             const Icon(Icons.check_circle, size: 14, color: Colors.green)
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
