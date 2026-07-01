import 'package:flutter/material.dart';

import '../screens/operation/operation_mode_screen.dart';

class OperationModeButton extends StatelessWidget {
  const OperationModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const OperationModeScreen(),
          ),
        );
      },
      icon: const Icon(Icons.storefront_rounded),
      label: const Text('Balcão', maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
