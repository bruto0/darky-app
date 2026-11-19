import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/data_providers.dart';
import '../../core/network/api_failure.dart';
import '../../core/ui/theme.dart';

/// White QR sheet: the barcode is shown on a white surface even in dark themes,
/// because scanners need the maximum contrast.
///
/// Screen brightness is deliberately not changed: the app has no brightness
/// plugin in its current dependency set, and the spec marks that part optional.
Future<void> showQrSheet(BuildContext context, {required String clientName}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _QrSheet(clientName: clientName),
  );
}

class _QrSheet extends ConsumerWidget {
  const _QrSheet({required this.clientName});

  final String clientName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.light;
    final text = Theme.of(context).textTheme;
    final barcode = ref.watch(barcodeProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        22,
        10,
        22,
        22 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: palette.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'QR-код',
                  style: text.titleLarge?.copyWith(color: palette.ink),
                ),
              ),
              IconButton(
                tooltip: 'Закрыть',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: palette.muted),
              ),
            ],
          ),
          Text(
            clientName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodyLarge?.copyWith(
              color: palette.ink2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          barcode.when(
            loading: () => _QrFrame(
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.pinkDeep,
                  ),
                ),
              ),
            ),
            error: (error, stackTrace) => _QrFrame(
              child: _QrErrorBody(
                message: error is ApiFailure
                    ? error.message
                    : 'Проверьте соединение и попробуйте снова',
                onRetry: () => ref.invalidate(barcodeProvider),
              ),
            ),
            data: (bytes) {
              if (bytes == null || bytes.isEmpty) {
                return _QrFrame(
                  child: _QrErrorBody(
                    message: 'Клуб пока не прислал код. Попробуйте обновить.',
                    onRetry: () => ref.invalidate(barcodeProvider),
                  ),
                );
              }
              return _QrFrame(
                child: Image.memory(
                  bytes,
                  key: const ValueKey('qr-barcode-image'),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) => _QrErrorBody(
                    message: 'Не удалось показать код. Попробуйте обновить.',
                    onRetry: () => ref.invalidate(barcodeProvider),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: palette.pinkSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Покажите на входе',
                style: text.labelLarge?.copyWith(color: palette.pinkDeep),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => ref.invalidate(barcodeProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Обновить'),
            style: TextButton.styleFrom(foregroundColor: palette.pinkDeep),
          ),
          Text(
            'Код обновляется автоматически. Если он не читается, нажмите «Обновить».',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _QrFrame extends StatelessWidget {
  const _QrFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const palette = AppPalette.light;
    return Container(
      height: 248,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line),
      ),
      child: child,
    );
  }
}

class _QrErrorBody extends StatelessWidget {
  const _QrErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const palette = AppPalette.light;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 42, color: palette.muted),
          const SizedBox(height: 8),
          Text(
            'Не удалось получить код',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: palette.pinkDeep),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
