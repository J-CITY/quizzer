import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizzer/l10n/app_localizations.dart';

import '../../data/models/rush_session.dart';

Future<({int errorLimit, int? override})?> showRushSettingsSheet(
  BuildContext context, {
  required int? initialErrorLimit,
  int? globalErrorLimit,
}) {
  return showModalBottomSheet<({int errorLimit, int? override})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _RushSettingsSheet(
      initialErrorLimit: initialErrorLimit,
      globalErrorLimit: globalErrorLimit,
    ),
  );
}

class _RushSettingsSheet extends StatefulWidget {
  final int? initialErrorLimit;
  final int? globalErrorLimit;

  const _RushSettingsSheet({
    required this.initialErrorLimit,
    required this.globalErrorLimit,
  });

  @override
  State<_RushSettingsSheet> createState() => _RushSettingsSheetState();
}

class _RushSettingsSheetState extends State<_RushSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController;
  late bool _useGlobal;
  late bool _unlimited;

  @override
  void initState() {
    super.initState();
    final limit =
        widget.initialErrorLimit ??
        widget.globalErrorLimit ??
        RushSession.defaultErrorLimit;
    _useGlobal =
        widget.globalErrorLimit != null && widget.initialErrorLimit == null;
    _unlimited = limit == 0;
    _limitController = TextEditingController(
      text: (_unlimited ? RushSession.defaultErrorLimit : limit).toString(),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    if (_useGlobal) {
      Navigator.pop(context, (
        errorLimit: widget.globalErrorLimit!,
        override: null,
      ));
      return;
    }
    final limit = _unlimited ? 0 : int.parse(_limitController.text);
    Navigator.pop(context, (errorLimit: limit, override: limit));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final globalLimit = widget.globalErrorLimit;
    final isList = globalLimit != null;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isList ? l10n.rushMode : l10n.settingsRushErrorLimit,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (globalLimit != null) ...[
                const SizedBox(height: 8),
                Text(l10n.rushLaunchRules),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.rushUseGlobalLimit),
                  subtitle: Text(l10n.rushErrorLimitSummary(globalLimit)),
                  value: _useGlobal,
                  onChanged: (value) => setState(() => _useGlobal = value),
                ),
              ],
              if (!_useGlobal) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.rushUnlimited),
                  value: _unlimited,
                  onChanged: (value) => setState(() => _unlimited = value),
                ),
                if (!_unlimited)
                  TextFormField(
                    controller: _limitController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        RushSession.maxErrorLimit.toString().length,
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.rushErrorLimitLabel,
                    ),
                    validator: (text) {
                      final limit = int.tryParse(text ?? '');
                      if (limit == null ||
                          limit < 1 ||
                          limit > RushSession.maxErrorLimit) {
                        return l10n.rushInvalidErrorLimit(
                          RushSession.maxErrorLimit,
                        );
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _confirm(),
                  ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _confirm,
                child: Text(isList ? l10n.start : l10n.rushSaveSettings),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
