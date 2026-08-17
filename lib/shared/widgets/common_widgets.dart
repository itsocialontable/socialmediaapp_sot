import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────
// COMMON SCAFFOLD
// ─────────────────────────────────────────
class CommonScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool showBackground;

  const CommonScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: showBackground
          ? Stack(
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.backgroundGradient,
                  ),
                ),
                // Blurred orbs
                Positioned(
                  top: -100,
                  right: -80,
                  child: _GlowOrb(color: AppColors.primary.withOpacity(0.15), size: 300),
                ),
                Positioned(
                  bottom: 100,
                  left: -100,
                  child: _GlowOrb(color: AppColors.secondary.withOpacity(0.1), size: 250),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.4,
                  right: -50,
                  child: _GlowOrb(color: AppColors.primaryLight.withOpacity(0.08), size: 200),
                ),
                // Content
                body,
              ],
            )
          : body,
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ─────────────────────────────────────────
// COMMON APP BAR
// ─────────────────────────────────────────
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final Color? gradientStart;
  final Color? gradientEnd;

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.gradientStart,
    this.gradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
        leading: showBack
        ? IconButton(
        onPressed: () {
      print("🔴 Back button tapped!");

      if (context.canPop()) {
        context.pop();                    // ← GoRouter ka correct method
      } else {
        print("Cannot pop, going to login");
        context.go('/welcome');  // Fallback
      }
    },
    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
    color: AppColors.textPrimary,
    padding: const EdgeInsets.all(12),
    constraints: const BoxConstraints(
    minWidth: 44,
    minHeight: 44,
    ),
    )
        : null,
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            gradientStart ?? AppColors.primary,
            gradientEnd ?? AppColors.primaryLight,
          ],
        ).createShader(bounds),
        child: Text(
          title,
          style: GoogleFonts.sora(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ─────────────────────────────────────────
// COMMON BUTTON
// ─────────────────────────────────────────
class CommonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Gradient? gradient;
  final Color? solidColor;
  final bool outlined;
  final Widget? icon;
  final double height;

  const CommonButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.gradient,
    this.solidColor,
    this.outlined = false,
    this.icon,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: outlined ? null : (gradient ?? AppColors.primaryGradient),
          color: outlined ? Colors.transparent : (solidColor),
          borderRadius: BorderRadius.circular(14),
          border: outlined
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: (gradient?.colors.first ?? AppColors.primary).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 8)],
                    Text(
                      label,
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: outlined ? AppColors.primary : Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// COMMON TEXT FIELD
// ─────────────────────────────────────────
class CommonTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Color? accentColor;

  const CommonTextField({
    super.key,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.accentColor,
  });

  @override
  State<CommonTextField> createState() => _CommonTextFieldState();
}

class _CommonTextFieldState extends State<CommonTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.sora(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isFocused ? accent : AppColors.border,
                width: _isFocused ? 1.5 : 1,
              ),
              color: AppColors.surfaceLight,
              boxShadow: _isFocused
                  ? [BoxShadow(color: accent.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
                  : [],
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.isPassword && _obscureText,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              style: GoogleFonts.sora(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: widget.hint,
                hintStyle: GoogleFonts.sora(color: AppColors.textMuted, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, color: _isFocused ? accent : AppColors.textMuted, size: 18)
                    : null,
                suffixIcon: widget.isPassword
                    ? GestureDetector(
                        onTap: () => setState(() => _obscureText = !_obscureText),
                        child: Icon(
                          _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// COMMON CARD
// ─────────────────────────────────────────
class CommonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final double? borderRadius;

  const CommonCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? (color ?? AppColors.surface) : null,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          border: gradient == null ? Border.all(color: AppColors.border) : null,
          boxShadow: gradient != null
              ? [
                  BoxShadow(
                    color: gradient!.colors.first.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  // final String? change;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    // this.change,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              // if (change != null)
              //   Container(
              //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //     decoration: BoxDecoration(
              //       color: AppColors.success.withOpacity(0.12),
              //       borderRadius: BorderRadius.circular(6),
              //     ),
              //     child: Text(
              //       change!,
              //       style: GoogleFonts.sora(
              //         fontSize: 11,
              //         fontWeight: FontWeight.w600,
              //         color: AppColors.success,
              //       ),
              //     ),
              //   ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// ROLE CHIP
// ─────────────────────────────────────────
class RoleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const RoleChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TASK ITEM
// ─────────────────────────────────────────
class TaskItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String priority;
  final Color priorityColor;
  final String? platform;

  const TaskItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.priorityColor,
    this.platform,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.image_outlined, color: priorityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.sora(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              priority,
              style: GoogleFonts.sora(
                  fontSize: 11, fontWeight: FontWeight.w600, color: priorityColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// BOTTOM NAV BAR
// ─────────────────────────────────────────
class CommonBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavItem> items;
  final Function(int) onTap;
  final Color activeColor;

  const CommonBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isActive = index == currentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: isActive ? activeColor : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? activeColor : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
