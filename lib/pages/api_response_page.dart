import 'package:flutter/material.dart';
import 'dart:convert';

class APIResponseView extends StatelessWidget {
  final String? response;
  final bool isServerRunning;
  final VoidCallback? onRetry;

  const APIResponseView({
    super.key,
    this.response,
    this.isServerRunning = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServerStatus(context),
            const Divider(),
            Expanded(
              child: _buildResponseContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerStatus(BuildContext context) {
    return Row(
      children: [
        Icon(
          isServerRunning ? Icons.cloud_done : Icons.cloud_off,
          color: isServerRunning ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          isServerRunning ? 'Server Running' : 'Server Stopped',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildResponseContent(BuildContext context) {
    if (response == null) {
      return const Center(
        child: Text('No response available'),
      );
    }

    try {
      final jsonData = json.decode(response!);
      final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonData);

      return SingleChildScrollView(
        child: SelectableText(
          prettyJson,
          style: const TextStyle(
            fontFamily: 'monospace',
            height: 1.5,
          ),
        ),
      );
    } catch (e) {
      return SingleChildScrollView(
        child: SelectableText(
          response!,
          style: const TextStyle(
            fontFamily: 'monospace',
            height: 1.5,
          ),
        ),
      );
    }
  }
}
