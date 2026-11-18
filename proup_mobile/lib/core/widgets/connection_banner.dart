import 'package:flutter/material.dart';

import '../errors/app_exception.dart';
import '../theme/app_colors.dart';

/// Aviso fijo de error de conexión con botón "Reintentar" (hallazgo H04 de QA).
///
/// A diferencia de un SnackBar, no desaparece solo: se queda visible hasta que la
/// acción se reintenta con éxito o el usuario lo cierra.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    super.key,
    required this.message,
    required this.onRetry,
    this.onClose,
    this.offline = true,
    this.retrying = false,
  });

  /// Texto del error (el mismo que esperan los casos de prueba).
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onClose;

  /// true = el error fue de conexión (muestra el título "Sin conexión").
  final bool offline;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: AppColors.errorContainer,
        child: SafeArea(
          bottom: false,
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      offline ? Icons.wifi_off_rounded : Icons.error_outline,
                      color: AppColors.onErrorContainer,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (offline)
                            const Text(
                              'Sin conexión',
                              style: TextStyle(
                                color: AppColors.onErrorContainer,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          Text(message, style: const TextStyle(color: AppColors.onErrorContainer, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onClose != null)
                      TextButton(
                        onPressed: retrying ? null : onClose,
                        style: TextButton.styleFrom(foregroundColor: AppColors.onErrorContainer),
                        child: const Text('Cerrar'),
                      ),
                    TextButton.icon(
                      onPressed: retrying ? null : onRetry,
                      style: TextButton.styleFrom(foregroundColor: AppColors.onErrorContainer),
                      icon:
                          retrying
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh, size: 18),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado del aviso de error de una pantalla.
class ConnectionIssue {
  const ConnectionIssue(this.message, {required this.retry, this.offline = true});

  /// Crea el aviso a partir del error capturado: el título "Sin conexión" solo
  /// aparece si de verdad falló la red (no si el servidor respondió con error).
  factory ConnectionIssue.from(Object error, String message, {required VoidCallback retry}) =>
      ConnectionIssue(message, retry: retry, offline: isConnectivityError(error));

  final String message;
  final VoidCallback retry;
  final bool offline;
}

/// ¿El error se debe a falta de conexión (sin respuesta del servidor)?
bool isConnectivityError(Object error) => error is NetworkException;

/// Coloca el [ConnectionBanner] encima de [child] mientras haya un [issue].
class WithConnectionBanner extends StatelessWidget {
  const WithConnectionBanner({
    super.key,
    required this.issue,
    required this.onClose,
    required this.child,
    this.retrying = false,
  });

  final ConnectionIssue? issue;
  final VoidCallback onClose;
  final bool retrying;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final i = issue;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child:
              i == null
                  ? const SizedBox(width: double.infinity)
                  : ConnectionBanner(
                    message: i.message,
                    offline: i.offline,
                    retrying: retrying,
                    onRetry: i.retry,
                    onClose: onClose,
                  ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
