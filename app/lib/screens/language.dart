import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(t('language'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        for (final code in I18n.codes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Box(
              color: app.lang == code ? C.greenTint : Colors.white,
              onTap: () => app.setLang(code),
              child: Row(children: [
                const LIcon('globe', size: 20, color: C.green),
                const SizedBox(width: 12),
                Expanded(child: Text(I18n.names[code]!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                if (app.lang == code) const LIcon('check', color: C.green),
              ]),
            ),
          ),
      ]),
    );
  }
}
