import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Prompt bar for natural language search
class PromptBar extends StatefulWidget {
  final Function(String) onSubmit;
  final VoidCallback? onClear;
  final String? currentPrompt;

  const PromptBar({
    super.key,
    required this.onSubmit,
    this.onClear,
    this.currentPrompt,
  });

  @override
  State<PromptBar> createState() => _PromptBarState();
}

class _PromptBarState extends State<PromptBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  // Layout constants
  static const double _outerRadius = 16.0;
  static const double _buttonMargin = 6.0;
  static const double _buttonRadius = _outerRadius - _buttonMargin;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPrompt);
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.only(left: 16, right: _buttonMargin, top: _buttonMargin, bottom: _buttonMargin),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(_outerRadius),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: AppTheme.primaryLight,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Try: "food expenses last week"',
                hintStyle: TextStyle(
                  color: AppTheme.textMuted.withOpacity(0.7),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),
          if (_hasText)
            GestureDetector(
              onTap: _handleClear,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.close,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            child: InkWell(
              onTap: _handleSubmit,
              borderRadius: BorderRadius.circular(_buttonRadius),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
