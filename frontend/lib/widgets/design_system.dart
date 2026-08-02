import 'dart:ui';
import 'dart:convert';
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

  MHButton({
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
    final color = isSecondary ? Colors.transparent : theme.colorScheme.secondary;
    final textColor = isSecondary ? theme.colorScheme.onSurface : theme.colorScheme.onSecondary;
    final borderColor = theme.dividerTheme.color ?? theme.dividerColor;
    final isDisabled = onPressed == null || isLoading;
    
    return Container(
      decoration: BoxDecoration(
        color: isDisabled && !isSecondary ? color.withOpacity(0.5) : color,
        border: isSecondary ? Border.all(color: borderColor) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSecondary || isDisabled ? null : [
          BoxShadow(color: theme.colorScheme.secondary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isDisabled ? null : onPressed,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[Icon(icon, color: textColor, size: 20), SizedBox(width: 8)],
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
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.38) : Colors.black38),
            filled: true,
            fillColor: isDark ? Theme.of(context).colorScheme.surface.withOpacity(0.05) : Colors.black.withOpacity(0.02),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.accent, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  MHCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Theme.of(context).colorScheme.surface;
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Theme.of(context).dividerColor.withOpacity(0.1) : Theme.of(context).dividerColor.withOpacity(0.1)),
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
            color: isDark ? Theme.of(context).colorScheme.surface.withOpacity(0.05) : Theme.of(context).colorScheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Theme.of(context).colorScheme.surface.withOpacity(0.1) : Theme.of(context).colorScheme.surface.withOpacity(0.8)),
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
    return Container(
      padding: EdgeInsets.only(
        left: padding.horizontal / 2, 
        right: padding.horizontal / 2, 
        top: padding.vertical / 2, 
        bottom: padding.vertical / 2 + MediaQuery.of(context).viewInsets.bottom
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), SizedBox(width: 4)],
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      baseColor: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      highlightColor: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppTheme.accent.withOpacity(0.5)),
            ),
            SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (description != null) ...[
              SizedBox(height: 8),
              Text(description!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
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
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.danger),
            SizedBox(height: 24),
            Text('Oops!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            SizedBox(height: 24),
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
      padding: EdgeInsets.only(bottom: 16),
      child: MHCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: MHImage(
                  url: news['image_url'],
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MHBadge(text: news['source'] ?? 'Local News', color: AppTheme.info),
                      Spacer(),
                      Text(
                        news['created_at'] != null ? news['created_at'].toString().substring(0, 10) : '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    news['title'] ?? 'News Update',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
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
  final Function(String)? onStatusUpdate;

  const MHEmergencyCard({super.key, required this.item, this.isGovt = false, this.onStatusUpdate});

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString().replaceAll('_', ' ') ?? 'pending';
    final userName = item['user_name'] ?? 'Citizen';
    final lat = item['lat'] != null ? double.parse(item['lat'].toString()).toStringAsFixed(4) : '';
    final lng = item['lng'] != null ? double.parse(item['lng'].toString()).toStringAsFixed(4) : '';
    final locationText = (lat.isNotEmpty && lng.isNotEmpty) ? '$lat, $lng' : 'Location unknown';
    final color = isGovt ? AppTheme.accent : AppTheme.danger;
    
    // Status color logic
    Color badgeColor = AppTheme.info;
    if (status.toLowerCase().contains('resolved') || status.toLowerCase().contains('completed')) badgeColor = AppTheme.success;
    if (status.toLowerCase().contains('action') || status.toLowerCase().contains('progress')) badgeColor = Colors.orange;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: MHCard(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(isGovt ? Icons.account_balance_rounded : Icons.warning_rounded, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGovt ? 'GOVT GRIEVANCE' : 'EMERGENCY SOS', 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)
                      ),
                      Text(item['category']?.toString().toUpperCase() ?? 'REPORT', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                MHBadge(text: status.toUpperCase(), color: badgeColor),
              ],
            ),
            SizedBox(height: 12),
            Text(item['description'] ?? 'No description provided.', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 16),
            Divider(color: Theme.of(context).dividerColor.withOpacity(0.5)),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                SizedBox(width: 4),
                Text(userName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
                Spacer(),
                Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                SizedBox(width: 4),
                Text(locationText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
              ],
            ),
            if (onStatusUpdate != null) ...[
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Update Tracking Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 16),
                            ListTile(title: Text('Responded'), leading: Icon(Icons.check_circle_outline, color: AppTheme.info), onTap: () { Navigator.pop(ctx); onStatusUpdate!('Responded'); }),
                            ListTile(title: Text('Searching for Help'), leading: Icon(Icons.search_rounded, color: Colors.orange), onTap: () { Navigator.pop(ctx); onStatusUpdate!('Searching for Help'); }),
                            ListTile(title: Text('In Action'), leading: Icon(Icons.directions_run_rounded, color: AppTheme.danger), onTap: () { Navigator.pop(ctx); onStatusUpdate!('In Action'); }),
                            ListTile(title: Text('Completed'), leading: Icon(Icons.done_all_rounded, color: AppTheme.success), onTap: () { Navigator.pop(ctx); onStatusUpdate!('Completed'); }),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.update_rounded, size: 18),
                  label: Text('Take Action / Update Status'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]
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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: MHImage(
                      url: imageUrl, 
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.image_outlined, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSold) ...[
                  const MHBadge(text: 'SOLD OUT', color: AppTheme.danger),
                  SizedBox(height: 8),
                ],
                Text(item['title'] ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 8),
                Text('₹${item['price']}', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 16)),
                SizedBox(height: 4),
                Text(item['condition'] ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MHImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;

  const MHImage({super.key, required this.url, required this.width, required this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('data:image')) {
      final base64String = url.split(',').last;
      return Image.memory(
        base64Decode(base64String),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildError(context),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => MHSkeletonLoader(width: width, height: height, borderRadius: 0),
        errorWidget: (context, url, error) => _buildError(context),
      );
    }
  }

  Widget _buildError(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(child: Icon(Icons.broken_image, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
    );
  }
}
