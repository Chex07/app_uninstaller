import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showSystemApps = false;
  bool _darkModeEnabled = false;
  bool _analyticsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sistem Uygulamalarını Göster'),
            value: _showSystemApps,
            onChanged: (bool value) {
              setState(() {
                _showSystemApps = value;
                // Gelecekte sistem uygulamalarını filtrelemek için kullanılabilir
              });
            },
          ),
          SwitchListTile(
            title: const Text('Karanlık Mod'),
            value: _darkModeEnabled,
            onChanged: (bool value) {
              setState(() {
                _darkModeEnabled = value;
                // Tema değişikliği için gerekli kod eklenecek
              });
            },
          ),
          SwitchListTile(
            title: const Text('Kullanım Analizlerini Topla'),
            subtitle: const Text('Uygulama performansını ve kullanımını izle'),
            value: _analyticsEnabled,
            onChanged: (bool value) {
              setState(() {
                _analyticsEnabled = value;
                // Analitik toplama ayarı
              });
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Uygulama Hakkında'),
            subtitle: const Text('Versiyon 1.0.0'),
            onTap: () {
              _showAboutDialog();
            },
            trailing: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('App Uninstaller'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Versiyon: 1.0.0'),
              SizedBox(height: 10),
              Text('Geliştiriciler: Codeium Mühendislik Ekibi'),
              SizedBox(height: 10),
              Text('Bu uygulama, Android cihazlarınızdaki uygulamaları yönetmenize ve kaldırmanıza yardımcı olur.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }
}
