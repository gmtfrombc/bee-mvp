import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/responsive_service.dart';

/// A reusable text field that follows Bee Design guidelines.
///
/// Features:
/// • Built-in label text
/// • Optional password toggle (obscure text)
/// • Optional suffix icon slot
/// • Accepts custom validator adhering to Flutter form conventions
/// • Applies ResponsiveService paddings & font sizes
class BeeTextField extends StatefulWidget {
  const BeeTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.hint,
  });

  /// Label displayed above the field.
  final String label;

  /// Controller for imperative access.
  final TextEditingController? controller;

  /// Initial value when no controller is supplied.
  final String? initialValue;

  /// Keyboard type – defaults to text.
  final TextInputType? keyboardType;

  /// Text input action (done, next, etc.).
  final TextInputAction? textInputAction;

  /// Form-style validator returning null if valid.
  final String? Function(String?)? validator;

  /// Change callback.
  final ValueChanged<String>? onChanged;

  /// When true, text is obscured and a show/hide toggle is shown.
  final bool obscureText;

  /// Whether to enable auto-suggestions (disabled for passwords by default when obscureText true).
  final bool enableSuggestions;

  /// Whether to enable spell-checking / autocorrect.
  final bool autocorrect;

  /// Optional custom suffix icon. Ignored if [obscureText] is true since the visibility toggle will be used.
  final Widget? suffixIcon;

  /// Max lines – defaults to 1 (single-line).
  final int maxLines;

  /// Optional max length.
  final int? maxLength;

  /// Optional additional formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field is read-only. Useful for picker-trigger fields.
  final bool readOnly;

  /// Optional tap callback when [readOnly] is true (or any custom need).
  final VoidCallback? onTap;

  /// Optional hint/placeholder text shown inside the field when empty.
  final String? hint;

  @override
  State<BeeTextField> createState() => _BeeTextFieldState();
}

class _BeeTextFieldState extends State<BeeTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyLarge;
    final inputPadding = EdgeInsets.symmetric(
      horizontal: ResponsiveService.getSmallSpacing(context),
      vertical: ResponsiveService.getTinySpacing(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: labelStyle),
        SizedBox(height: ResponsiveService.getTinySpacing(context)),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          obscureText: _obscure,
          enableSuggestions: widget.enableSuggestions && !widget.obscureText,
          autocorrect: widget.autocorrect && !widget.obscureText,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            contentPadding: inputPadding,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: widget.hint,
            suffixIcon:
                widget.obscureText
                    ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                    : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}
