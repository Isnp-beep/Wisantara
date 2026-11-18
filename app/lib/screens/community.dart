import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'post_create.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});
  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  String _tab = 'all';
  int _rev = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return SafeArea(
      bottom: false,
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 10), child: Text(t('community'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Pill(t('for_you'), selected: _tab == 'all', onTap: () => setState(() => _tab = 'all')),
              Pill(t('following'), selected: _tab == 'following', onTap: () => setState(() => _tab = 'following')),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureView(
              key: ValueKey('$_tab$_rev'),
              load: () => app.api.get('/posts', query: {'tab': _tab}),
              builder: (c, data, reload) {
                final posts = List<Map>.from((data as List).map((e) => Map.from(e)));
                if (posts.isEmpty) {
                  return EmptyView(_tab == 'following' ? 'Ikuti traveler lain untuk melihat postingannya di sini.' : t('empty'));
                }
                return RefreshIndicator(
                  color: C.green,
                  onRefresh: () async => reload(),
                  child: ListView(padding: const EdgeInsets.only(bottom: 90), children: [for (final p in posts) PostCard(post: p)]),
                );
              },
            ),
          ),
        ]),
        Positioned(
          right: 20, bottom: 18,
          child: FloatingActionButton.extended(
            backgroundColor: C.green,
            foregroundColor: Colors.white,
            onPressed: () async {
              final ok = await go<bool>(context, const PostCreateScreen());
              if (ok == true) setState(() => _rev++);
            },
            icon: const LIcon('camera', color: Colors.white, size: 20),
            label: Text(t('post')),
          ),
        ),
      ]),
    );
  }
}

class PostCard extends StatefulWidget {
  final Map post;
  const PostCard({super.key, required this.post});
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _liked = widget.post['liked'] == true;
  late int _likes = (widget.post['likes'] as num).toInt();
  late int _comments = (widget.post['comments'] as num).toInt();
  late bool _following = widget.post['following'] == true;

  Future<void> _like() async {
    try {
      final r = await context.read<AppState>().api.post('/posts/${widget.post['id']}/like');
      if (mounted) {
        setState(() {
          _liked = r['liked'] == true;
          _likes = (r['likes'] as num).toInt();
        });
      }
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  Future<void> _follow() async {
    try {
      final r = await context.read<AppState>().api.post('/users/${widget.post['user']['id']}/follow');
      if (mounted) setState(() => _following = r['following'] == true);
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final me = context.read<AppState>().user?['id'];
    final u = p['user'] as Map;
    final isMe = me != null && (me as num).toInt() == (u['id'] as num).toInt();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
          child: Row(children: [
            CircleAvatar(radius: 19, backgroundColor: C.sage, child: Text('${u['name']}'.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text('${u['name']}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                  if (u['role'] == 'lokal')
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: C.greenTint, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Warlok', style: TextStyle(fontSize: 10, color: C.green, fontWeight: FontWeight.w800)),
                    ),
                ]),
                Text('${p['destination_name']} · ${ago(p['created_at'] as String?)}', style: const TextStyle(color: C.muted, fontSize: 12)),
              ]),
            ),
            if (!isMe)
              TextButton(onPressed: _follow, child: Text(_following ? t('following') : 'Ikuti', style: TextStyle(color: _following ? C.muted : C.green, fontWeight: FontWeight.w800))),
          ]),
        ),
        if (p['image_url'] != null) NetImg(p['image_url'] as String?, width: double.infinity, height: 230),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Tempat ', style: TextStyle(color: C.muted, fontSize: 12.5)),
              Stars(p['rating_place'] as num),
              if (p['rating_guide'] != null) ...[
                const SizedBox(width: 12),
                Text('Pemandu ${p['guide_name'] ?? ''} ', style: const TextStyle(color: C.muted, fontSize: 12.5)),
                Stars(p['rating_guide'] as num),
              ],
            ]),
            if ('${p['caption']}'.isNotEmpty) ...[const SizedBox(height: 8), Text('${p['caption']}', style: const TextStyle(height: 1.4))],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 14, 8),
          child: Row(children: [
            IconButton(onPressed: _like, icon: Icon(_liked ? Icons.favorite : Icons.favorite_border, color: C.red)),
            Text('$_likes', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () async {
                final n = await go<int>(context, CommentsScreen(postId: (p['id'] as num).toInt()));
                if (n != null && mounted) setState(() => _comments = n);
              },
              icon: const LIcon('message-circle', size: 22),
            ),
            Text('$_comments', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

/// Komentar sebuah postingan. Mengembalikan jumlah komentar terbaru saat ditutup.
class CommentsScreen extends StatefulWidget {
  final int postId;
  const CommentsScreen({super.key, required this.postId});
  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _ctl = TextEditingController();
  List<Map> _items = [];
  bool _loading = true, _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await context.read<AppState>().api.get('/posts/${widget.postId}/comments');
      _items = List<Map>.from((r as List).map((e) => Map.from(e)));
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await context.read<AppState>().api.post('/posts/${widget.postId}/comments', {'body': text});
      _ctl.clear();
      await _load();
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.of(context).pop(_items.length);
        },
        child: Scaffold(
          appBar: AppBar(title: Text(t('comment'))),
          body: Column(children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: C.green))
                  : _items.isEmpty
                      ? const EmptyView('Belum ada komentar')
                      : ListView(padding: const EdgeInsets.all(20), children: [
                          for (final c in _items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                CircleAvatar(radius: 16, backgroundColor: C.sage, child: Text('${c['user']['name']}'.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 13))),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${c['user']['name']}  ·  ${ago(c['created_at'] as String?)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                    const SizedBox(height: 2),
                                    Text('${c['body']}'),
                                  ]),
                                ),
                              ]),
                            ),
                        ]),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(children: [
                  Expanded(child: TextField(controller: _ctl, decoration: const InputDecoration(hintText: 'Tulis komentar…', isDense: true))),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: C.green),
                    onPressed: _busy ? null : _send,
                    icon: const LIcon('send', color: Colors.white, size: 20),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
}
