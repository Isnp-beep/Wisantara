import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'language.dart';
import 'shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _register = false, _busy = false, _hide = true;
  String _role = 'turis';
  final _name = TextEditingController(), _email = TextEditingController(), _pass = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    if (_email.text.trim().isEmpty || _pass.text.isEmpty || (_register && _name.text.trim().isEmpty)) {
      toast(context, 'Lengkapi semua kolom', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      if (_register) {
        await app.register(_name.text.trim(), _email.text.trim(), _pass.text, _role);
      } else {
        await app.login(_email.text.trim(), _pass.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const Shell()), (r) => false);
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      toast(context, 'Isi email dulu');
      return;
    }
    try {
      final r = await context.read<AppState>().api.post('/auth/forgot', {'email': _email.text.trim()});
      if (mounted) toast(context, '${r['message']}');
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  Future<void> _server() async {
    final app = context.read<AppState>();
    final ctl = TextEditingController(text: app.baseUrl);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Alamat server API'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ctl, keyboardType: TextInputType.url),
          const SizedBox(height: 8),
          const Text('Emulator: http://10.0.2.2/Wisantara/api\nHP asli: http://IP-LAPTOP/Wisantara/api',
              style: TextStyle(fontSize: 12, color: C.muted)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(t('save'))),
        ],
      ),
    );
    if (ok == true) {
      await app.setBaseUrl(ctl.text);
      if (mounted) toast(context, 'Server diperbarui');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 32), children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(onPressed: _server, icon: const LIcon('settings', size: 20)),
            IconButton(onPressed: () => go(context, const LanguageScreen()), icon: const LIcon('globe', size: 20)),
          ]),
          const Center(child: Mascot('jempol', height: 150)),
          const SizedBox(height: 8),
          const Center(child: Text('Wisantara', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: C.green))),
          const SizedBox(height: 4),
          Center(child: Text(_register ? t('register') : t('login'), style: const TextStyle(color: C.muted))),
          const SizedBox(height: 22),
          if (_register) ...[
            TextField(controller: _name, decoration: InputDecoration(hintText: t('name'))),
            const SizedBox(height: 12),
          ],
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: t('email'))),
          const SizedBox(height: 12),
          TextField(
            controller: _pass,
            obscureText: _hide,
            decoration: InputDecoration(
              hintText: t('password'),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hide = !_hide),
                icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: C.muted),
              ),
            ),
          ),
          if (_register) ...[
            const SizedBox(height: 14),
            Row(children: [
              Pill('Wisatawan', selected: _role == 'turis', onTap: () => setState(() => _role = 'turis'), icon: 'backpack'),
              Pill('Warga lokal', selected: _role == 'lokal', onTap: () => setState(() => _role = 'lokal'), icon: 'home'),
            ]),
          ] else
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _forgot, child: Text(t('forgot')))),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(_register ? t('register') : t('login')),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _register = !_register),
            child: Text(_register ? 'Sudah punya akun? ${t('login')}' : 'Belum punya akun? ${t('register')}'),
          ),
          if (!_register)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Akun contoh: raka@wisantara.id / password123', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: C.muted)),
            ),
        ]),
      ),
    );
  }
}
