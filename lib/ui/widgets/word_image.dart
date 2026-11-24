import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';

import '../../data/services/word_image_files.dart';

class WordImage extends StatefulWidget {
  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? errorBuilder;
  final VoidCallback? onLoadError;

  const WordImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    this.onLoadError,
  });

  @override
  State<WordImage> createState() => _WordImageState();
}

class _WordImageState extends State<WordImage> {
  Future<File?>? _localFile;
  bool _reportedError = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant WordImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _resolveImage();
  }

  void _resolveImage() {
    _reportedError = false;
    _localFile = WordImageFiles.isRemote(widget.source)
        ? null
        : WordImageFiles.findLocal(widget.source);
  }

  Widget _showError(BuildContext context) {
    if (widget.onLoadError != null && !_reportedError) {
      _reportedError = true;
      final source = widget.source;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.source == source) widget.onLoadError?.call();
      });
    }
    return widget.errorBuilder?.call(context) ??
        Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            semanticLabel: AppLocalizations.of(context)!.wordImageUnavailable,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    const loading = Center(child: CircularProgressIndicator());
    final localFile = _localFile;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: localFile == null
          ? CachedNetworkImage(
              imageUrl: widget.source,
              fit: widget.fit,
              placeholder: (_, _) => loading,
              errorWidget: (context, _, _) => _showError(context),
            )
          : FutureBuilder<File?>(
              key: ValueKey(widget.source),
              future: localFile,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return loading;
                }
                final file = snapshot.data;
                if (file == null) return _showError(context);
                return Image.file(
                  file,
                  fit: widget.fit,
                  width: widget.width,
                  height: widget.height,
                  errorBuilder: (context, _, _) => _showError(context),
                );
              },
            ),
    );
  }
}
