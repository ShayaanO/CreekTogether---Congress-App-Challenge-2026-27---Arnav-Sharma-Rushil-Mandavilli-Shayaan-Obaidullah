import 'package:flutter/material.dart';

/// Shows a real banner at the top of the screen (SnackBars appear at the bottom).
/// Must be called with a context that is inside a Scaffold.
void showTopBanner(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearMaterialBanners();
  messenger.showMaterialBanner(
    MaterialBanner(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: const Text('DISMISS'),
        ),
      ],
    ),
  );
}
