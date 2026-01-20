import 'package:flutter/material.dart';

/// macOS-style floating dock navigation bar with animated icons.
/// Provides a modern, floating bottom navigation with smooth 144hz-style animations.
class DockNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<DockNavItem> items;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double height;
  final double iconSize;
  final EdgeInsetsGeometry? margin;

  const DockNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.height = 70,
    this.iconSize = 26,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark
            ? const Color(0xFF1A1A2E)
            : Colors.white);
    final selected = selectedColor ?? Theme.of(context).primaryColor;
    final unselected = unselectedColor ??
        (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    // Get bottom safe area padding
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // TRUE FLOATING ISLAND: transparent background, floating in air
    return Container(
      margin: margin ?? EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 20),
      height: height,
      decoration: BoxDecoration(
        // Transparent background - floating in air
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        // No border for cleaner floating look
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final isSelected = index == currentIndex;
          return _DockNavItem(
            item: items[index],
            isSelected: isSelected,
            selectedColor: selected,
            unselectedColor: unselected,
            iconSize: iconSize,
            onTap: () => onTap(index),
          );
        }),
      ),
    );
  }
}

class DockNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String? label;
  final String? tooltip;

  const DockNavItem({
    required this.icon,
    this.activeIcon,
    this.label,
    this.tooltip,
  });
}

class _DockNavItem extends StatefulWidget {
  final DockNavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final double iconSize;
  final VoidCallback onTap;

  const _DockNavItem({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.iconSize,
    required this.onTap,
  });

  @override
  State<_DockNavItem> createState() => _DockNavItemState();
}

class _DockNavItemState extends State<_DockNavItem>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Scale animation - smooth 144hz feel
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _scaleController, 
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    
    // Bounce animation for selection
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -8.0, end: 2.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 2.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
    ]).animate(_bounceController);
    
    // Subtle rotation for extra smoothness
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.05),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.05, end: 0.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isSelected) {
      _scaleController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _DockNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _scaleController.forward();
        _bounceController.forward(from: 0.0);
      } else {
        _scaleController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.isSelected
        ? (widget.item.activeIcon ?? widget.item.icon)
        : widget.item.icon;

    return Tooltip(
      message: widget.item.tooltip ?? widget.item.label ?? '',
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          // Trigger bounce even if already selected for feedback
          if (widget.isSelected) {
            _bounceController.forward(from: 0.0);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _bounceAnimation, _rotationAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated icon with glow effect when selected
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.all(widget.isSelected ? 8 : 0),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Icon(
                              icon,
                              key: ValueKey(widget.isSelected),
                              size: widget.iconSize,
                              color: widget.isSelected 
                                  ? widget.selectedColor 
                                  : widget.unselectedColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Animated dot indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: widget.isSelected ? 5 : 0,
                          height: widget.isSelected ? 5 : 0,
                          decoration: BoxDecoration(
                            color: widget.selectedColor,
                            shape: BoxShape.circle,
                            boxShadow: widget.isSelected ? [
                              BoxShadow(
                                color: widget.selectedColor.withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ] : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
