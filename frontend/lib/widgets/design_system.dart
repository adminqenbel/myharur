import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../theme.dart';

// ── BUTTONS ─────────────────────────────────────────────────────────────────

class MHButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  const MHButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSecondary ? Colors.transparent : AppTheme.accent;
    final textColor = isSecondary ? theme.colorScheme.onSurface : AppTheme.primary;
    final isDisabled = onPressed == null || isLoading;
    
    return Container(
      decoration: BoxDecoration(
        color: isDisabled && !isSecondary ? color.withOpacity(0.5) : color,
        border: isSecondary ? Border.all(color: AppTheme.divider) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSecondary || isDisabled ? null : [
          BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isDisabled ? null : onPressed,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[Icon(icon, color: textColor, size: 20), const SizedBox(width: 8)],
                      Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class MHOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const MHOutlinedButton({super.key, required this.text, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return MHButton(
      text: text,
      onPressed: onPressed,
      isSecondary: true,
      icon: icon,
    );
  }
}

// ── INPUTS ──────────────────────────────────────────────────────────────────

class MHTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;

  const MHTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.accent, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

// ── CONTAINERS & CARDS ──────────────────────────────────────────────────────

class MHCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const MHCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppTheme.surface : Colors.white;
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 16, offset: const Offset(0, 4))
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class MHGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const MHGlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MHBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const MHBottomSheet({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        left: padding.horizontal / 2, 
        right: padding.horizontal / 2, 
        top: padding.vertical / 2, 
        bottom: padding.vertical / 2 + MediaQuery.of(context).viewInsets.bottom
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: child,
    );
  }
}

// ── MEDIA & IDENTITY ────────────────────────────────────────────────────────

class MHAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  final String? fallback;

  const MHAvatar({super.key, this.url, this.radius = 24, this.fallback});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.accent.withOpacity(0.2),
      backgroundImage: url != null && url!.isNotEmpty ? CachedNetworkImageProvider(url!) : null,
      child: (url == null || url!.isEmpty) ? Text(fallback ?? 'U', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: radius / 1.5)) : null,
    );
  }
}

class MHBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const MHBadge({super.key, required this.text, this.color = AppTheme.accent, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class MHTagChip extends StatelessWidget {
  final String label;
  final Color color;
  
  const MHTagChip({super.key, required this.label, this.color = AppTheme.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

// ── LOADERS & STATES ────────────────────────────────────────────────────────

class MHSkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const MHSkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class MHEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;

  const MHEmptyState({super.key, required this.icon, required this.title, this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppTheme.accent.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}

class MHErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const MHErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.danger),
            const SizedBox(height: 24),
            Text('Oops!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(width: 200, child: MHOutlinedButton(text: 'Retry', onPressed: onRetry, icon: Icons.refresh_rounded)),
          ],
        ),
      ),
    );
  }
}

// ── DOMAIN CARDS ────────────────────────────────────────────────────────────

class MHNewsCard extends StatelessWidget {
  final Map<String, dynamic> news;
  final VoidCallback onTap;
  
  const MHNewsCard({super.key, required this.news, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = news['image_url'] != null && (news['image_url'] as String).isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MHCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: news['image_url'],
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const MHSkeletonLoader(width: double.infinity, height: 180, borderRadius: 0),
                  errorWidget: (context, url, error) => const SizedBox(height: 180, child: Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey))),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MHBadge(text: news['source'] ?? 'Local News', color: AppTheme.info),
                      const Spacer(),
                      Text(
                        news['created_at'] != null ? news['created_at'].toString().substring(0, 10) : '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    news['title'] ?? 'News Update',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news['content'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MHEmergencyCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isGovt;

  const MHEmergencyCard({super.key, required this.item, this.isGovt = false});

  @override
  Widget build(BuildContext context) {
    final status = item['status'] ?? 'pending';
    final color = isGovt ? AppTheme.accentDark : AppTheme.danger;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MHCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(isGovt ? Icons.account_balance_rounded : Icons.warning_rounded, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['category']?.toString().toUpperCase() ?? 'REPORT', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(item['description'] ?? 'No description provided.', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  MHBadge(text: status.toString().toUpperCase(), color: status == 'resolved' ? AppTheme.success : AppTheme.info),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MHMarketplaceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const MHMarketplaceCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSold = item['is_sold'] == true;
    final String? imageUrl = item['image_url'] as String?;

    return MHCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl, 
                      fit: BoxFit.cover, 
                      placeholder: (context, url) => const MHSkeletonLoader(width: double.infinity, height: 140, borderRadius: 0),
                      errorWidget: (context, url, error) => const Icon(Icons.image, size: 40, color: Colors.grey)
                    ),
                  )
                : const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSold) ...[
                  const MHBadge(text: 'SOLD OUT', color: AppTheme.danger),
                  const SizedBox(height: 8),
                ],
                Text(item['title'] ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text('₹${item['price']}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(item['condition'] ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
