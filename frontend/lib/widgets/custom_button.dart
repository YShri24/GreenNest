import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPrimary;
  final IconData? icon;
  final bool isEnabled;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.isPrimary = true,
    this.icon,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late double _scale;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1 - _controller.value;
    final primaryColor = widget.isEnabled ? const Color(0xFF0F5132) : Colors.grey; // Premium deep emerald or grey
    final secondaryColor = widget.isEnabled ? const Color(0xFFE8F5E9) : Colors.grey[200]!; // Mint tint or light grey
    final textColor = widget.isEnabled 
        ? (widget.isPrimary ? Colors.white : const Color(0xFF0F5132))
        : Colors.grey[500]!;

    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => _controller.forward() : null,
      onTapUp: widget.isEnabled ? (_) {
        _controller.reverse();
        widget.onTap();
      } : null,
      onTapCancel: widget.isEnabled ? () => _controller.reverse() : null,
      child: Transform.scale(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isPrimary && widget.isEnabled
                ? LinearGradient(
                    colors: [primaryColor, const Color(0xFF198754)], // Elegant green gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isPrimary 
                ? (widget.isEnabled ? null : Colors.grey[300])
                : secondaryColor,
            boxShadow: widget.isPrimary && widget.isEnabled
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
            border: widget.isPrimary ? null : Border.all(color: textColor.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: textColor, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
