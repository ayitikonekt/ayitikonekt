import 'package:flutter/material.dart';

class AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onPressed;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;

  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.iconSize = 22,
    this.padding = const EdgeInsets.all(8),
    this.backgroundColor = Colors.white,
    this.selectedColor = const Color(0xFFE31B23),
    this.unselectedColor = const Color(0xFF616161),
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton> {
  late bool _selected;
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.isFavorite;
  }

  @override
  void didUpdateWidget(AnimatedFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_waiting && widget.isFavorite != _selected) {
      _selected = widget.isFavorite;
    }
  }

  Future<void> _toggle() async {
    if (_waiting || widget.onPressed == null) return;

    setState(() {
      _selected = !_selected;
      _waiting = true;
    });

    // Permite ver la animación incluso cuando al quitar un favorito
    // el producto desaparece inmediatamente de la lista.
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    widget.onPressed!();
    _waiting = false;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.backgroundColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onPressed == null ? null : _toggle,
        child: Padding(
          padding: widget.padding,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
            child: Icon(
              _selected ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(_selected),
              color: _selected ? widget.selectedColor : widget.unselectedColor,
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
