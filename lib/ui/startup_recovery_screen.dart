import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';

class StartupRecoveryScreen extends StatefulWidget {
  const StartupRecoveryScreen({
    super.key,
    required this.hasBackup,
    required this.onRetry,
    required this.onRestore,
  });

  final bool hasBackup;
  final Future<void> Function() onRetry;
  final Future<void> Function() onRestore;

  @override
  State<StartupRecoveryScreen> createState() => _StartupRecoveryScreenState();
}

class _StartupRecoveryScreenState extends State<StartupRecoveryScreen> {
  bool _working = false;
  String? _error;

  Future<void> _run(Future<void> Function() action, String errorMessage) async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      debugPrint('Local database recovery could not continue: $error');
      if (mounted) setState(() => _error = errorMessage);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: CircleAvatar(
                      backgroundColor: colors.errorContainer,
                      foregroundColor: colors.onErrorContainer,
                      radius: 25,
                      child: const Icon(Icons.storage_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.startupDatabaseTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.startupDatabaseBody),
                  const SizedBox(height: 16),
                  Text(
                    widget.hasBackup
                        ? l10n.startupDatabaseRestoreDescription
                        : l10n.startupDatabaseNoBackup,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_error case final error?)
                    Semantics(
                      liveRegion: true,
                      child: Text(error, style: TextStyle(color: colors.error)),
                    ),
                  if (_working)
                    LinearProgressIndicator(
                      semanticsLabel: l10n.startupDatabaseWorking,
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _working
                        ? null
                        : () => _run(
                            widget.onRetry,
                            l10n.startupDatabaseRetryError,
                          ),
                    child: Text(l10n.startupDatabaseRetry),
                  ),
                  if (widget.hasBackup) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _working
                          ? null
                          : () => _run(
                              widget.onRestore,
                              l10n.startupDatabaseRestoreError,
                            ),
                      child: Text(l10n.startupDatabaseRestore),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
