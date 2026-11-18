import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Unggah foto + ulasan tempat dan (opsional) pemandu. Mengembalikan true jika berhasil.
class PostCreateScreen extends StatefulWidget {
  final int? destinationId;
  final String? destinationName;
  const PostCreateScreen({super.key, this.destinationId, this.destinationName});
  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final _caption = TextEditingController();
  int? _dest;
  int? _guide;
  int _rp = 5, _rg = 5;
  String? _imagePath;
  bool _busy = false;
  List<Map> _dests = [], _guides = [];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _dest = widget.destinationId;
    _init();
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final api = context.read<AppState>().api;
    try {
      final d = await api.get('/destinations');
      final g = await api.get('/guides');
      _dests = List<Map>.from((d as List).map((e) => Map.from(e)));
      _guides = List<Map>.from((g as List).map((e) => Map.from(e)));
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _pick(ImageSource s) async {
    try {
      final x = await ImagePicker().pickImage(source: s, maxWidth: 1600, imageQuality: 85);
      if (x != null) setState(() => _imagePath = x.path);
    } catch (_) {
      if (mounted) toast(context, 'Tidak bisa mengakses foto', error: true);
    }
  }

  Future<void> _submit() async {
    if (_dest == null) {
      toast(context, 'Pilih tempat wisata dulu', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AppState>().api.postMultipart('/posts', {
        'destination_id': '$_dest',
        'rating_place': '$_rp',
        if (_guide != null) 'guide_id': '$_guide',
        if (_guide != null) 'rating_guide': '$_rg',
        'caption': _caption.text.trim(),
      }, filePath: _imagePath);
      if (!mounted) return;
      context.read<AppState>().bump();
      toast(context, 'Postingan terkirim');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bagikan pengalaman')),
        body: !_ready
            ? const Center(child: CircularProgressIndicator(color: C.green))
            : ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 30), children: [
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    builder: (c) => SafeArea(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        ListTile(leading: const LIcon('image'), title: const Text('Pilih dari galeri'), onTap: () { Navigator.pop(c); _pick(ImageSource.gallery); }),
                        ListTile(leading: const LIcon('camera'), title: const Text('Ambil foto'), onTap: () { Navigator.pop(c); _pick(ImageSource.camera); }),
                      ]),
                    ),
                  ),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(color: C.greenTint, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
                    clipBehavior: Clip.antiAlias,
                    child: _imagePath == null
                        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [LIcon('camera', size: 34, color: C.green), SizedBox(height: 8), Text('Tambah foto', style: TextStyle(color: C.green, fontWeight: FontWeight.w700))]))
                        : Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Tempat wisata', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (widget.destinationId != null)
                  Box(child: Text(widget.destinationName ?? 'Destinasi', style: const TextStyle(fontWeight: FontWeight.w700)))
                else
                  DropdownButtonFormField<int>(
                    value: _dest,
                    hint: const Text('Pilih tempat'),
                    items: [for (final d in _dests) DropdownMenuItem(value: (d['id'] as num).toInt(), child: Text('${d['name']}'))],
                    onChanged: (v) => setState(() => _dest = v),
                  ),
                const SizedBox(height: 14),
                const Text('Rating tempat', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                StarPicker(value: _rp, onChanged: (v) => setState(() => _rp = v)),
                const SizedBox(height: 14),
                const Text('Pakai pemandu? (opsional)', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: _guide,
                  hint: const Text('Tanpa pemandu'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Tanpa pemandu')),
                    for (final g in _guides) DropdownMenuItem<int?>(value: (g['id'] as num).toInt(), child: Text('${g['name']}')),
                  ],
                  onChanged: (v) => setState(() => _guide = v),
                ),
                if (_guide != null) ...[
                  const SizedBox(height: 12),
                  const Text('Rating pemandu', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  StarPicker(value: _rg, onChanged: (v) => setState(() => _rg = v)),
                ],
                const SizedBox(height: 14),
                TextField(controller: _caption, maxLength: 500, minLines: 3, maxLines: 5, decoration: const InputDecoration(hintText: 'Ceritakan pengalamanmu…')),
                const SizedBox(height: 8),
                FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Mengirim…' : 'Kirim')),
              ]),
      );
}
