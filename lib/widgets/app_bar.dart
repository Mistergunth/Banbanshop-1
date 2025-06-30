import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final double elevation;
  final Color? backgroundColor;
  final Color? titleColor;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.leading,
    this.elevation = 0.5,
    this.backgroundColor,
    this.titleColor,
    this.centerTitle = false,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? theme.textTheme.titleLarge?.color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      leading: leading ?? _buildLeading(context),
      actions: actions,
      elevation: elevation,
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      foregroundColor: titleColor ?? theme.textTheme.titleLarge?.color,
      bottom: bottom,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (!showBackButton) return null;
    
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      onPressed: onBackPressed ?? () => Navigator.maybePop(context),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0)
  );
}
