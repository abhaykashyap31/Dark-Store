import 'package:flutter/material.dart';

import '../../../../core/constants/order_status.dart';
import '../../../../shared/models/order.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentIndex = OrderStatus.pipeline.indexOf(order.status);
    final isCancelled = order.isCancelled;

    if (isCancelled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final event in order.statusHistory)
            _HistoryTile(event: event, emphasize: event.toStatus == OrderStatus.cancelled),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'This order was cancelled before packing.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < OrderStatus.pipeline.length; i++)
          _PipelineStep(
            status: OrderStatus.pipeline[i],
            isDone: currentIndex >= 0 && i <= currentIndex,
            isCurrent: currentIndex == i,
            isLast: i == OrderStatus.pipeline.length - 1,
          ),
        const SizedBox(height: 16),
        Text(
          'History',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final event in order.statusHistory) _HistoryTile(event: event),
      ],
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({
    required this.status,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  final String status;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDone ? scheme.primary : scheme.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: color,
              size: 22,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isDone ? scheme.primary : scheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 16),
          child: Text(
            OrderStatus.label(status),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isDone ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.event, this.emphasize = false});

  final OrderStatusEvent event;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        emphasize ? Icons.cancel_outlined : Icons.timeline,
        color: emphasize ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(OrderStatus.label(event.toStatus)),
      subtitle: Text(
        [
          if (event.changedByRole != null) event.changedByRole!,
          if (event.note != null) event.note!,
          if (event.changedAt.isNotEmpty) event.changedAt,
        ].join(' · '),
      ),
    );
  }
}
