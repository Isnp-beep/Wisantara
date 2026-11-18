import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'auth.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final app = context.read<AppState>();
    await Future.wait([app.init(), Future.delayed(const Duration(milliseconds: 2200))]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => app.loggedIn ? const Shell() : const AuthScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    return Scaffold(
      backgroundColor: C.green,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _c, curve: Curves.easeIn),
          child: ScaleTransition(
            scale: Tween<double>(begin: .7, end: 1).animate(curved),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                decoration: BoxDecoration(color: C.cream, borderRadius: BorderRadius.circular(40)),
                child: const Mascot('happy', height: 190),
              ),
              const SizedBox(height: 26),
              const Text('Wisantara', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: .5)),
              const SizedBox(height: 6),
              const Text('Kenali Indonesia bersama warga lokal', style: TextStyle(color: Color(0xFFE9EEDF), fontSize: 14)),
              const SizedBox(height: 36),
              const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: C.gold)),
            ]),
          ),
        ),
      ),
    );
  }
}
