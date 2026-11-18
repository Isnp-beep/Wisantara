import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/state.dart';
import 'core/theme.dart';
import 'screens/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const WisantaraApp()));
}

class WisantaraApp extends StatelessWidget {
  const WisantaraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Wisantara',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashScreen(),
      );
}
