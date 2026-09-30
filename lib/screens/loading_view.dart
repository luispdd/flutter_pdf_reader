import 'package:flutter/material.dart';
import 'package:flutter_pdf_reader/core/app_theme.dart';

class LoadingView extends StatefulWidget {
  final String? documentFileName;
  final VoidCallback? onCancel;

  const LoadingView({
    super.key,
    this.documentFileName,
    this.onCancel,
  });

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.documentFileName != null &&
            widget.documentFileName!.isNotEmpty
        ? 'Loading ${widget.documentFileName}...'
        : 'Loading document...';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kAmber, kAmberDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: kAmber.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: RotationTransition(
              key: const Key('loading_icon_rotation'),
              turns: _controller,
              child: const Icon(
                Icons.sync_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: kTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Preparing pages, please wait...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.40),
            height: 1.5,
          ),
        ),
        if (widget.onCancel != null) ...[
          const SizedBox(height: 28),
          Center(
            child: OutlinedButton.icon(
              key: const Key('loading_cancel_button'),
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close, size: 18),
              label: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.8),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
        const Spacer(flex: 3),
      ],
    );
  }
}
