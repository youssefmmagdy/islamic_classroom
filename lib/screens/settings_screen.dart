import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'تلقائي (حسب النظام)';
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'غامق';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Consumer<AppSettings>(
        builder: (context, appSettings, _) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('اللغة الإنجليزية'),
                subtitle: const Text('تبديل لغة التطبيق إلى الإنجليزية'),
                value: appSettings.isEnglish,
                onChanged: (v) => appSettings.setEnglish(v),
                secondary: const Icon(Icons.language),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('مظهر التطبيق'),
                subtitle: Text(_getThemeModeText(appSettings.themeMode)),
                trailing: DropdownButton<ThemeMode>(
                  value: appSettings.themeMode,
                  onChanged: (ThemeMode? mode) {
                    if (mode != null) {
                      appSettings.setThemeMode(mode);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('تلقائي'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('فاتح'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('غامق'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
