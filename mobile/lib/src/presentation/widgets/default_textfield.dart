import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';

class DefaultTextfield extends StatefulWidget {
  const DefaultTextfield({
    super.key,
    this.label,
    this.placeholder = '',
    this.controller,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.validator,
    this.onSubmitted,
  });

  final String? label;
  final String placeholder;
  final TextEditingController? controller;
  final bool obscureText;
  final bool showPasswordToggle;
  final TextInputType keyboardType;
  final bool required;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  State<DefaultTextfield> createState() => _DefaultTextfieldState();
}

class _DefaultTextfieldState extends State<DefaultTextfield> {
  late TextEditingController _controller;
  bool _obscure = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _obscure = widget.obscureText;
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final err = widget.validator?.call(value);
    setState(() => _error = err);
    if (err == null) widget.onSubmitted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.required ? '${widget.label!} *' : widget.label!,
              style: theme.textTheme.labelMedium,
            ),
          ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusMd),
            border: Border.all(
              color: _error != null ? kErrorBase : kGray200,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            keyboardType: widget.keyboardType,
            obscureText: _obscure,
            onSubmitted: _submit,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              suffixIcon: widget.showPasswordToggle
                  ? IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_error!, style: const TextStyle(color: kErrorBase, fontSize: 12)),
          ),
      ],
    );
  }
}
