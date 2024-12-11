// Gereksiz import'u kaldırdık
// import 'dart:convert';

class AppInfo {
  final String packageName;
  final String appName;
  final String? appIcon; // Base64 encoded icon
  final double? size;
  final DateTime installedDate;
  final DateTime lastUsedDate;
  final List<String>? permissions;
  final String? category;

  AppInfo({
    required this.packageName,
    required this.appName,
    this.appIcon,
    this.size,
    required this.installedDate,
    required this.lastUsedDate,
    this.permissions,
    this.category,
  });

  // Tarih formatını güzelleştiren getter
  String get formattedInstalledDate {
    return _formatDate(installedDate);
  }

  // Son kullanım açıklaması
  String get lastUsedDescription {
    final now = DateTime.now();
    final difference = now.difference(lastUsedDate);

    if (difference.inDays == 0) return 'Bugün';
    if (difference.inDays == 1) return 'Dün';
    if (difference.inDays < 30) return '${difference.inDays} gün önce';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} ay önce';
    return '${(difference.inDays / 365).floor()} yıl önce';
  }

  // Tarih formatını düzenleyen yardımcı metod
  String _formatDate(DateTime date) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Map'ten AppInfo oluşturma
  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? 'Bilinmeyen Uygulama',
      appIcon: map['appIcon'], // Base64 encoded icon
      size: _parseSize(map['size']),
      installedDate: _parseDate(map['installedTime']),
      lastUsedDate: _parseDate(map['lastUsedTime']),
      permissions: _parsePermissions(map['permissions']),
      category: map['category'] ?? 'Diğer',
    );
  }

  // Boyutu güvenli bir şekilde parse eden statik metod
  static double _parseSize(dynamic size) {
    if (size == null) return 0.0;
    if (size is double) return size;
    if (size is int) return size.toDouble();
    if (size is String) {
      return double.tryParse(size) ?? 0.0;
    }
    return 0.0;
  }

  // Tarihi güvenli bir şekilde parse eden statik metod
  static DateTime _parseDate(dynamic timestamp) {
    try {
      // Timestamp'i integer olarak parse et
      final int? parsedTimestamp = timestamp is String 
        ? int.tryParse(timestamp) 
        : timestamp as int?;
      
      // Geçerli bir timestamp varsa DateTime'a çevir
      return parsedTimestamp != null 
        ? DateTime.fromMillisecondsSinceEpoch(parsedTimestamp) 
        : DateTime.now();
    } catch (e) {
      // Parse edilemezse şu anki tarihi kullan
      print('Tarih parse edilemedi: $timestamp');
      return DateTime.now();
    }
  }

  // İzinleri parse eden statik metod
  static List<String> _parsePermissions(dynamic permissions) {
    if (permissions == null) return [];
    
    // Zaten liste ise olduğu gibi dön
    if (permissions is List) {
      return permissions.map((p) => p.toString()).toList();
    }
    
    // String ise virgülle ayır
    if (permissions is String) {
      return permissions.split(',');
    }
    
    return [];
  }

  // Eşitlik kontrolü için gerekli metodlar
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is AppInfo && 
    packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'appIcon': appIcon,
      'size': size,
      'installedTime': installedDate.millisecondsSinceEpoch,
      'lastUsedTime': lastUsedDate.millisecondsSinceEpoch,
      'permissions': permissions,
      'category': category,
    };
  }
}
