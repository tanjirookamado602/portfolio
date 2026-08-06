import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimelineItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final String? date;
  final IconData? icon; // Unused in terminal design
  final Color? color;
  final bool isFirst;
  final bool isLast;
  final bool isActive;

  const TimelineItem({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.date,
    this.icon,
    this.color,
    this.isFirst = false,
    this.isLast = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date (Left aligned column)
          if (MediaQuery.of(context).size.width > 600)
            SizedBox(
              width: 120,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 16),
                child: Text(
                  date ?? '',
                  style: AppTheme.labelMeta.copyWith(
                    color: AppTheme.textFaint,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          
          // Timeline Line and Node
          _buildTimelineIndicator(),
          
          const SizedBox(width: 24),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40), // Spacing between items
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator() {
    return Column(
      children: [
        // Top line
        Container(
          width: 1,
          height: 8,
          color: isFirst ? Colors.transparent : AppTheme.borderSubtle,
        ),
        // Node
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accentPrimary : AppTheme.textFaint,
            shape: BoxShape.circle,
          ),
        ),
        // Bottom line
        Expanded(
          child: Container(
            width: 1,
            color: isLast ? Colors.transparent : AppTheme.borderSubtle,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (MediaQuery.of(context).size.width <= 600 && date != null)
          Text(
            date!,
            style: AppTheme.labelMeta.copyWith(color: AppTheme.textFaint),
          ),
        if (MediaQuery.of(context).size.width <= 600 && date != null)
          const SizedBox(height: 4),
        
        Text(
          title,
          style: AppTheme.titleMedium,
        ),
        
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ],
        
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(
            description!,
            style: AppTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
