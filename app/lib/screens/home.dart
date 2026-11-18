import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'detail.dart';
import 'guides.dart';
import 'map_screen.dart';
import 'notifications.dart';
import 'plans.dart';
import 'recommend.dart';
import 'translate.dart';

class HomeTab extends StatelessWidget {
  final ValueChanged<int> onJump;
  const HomeTab({super.key, required this.onJump});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return SafeArea(
      bottom: false,
      child: FutureView(
        load: () => app.api.get('/destinations', query: {'lang': app.lang}),
        builder: (c, data, reload) {
          final list = List<Map>.from((data as List).map((e) => Map.from(e)));
          final withPhoto = list.where((d) => (d['image_url'] ?? '') != '').toList();
          return RefreshIndicator(
            color: C.green,
            onRefresh: () async => reload(),
            child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              _Header(),
              if (withPhoto.isNotEmpty) _Slider(items: withPhoto),
              _AiBox(),
              SectionTitle(t('explore')),
              _Quick(onJump: onJump),
              SectionTitle(t('popular')),
              for (final d in (List<Map>.from(list)..sort((a, b) => ((b['rating'] as num)).compareTo(a['rating'] as num))).take(4))
                DestCard(d: d, onTap: () => go(context, DetailScreen(id: (d['id'] as num).toInt()))),
            ]),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final name = '${app.user?['name'] ?? ''}'.split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${t('greeting')}, $name 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const Text('Kenali Indonesia bersama warga lokal', style: TextStyle(color: C.muted, fontSize: 13)),
          ]),
        ),
        Stack(clipBehavior: Clip.none, children: [
          IconButton(
            onPressed: () async {
              await go(context, const NotificationsScreen());
              app.refreshUnread();
            },
            icon: const LIcon('bell', size: 24),
          ),
          if (app.unread > 0)
            Positioned(
              right: 6, top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(10)),
                child: Text('${app.unread}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      ]),
    );
  }
}

class _Slider extends StatefulWidget {
  final List<Map> items;
  const _Slider({required this.items});
  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> {
  final _pc = PageController(viewportFraction: .92);
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pc.hasClients || widget.items.isEmpty) return;
      _pc.animateToPage((_i + 1) % widget.items.length, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _pc,
            itemCount: widget.items.length,
            onPageChanged: (v) => setState(() => _i = v),
            itemBuilder: (c, i) {
              final d = widget.items[i];
              return GestureDetector(
                onTap: () => go(context, DetailScreen(id: (d['id'] as num).toInt())),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(fit: StackFit.expand, children: [
                      NetImg(d['image_url'] as String?),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xCC2B1D14)]),
                        ),
                      ),
                      Positioned(
                        left: 16, right: 16, bottom: 14,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${d['name']}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          Text('${d['region']} · ${rupiah(d['price_idr'] as num)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < widget.items.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _i ? 20 : 7, height: 7,
              decoration: BoxDecoration(color: i == _i ? C.green : C.line, borderRadius: BorderRadius.circular(4)),
            ),
        ]),
      ]);
}

class _AiBox extends StatefulWidget {
  @override
  State<_AiBox> createState() => _AiBoxState();
}

class _AiBoxState extends State<_AiBox> {
  final _ctl = TextEditingController();
  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _go([String? text]) {
    final p = (text ?? _ctl.text).trim();
    go(context, RecommendScreen(prompt: p));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: C.goldTint, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const LIcon('sparkles', color: C.brown, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(t('ask_ai'), style: const TextStyle(fontWeight: FontWeight.w800))),
              const Mascot('berpikir', height: 54),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _ctl,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _go(),
              decoration: InputDecoration(
                hintText: 'mis. budget 2 juta 3 hari alam',
                suffixIcon: IconButton(onPressed: _go, icon: const LIcon('send', color: C.green, size: 20)),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                Pill('Budget 1 juta', onTap: () => _go('budget 1 juta 2 hari')),
                Pill('Gunung 3 hari', onTap: () => _go('gunung 3 hari budget 2 juta')),
                Pill('Pantai santai', onTap: () => _go('pantai 2 hari budget 3 juta')),
                Pill('Budaya & sejarah', onTap: () => _go('budaya sejarah candi 2 hari')),
              ]),
            ),
          ]),
        ),
      );
}

class _Quick extends StatelessWidget {
  final ValueChanged<int> onJump;
  const _Quick({required this.onJump});
  @override
  Widget build(BuildContext context) {
    final items = <List<dynamic>>[
      ['map', t('map'), () => go(context, const MapScreen())],
      ['users', t('guides'), () => go(context, const GuidesScreen())],
      ['clipboard-list', t('planner'), () => go(context, const PlansScreen())],
      ['languages', t('translate'), () => go(context, const TranslateScreen())],
      ['compass', t('explore'), () => onJump(1)],
      ['message-circle', t('community'), () => onJump(2)],
      ['ticket', t('orders'), () => onJump(3)],
      ['bell', t('notifications'), () => go(context, const NotificationsScreen())],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: .95,
        children: [
          for (final it in items)
            GestureDetector(
              onTap: it[2] as VoidCallback,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(color: C.greenTint, borderRadius: BorderRadius.circular(18)),
                  child: Center(child: LIcon(it[0] as String, color: C.green, size: 24)),
                ),
                const SizedBox(height: 6),
                Text(it[1] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
      ),
    );
  }
}
