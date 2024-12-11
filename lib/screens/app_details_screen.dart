import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../providers/apps_provider.dart';
import 'package:provider/provider.dart';

class AppDetailsScreen extends StatelessWidget {
  final AppInfo app;

  const AppDetailsScreen({Key? key, required this.app}) : super(key: key);

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
  Widget build(BuildContext context) {
    final imageProvider = _decodeBase64Image(app.appIcon);

    return Scaffold(
      appBar: AppBar(
        title: Text(app.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _confirmUninstall(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Uygulama Kartı
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Uygulama İkonu
                      imageProvider != null
                        ? CircleAvatar(
                            backgroundImage: imageProvider,
                            radius: 30,
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.apps, size: 40),
                            radius: 30,
                          ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.appName, 
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Paket Adı: ${app.packageName}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Boyut', '${app.size?.toStringAsFixed(2) ?? '0'} MB'),
                  _buildDetailRow('Yüklenme Tarihi', app.formattedInstalledDate),
                  _buildDetailRow('Son Kullanım', app.lastUsedDescription),
                  _buildDetailRow('Kategori', app.category ?? 'Bilinmiyor'),
                ],
              ),
            ),
          ),

          // İzinler Kartı
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İzinler', 
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (app.permissions != null && app.permissions!.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: app.permissions!.map((permission) {
                        return Chip(
                          label: Text(permission),
                          backgroundColor: Colors.blue.shade50,
                        );
                      }).toList(),
                    )
                  else
                    const Text('Herhangi bir izin bulunamadı.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _confirmUninstall(BuildContext context) {
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
                Navigator.of(context).pop(); // Detay ekranından çık
              },
            ),
          ],
        );
      },
    );
  }
}
