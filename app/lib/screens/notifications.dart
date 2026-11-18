import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _icons = {'payment': 'wallet', 'reminder': 'bell', 'plan': 'clipboard-list', 'community': 'message-circle'};

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(t('notifications'))),
      body: FutureView(
        load: () async {
          final r = await app.api.get('/notifications');
          await app.api.post('/notifications/read-all');
          app.unread = 0;
          return r;
        },
        builder: (c, data, reload) {
          final items = List<Map>.from((data['items'] as List).map((e) => Map.from(e)));
          if (items.isEmpty) return EmptyView(t('empty'), pose: 'berjalan');
          return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
            for (final n in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Box(
                  color: n['is_read'] == true ? Colors.white : C.goldTint,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: C.greenTint, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: LIcon(_icons['${n['type']}'] ?? 'bell', color: C.green, size: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${n['title']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${n['body']}', style: const TextStyle(color: C.muted, height: 1.35)),
                        const SizedBox(height: 4),
                        Text(ago(n['created_at'] as String?), style: const TextStyle(color: C.muted, fontSize: 11.5)),
                      ]),
                    ),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}
