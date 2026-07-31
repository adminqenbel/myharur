import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

class MHButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;

  const MHButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSecondary ? Colors.transparent : AppTheme.accent;
    final textColor = isSecondary ? theme.colorScheme.onSurface : AppTheme.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: isSecondary ? Border.all(color: AppTheme.divider) : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSecondary ? null : [
          BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : onPressed,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
                : Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class MHCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const MHCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppTheme.surface : Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
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

  const MHGlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8)),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

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
      backgroundImage: url != null ? NetworkImage(url!) : null,
      child: url == null ? Text(fallback ?? 'U', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: radius / 1.5)) : null,
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
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class MHNewsCard extends StatelessWidget {
  final Map<String, dynamic> news;
  final VoidCallback onTap;
  
  const MHNewsCard({super.key, required this.news, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = news['image_url'] != null && (news['image_url'] as String).isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: MHCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  news['image_url'],
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
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
                    style: Theme.of(context).textTheme.titleLarge,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: MHCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(isGovt ? Icons.account_balance_rounded : Icons.warning_rounded, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['category']?.toString().toUpperCase() ?? 'REPORT', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(item['description'] ?? 'No description provided.', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  MHBadge(text: status.toString().toUpperCase(), color: AppTheme.info),
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
            height: 110,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40, color: Colors.grey)),
                  )
                : const Icon(Icons.image, size: 40, color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSold) ...[
                  const MHBadge(text: 'SOLD', color: AppTheme.danger),
                  const SizedBox(height: 4),
                ],
                Text(item['title'] ?? '', style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('₹${item['price']}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(item['condition'] ?? '', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
