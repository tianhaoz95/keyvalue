import 'package:flutter/material.dart';

class ConfirmSlider extends StatefulWidget {
  final String text;
  final VoidCallback onConfirm;
  final Color? color;
  final bool isCompact;

  const ConfirmSlider({
    super.key,
    required this.text,
    required this.onConfirm,
    this.color,
    this.isCompact = false,
  });

  @override
  State<ConfirmSlider> createState() => _ConfirmSliderState();
}

class _ConfirmSliderState extends State<ConfirmSlider> with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  bool _isConfirmed = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller)
      ..addListener(() {
        setState(() {
          _dragValue = _animation.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (_isConfirmed) return;
    setState(() {
      _dragValue += details.delta.dx / maxWidth;
      _dragValue = _dragValue.clamp(0.0, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isConfirmed) return;
    if (_dragValue > 0.9) {
      setState(() {
        _dragValue = 1.0;
        _isConfirmed = true;
      });
      widget.onConfirm();
    } else {
      _animation = Tween<double>(begin: _dragValue, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? Colors.black;
    final height = widget.isCompact ? 44.0 : 52.0;
    final thumbSize = height - 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final thumbOffset = _dragValue * (maxWidth - thumbSize - 8);

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: themeColor.withValues(alpha: 0.1)),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.text.toUpperCase(),
                  style: TextStyle(
                    color: themeColor.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w900,
                    fontSize: widget.isCompact ? 10 : 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Positioned(
                left: 4 + thumbOffset,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _handleDragUpdate(details, maxWidth),
                  onHorizontalDragEnd: _handleDragEnd,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isConfirmed ? Icons.check : Icons.chevron_right,
                      color: Colors.white,
                      size: widget.isCompact ? 20 : 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
