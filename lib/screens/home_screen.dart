import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/apps_provider.dart';
import '../models/app_info.dart';
import 'app_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AppInfo> _filteredApps = [];

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
    final provider = Provider.of<AppsProvider>(context, listen: false);
    setState(() {
      _filteredApps = provider.apps
          .where((app) => 
            app.appName.toLowerCase().contains(query.toLowerCase()) || 
            app.packageName.toLowerCase().contains(query.toLowerCase())
          )
          .toList();
    });
  }

  void _confirmUninstall(AppInfo app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uygulamayı Kaldır'),
        content: Text(
          '${app.appName} uygulamasını kaldırmak istediğinize emin misiniz?'
        ),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Kaldır'),
            onPressed: () {
              Provider.of<AppsProvider>(context, listen: false).uninstallApp(app.packageName);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Uninstaller'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
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
              ),
              onChanged: _filterApps,
            ),
          ),
          Expanded(
            child: Consumer<AppsProvider>(
              builder: (context, provider, child) {
                final apps = _searchController.text.isEmpty 
                  ? provider.apps 
                  : _filteredApps;

                if (provider.apps.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.apps, size: 50),
                        title: Text(
                          app.appName, 
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.packageName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text('${app.size ?? '0'} MB'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmUninstall(app),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
