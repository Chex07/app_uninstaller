import 'package:flutter/foundation.dart';
import '../models/app_info.dart';
import 'package:flutter/services.dart';

class AppsProvider with ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('app_uninstaller/apps');

  List<AppInfo> _apps = [];
  bool _isLoading = false;
  Map<String, dynamic> _storageInfo = {};
  Map<String, dynamic> _appStats = {};
  String? _errorMessage;
  
  // Toplu kaldırma için yeni değişkenler
  List<String> _appsToUninstall = [];
  bool _isUninstalling = false;

  List<AppInfo> get apps => _apps;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get storageInfo => _storageInfo;
  Map<String, dynamic> get appStats => _appStats;
  String? get errorMessage => _errorMessage;
  bool get isUninstalling => _isUninstalling;

  AppsProvider() {
    // Uygulama kaldırma sonucunu dinle
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'uninstallResult') {
        _handleUninstallResult(call.arguments);
      }
    });
  }

  // Toplu uygulama kaldırma başlatma
  Future<void> startBulkUninstall(List<String> packageNames) async {
    if (_isUninstalling) return;

    _isUninstalling = true;
    _appsToUninstall = List.from(packageNames);
    notifyListeners();

    // İlk uygulamayı kaldırmaya başla
    _uninstallNextApp();
  }

  // Sıradaki uygulamayı kaldır
  Future<void> _uninstallNextApp() async {
    if (_appsToUninstall.isEmpty) {
      _isUninstalling = false;
      notifyListeners();
      return;
    }

    try {
      final packageName = _appsToUninstall.first;
      await _channel.invokeMethod('uninstallApp', packageName);
    } catch (e) {
      print('Uygulama kaldırma hatası: $e');
      // Hata olsa bile bir sonraki uygulamaya geç
      _appsToUninstall.removeAt(0);
      _uninstallNextApp();
    }
  }

  // Kaldırma sonucunu işle
  void _handleUninstallResult(bool success) {
    if (success && _appsToUninstall.isNotEmpty) {
      // Başarıyla kaldırılan uygulamayı listeden çıkar
      final removedPackage = _appsToUninstall.removeAt(0);
      
      // Uygulamayı listeden sil
      _apps.removeWhere((app) => app.packageName == removedPackage);
      
      // İstatistikleri yeniden hesapla
      _calculateAppStats();
      
      // Sonraki uygulamayı kaldırmaya devam et
      _uninstallNextApp();
      
      notifyListeners();
    } else if (!success) {
      // Kaldırma başarısız oldu, bir sonraki uygulamaya geç
      if (_appsToUninstall.isNotEmpty) {
        _appsToUninstall.removeAt(0);
        _uninstallNextApp();
      } else {
        _isUninstalling = false;
        notifyListeners();
      }
    }
  }

  // Tek bir uygulamayı kaldırma
  Future<bool> uninstallApp(String packageName) async {
    try {
      _appsToUninstall = [packageName];
      _isUninstalling = true;
      notifyListeners();

      await _channel.invokeMethod('uninstallApp', packageName);
      return true;
    } catch (e) {
      print('Uygulama kaldırılırken hata: $e');
      _errorMessage = 'Uygulama kaldırılamadı: ${e.toString()}';
      _isUninstalling = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchStorageInfo() async {
    try {
      final dynamic result = await _channel.invokeMethod('getStorageInfo');
      
      // Tüm olası Map türleri için esnek parsing
      if (result is Map) {
        _storageInfo = {
          'totalStorage': _parseStorageValue(result['totalStorage']),
          'usedStorage': _parseStorageValue(result['usedStorage']),
          'availableStorage': _parseStorageValue(result['availableStorage']),
          'usedPercentage': _parsePercentage(result['usedPercentage'])
        };
      } else {
        // Fallback to default values if result is not a map
        _storageInfo = {
          'totalStorage': 0.0,
          'usedStorage': 0.0,
          'availableStorage': 0.0,
          'usedPercentage': 0
        };
        _errorMessage = 'Depolama bilgisi alınamadı: Geçersiz veri formatı';
      }
      
      notifyListeners();
    } on PlatformException catch (e) {
      print('Depolama bilgisi alınırken hata: ${e.message}');
      _storageInfo = {
        'totalStorage': 0.0,
        'usedStorage': 0.0,
        'availableStorage': 0.0,
        'usedPercentage': 0
      };
      _errorMessage = 'Depolama bilgisi alınamadı: ${e.message}';
      notifyListeners();
    } catch (e) {
      print('Beklenmedik hata: $e');
      _storageInfo = {
        'totalStorage': 0.0,
        'usedStorage': 0.0,
        'availableStorage': 0.0,
        'usedPercentage': 0
      };
      _errorMessage = 'Beklenmedik bir hata oluştu';
      notifyListeners();
    }
  }

  Future<void> fetchInstalledApps() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final List<dynamic> appList = await _channel.invokeMethod('getInstalledApps');
      
      // Esnek parsing
      _apps = appList.map((app) {
        try {
          // Tüm Map türlerini Map<String, dynamic>'e çevir
          final Map<String, dynamic> safeMap = (app is Map) 
            ? app.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};
          
          return AppInfo.fromMap(safeMap);
        } catch (e) {
          print('Uygulama parse hatası: $e');
          return null;
        }
      }).whereType<AppInfo>().toList();
      
      // İstatistikleri hesapla
      _calculateAppStats();

      _isLoading = false;
      notifyListeners();
    } on PlatformException catch (e) {
      print('Uygulama listesi alınırken hata: ${e.message}');
      _errorMessage = 'Uygulama listesi alınamadı: ${e.message}';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Beklenmedik hata: $e');
      _errorMessage = 'Uygulama listesi yüklenirken beklenmedik bir hata oluştu';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateAppStats() {
    _appStats = {
      'totalApps': _apps.length,
      'totalSize': _calculateTotalSize(),
      'largestApp': _findLargestApp(),
      'oldestApp': _findOldestApp(),
      'categoryDistribution': _calculateCategoryDistribution(),
    };
  }

  double _calculateTotalSize() {
    return _apps.fold(0.0, (total, app) => 
      total + (double.tryParse(app.size?.toString() ?? '0') ?? 0)
    );
  }

  AppInfo? _findLargestApp() {
    if (_apps.isEmpty) return null;
    return _apps.reduce((a, b) => 
      (double.tryParse(a.size?.toString() ?? '0') ?? 0) > 
      (double.tryParse(b.size?.toString() ?? '0') ?? 0) ? a : b
    );
  }

  AppInfo? _findOldestApp() {
    if (_apps.isEmpty) return null;
    return _apps.reduce((a, b) => 
      a.installedDate.isBefore(b.installedDate) ? a : b
    );
  }

  Map<String, int> _calculateCategoryDistribution() {
    final Map<String, int> categories = {};
    for (var app in _apps) {
      categories[app.category ?? 'Diğer'] = 
        (categories[app.category ?? 'Diğer'] ?? 0) + 1;
    }
    return categories;
  }

  // Performans optimizasyonu için ek metodlar
  List<AppInfo> getAppsByCategory(String category) {
    return _apps.where((app) => app.category == category).toList();
  }

  List<AppInfo> getLargeApps({double threshold = 100.0}) {
    return _apps.where((app) {
      final size = double.tryParse(app.size?.toString() ?? '0') ?? 0;
      return size > threshold;
    }).toList();
  }

  List<AppInfo> getUnusedApps({int monthsInactive = 3}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: monthsInactive * 30));
    return _apps.where((app) => 
      app.lastUsedDate.isBefore(cutoffDate)
    ).toList();
  }

  // Yardımcı metodlar
  double _parseStorageValue(dynamic value) {
    if (value == null) return 0.0;
    try {
      // String veya num değerlerini parse et
      final numValue = value is String 
        ? double.tryParse(value) ?? 0.0 
        : (value is num ? value.toDouble() : 0.0);
      
      // Byte'ı GB'a çevir
      return numValue / (1024 * 1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  int _parsePercentage(dynamic value) {
    if (value == null) return 0;
    try {
      // String veya num değerlerini parse et
      return value is String 
        ? int.tryParse(value) ?? 0 
        : (value is num ? value.toInt() : 0);
    } catch (e) {
      return 0;
    }
  }
}
