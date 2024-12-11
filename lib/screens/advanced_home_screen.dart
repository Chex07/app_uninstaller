import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/apps_provider.dart';
import '../models/app_info.dart';
import 'settings_screen.dart';
import 'app_details_screen.dart';

class AdvancedHomeScreen extends StatefulWidget {
  const AdvancedHomeScreen({Key? key}) : super(key: key);

  @override
  _AdvancedHomeScreenState createState() => _AdvancedHomeScreenState();
}

class _AdvancedHomeScreenState extends State<AdvancedHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AppInfo> _filteredApps = [];
  List<String> _selectedApps = [];

  // Base64 decode için güvenli bir fonksiyon
  ImageProvider? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;

    try {
      // Base64 prefix'ini kaldır
      final cleanBase64 = base64String.contains(',') 
          ? base64String.split(',').last 
          : base64String;

      // Base64 string'ini temizle
      final base64Cleaned = cleanBase64.replaceAll(RegExp(r'\s+'), '');

      // Decode et
      final Uint8List bytes = base64Decode(base64Cleaned);
      return MemoryImage(bytes);
    } catch (e) {
      print('Base64 decode hatası: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppsProvider>(context, listen: false)
        ..fetchInstalledApps()
        ..fetchStorageInfo();
    });
  }

  void _filterApps(String query) {
    final appsProvider = Provider.of<AppsProvider>(context, listen: false);
    setState(() {
      _filteredApps = appsProvider.apps.where((app) =>
        app.appName.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  void _selectApp(String packageName) {
    setState(() {
      if (_selectedApps.contains(packageName)) {
        _selectedApps.remove(packageName);
      } else {
        _selectedApps.add(packageName);
      }
    });
  }

  void _uninstallSelectedApps() {
    final appsProvider = Provider.of<AppsProvider>(context, listen: false);
    
    // Toplu kaldırma onay ekranı
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${_selectedApps.length} Uygulamayı Kaldır'),
          content: Text('Seçilen ${_selectedApps.length} uygulamayı kaldırmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Kaldır'),
              onPressed: () {
                Navigator.of(context).pop();
                // Toplu kaldırma işlemini başlat
                appsProvider.startBulkUninstall(_selectedApps);
                // Seçimleri temizle
                setState(() {
                  _selectedApps.clear();
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showAppOptionsBottomSheet(AppInfo app) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Uygulamayı Kaldır'),
              onTap: () {
                Navigator.pop(context);
                _confirmUninstall(app);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Uygulama Detayları'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppDetailsScreen(app: app),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmUninstall(AppInfo app) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Uygulamayı Kaldır'),
          content: Text('${app.appName} uygulamasını kaldırmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Kaldır'),
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AppsProvider>(context, listen: false).uninstallApp(app.packageName);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Uninstaller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppsProvider>(
        builder: (context, appsProvider, child) {
          // Hata durumunda hata mesajını göster
          if (appsProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline, 
                    color: Colors.red, 
                    size: 60
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hata Oluştu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appsProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      appsProvider
                        ..fetchInstalledApps()
                        ..fetchStorageInfo();
                    },
                    child: const Text('Yeniden Dene'),
                  ),
                ],
              ),
            );
          }

          // Yükleme sırasında gösterge
          if (appsProvider.isLoading || appsProvider.isUninstalling) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uygulamalar yükleniyor veya kaldırılıyor...')
                ],
              ),
            );
          }

          return Column(
            children: [
              // Depolama Kartı
              Card(
                color: Colors.blue[50],
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Depolama Kullanımı',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Toplam: ${(appsProvider.storageInfo['totalStorage'] ?? 0.0).toStringAsFixed(2)} GB',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Kullanılan: ${(appsProvider.storageInfo['usedStorage'] ?? 0.0).toStringAsFixed(2)} GB',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: ((appsProvider.storageInfo['usedPercentage'] ?? 0) / 100.0).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (appsProvider.storageInfo['usedPercentage'] ?? 0) > 80 
                            ? Colors.red 
                            : Colors.blue
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Kullanım: %${appsProvider.storageInfo['usedPercentage'] ?? 0}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // Arama ve Filtreleme
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Uygulama ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterApps('');
                          },
                        )
                      : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: _filterApps,
                ),
              ),

              // Uygulama Listesi
              Expanded(
                child: appsProvider.apps.isEmpty
                  ? const Center(
                      child: Text(
                        'Hiç uygulama bulunamadı.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredApps.isEmpty 
                        ? appsProvider.apps.length 
                        : _filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = _filteredApps.isEmpty 
                          ? appsProvider.apps[index] 
                          : _filteredApps[index];

                        // Güvenli base64 decode
                        final imageProvider = _decodeBase64Image(app.appIcon);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _selectedApps.contains(app.packageName),
                                  onChanged: (_) => _selectApp(app.packageName),
                                ),
                                const SizedBox(width: 8),
                                // Uygulama ikonu
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: imageProvider,
                                  child: imageProvider == null
                                      ? const Icon(Icons.apps)
                                      : null,
                                ),
                              ],
                            ),
                            title: Text(
                              app.appName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${app.size?.toStringAsFixed(2) ?? '0'} MB'),
                                Text('Son kullanım: ${app.lastUsedDescription}'),
                                Text('Yüklenme: ${app.formattedInstalledDate}'),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: (app.permissions ?? [])
                                    .take(3)
                                    .map((perm) => Chip(
                                      label: Text(perm, style: const TextStyle(fontSize: 10)),
                                      backgroundColor: Colors.blue.shade50,
                                    ))
                                    .toList(),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showAppOptionsBottomSheet(app),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AppDetailsScreen(app: app),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedApps.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: _uninstallSelectedApps,
            icon: const Icon(Icons.delete),
            label: Text('${_selectedApps.length} Uygulamayı Kaldır'),
          )
        : null,
    );
  }
}
