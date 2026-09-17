import 'package:flutter/material.dart';

import '../errors/api_exception.dart';

/// Standard error state for a page or section.
///
/// Pass the caught [ApiException] so the message is already user-safe
/// (never a raw stack trace or backend internals) and optionally [onRetry]
/// to show a retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final ApiException error;
  final VoidCallback? onRetry;

  IconData get _icon => switch (error) {
        NetworkException() => Icons.wifi_off_rounded,
        AuthException() => Icons.lock_outline_rounded,
        ForbiddenException() => Icons.block_rounded,
        NotFoundException() => Icons.search_off_rounded,
        ValidationException() => Icons.error_outline_rounded,
        ServerException() => Icons.dns_rounded,
        UnknownApiException() => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
