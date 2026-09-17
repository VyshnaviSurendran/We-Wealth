import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../application/auth_controller.dart';

/// Shown once at startup while the session is being restored (reading the
/// stored token and, if present, validating it against `GET /auth/me`).
///
/// The router's redirect (see `app/router.dart`) moves away from this page
/// automatically once `authControllerProvider` resolves to authenticated or
/// unauthenticated — this page only needs to render the in-between states.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: authState.when(
        data: (_) => const LoadingView(),
        loading: () => const LoadingView(message: 'Loading your session...'),
        error: (error, _) => ErrorView(
          error: error is ApiException ? error : const UnknownApiException(),
          onRetry: () => ref.invalidate(authControllerProvider),
        ),
      ),
    );
  }
}
