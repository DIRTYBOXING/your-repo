import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SMART CACHE SERVICE — Multi-Layer Caching for Hot Data
/// Memory -> SharedPreferences -> Firestore with TTL & LRU eviction
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;

enum CacheLayer { memory, local, remote }

enum CachePriority { low, normal, high, critical }

class CacheEntry<T> {
  final String key;
  final T value;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final CachePriority priority;
  int accessCount;
  DateTime lastAccessedAt;

  CacheEntry({
    required this.key,
    required this.value,
    required this.cachedAt,
    required this.expiresAt,
    this.priority = CachePriority.normal,
    this.accessCount = 0,
  }) : lastAccessedAt = cachedAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get age => DateTime.now().difference(cachedAt);
  Duration get ttl => expiresAt.difference(DateTime.now());

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value is Map || value is List ? value : value.toString(),
    'cachedAt': cachedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'priority': priority.name,
    'accessCount': accessCount,
    'lastAccessedAt': lastAccessedAt.toIso8601String(),
  };

  static CacheEntry<T>? fromJson<T>(
    Map<String, dynamic> json,
    T Function(dynamic) deserializer,
  ) {
    try {
      return CacheEntry<T>(
        key: json['key'] as String,
        value: deserializer(json['value']),
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        priority: CachePriority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => CachePriority.normal,
        ),
        accessCount: json['accessCount'] as int? ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

class CacheStats {
  int memoryHits = 0;
  int localHits = 0;
  int remoteFetches = 0;
  int misses = 0;
  int evictions = 0;

  double get hitRate {
    final total = memoryHits + localHits + remoteFetches + misses;
    return total > 0 ? (memoryHits + localHits) / total : 0;
  }

  Map<String, dynamic> toMap() => {
    'memoryHits': memoryHits,
    'localHits': localHits,
    'remoteFetches': remoteFetches,
    'misses': misses,
    'evictions': evictions,
    'hitRate': hitRate,
  };
}

class SmartCacheService with ChangeNotifier {
  static final SmartCacheService _instance = SmartCacheService._internal();
  factory SmartCacheService() => _instance;
  SmartCacheService._internal();

  static const int _maxMemoryEntries = 500;
  // ignore: unused_field
  static const int _maxLocalEntries = 2000;
  static const Duration _defaultTTL = Duration(minutes: 15);

  final Map<String, CacheEntry<dynamic>> _memoryCache = {};
  SharedPreferences? _prefs;
  final CacheStats _stats = CacheStats();
  Timer? _cleanupTimer;
  bool _initialized = false;

  CacheStats get stats => _stats;
  int get memorySize => _memoryCache.length;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('💾 SmartCacheService: Initializing...');
    _prefs = await SharedPreferences.getInstance();
    _startCleanupTimer();
    _initialized = true;
    notifyListeners();
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanup(),
    );
  }

  /// Get value from cache with automatic layer traversal
  Future<T?> get<T>(String key, {T Function(dynamic)? deserializer}) async {
    // Layer 1: Memory cache
    final memEntry = _memoryCache[key];
    if (memEntry != null && !memEntry.isExpired) {
      memEntry.accessCount++;
      memEntry.lastAccessedAt = DateTime.now();
      _stats.memoryHits++;
      return memEntry.value as T;
    }

    // Layer 2: Local storage
    if (_prefs != null) {
      final localJson = _prefs!.getString('cache_$key');
      if (localJson != null) {
        try {
          final json = jsonDecode(localJson) as Map<String, dynamic>;
          final entry = CacheEntry.fromJson<T>(
            json,
            deserializer ?? (v) => v as T,
          );
          if (entry != null && !entry.isExpired) {
            // Promote to memory
            _memoryCache[key] = entry;
            _stats.localHits++;
            return entry.value;
          }
        } catch (_) {}
      }
    }

    _stats.misses++;
    return null;
  }

  /// Set value in cache
  Future<void> set<T>(
    String key,
    T value, {
    Duration? ttl,
    CachePriority priority = CachePriority.normal,
    bool persistLocally = true,
  }) async {
    final now = DateTime.now();
    final entry = CacheEntry<T>(
      key: key,
      value: value,
      cachedAt: now,
      expiresAt: now.add(ttl ?? _defaultTTL),
      priority: priority,
    );

    // Store in memory
    _memoryCache[key] = entry;
    _enforceMemoryLimit();

    // Persist locally if requested
    if (persistLocally && _prefs != null) {
      await _prefs!.setString('cache_$key', jsonEncode(entry.toJson()));
    }

    notifyListeners();
  }

  /// Get or fetch with automatic caching
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
    CachePriority priority = CachePriority.normal,
    T Function(dynamic)? deserializer,
  }) async {
    // Try cache first
    final cached = await get<T>(key, deserializer: deserializer);
    if (cached != null) return cached;

    // Fetch and cache
    final value = await fetcher();
    await set(key, value, ttl: ttl, priority: priority);
    _stats.remoteFetches++;
    return value;
  }

  /// Invalidate cache entry
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    await _prefs?.remove('cache_$key');
  }

  /// Invalidate by pattern
  Future<void> invalidatePattern(String pattern) async {
    final regex = RegExp(pattern);
    final keysToRemove = _memoryCache.keys
        .where(regex.hasMatch)
        .toList();
    for (final key in keysToRemove) {
      await invalidate(key);
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    final keys = _prefs?.getKeys().where((k) => k.startsWith('cache_')) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
    notifyListeners();
  }

  void _enforceMemoryLimit() {
    if (_memoryCache.length <= _maxMemoryEntries) return;

    // LRU eviction - remove least recently accessed
    final entries = _memoryCache.entries.toList()
      ..sort(
        (a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt),
      );

    final toRemove = entries.take(_memoryCache.length - _maxMemoryEntries + 50);
    for (final entry in toRemove) {
      // Keep critical priority entries
      if (entry.value.priority != CachePriority.critical) {
        _memoryCache.remove(entry.key);
        _stats.evictions++;
      }
    }
  }

  void _cleanup() {
    // Remove expired entries from memory
    _memoryCache.removeWhere((_, entry) => entry.isExpired);
    notifyListeners();
  }

  /// Preload hot data into cache
  Future<void> preloadHotData() async {
    debugPrint('SmartCacheService: Preloading hot data...');

    // Preload featured events
    try {
      final eventsSnap = await _firestore
          .collection('events')
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();
      for (final doc in eventsSnap.docs) {
        await set(
          'event_${doc.id}',
          doc.data(),
          ttl: const Duration(hours: 1),
          priority: CachePriority.high,
        );
      }
    } catch (_) {}

    // Preload top fighters
    try {
      final fightersSnap = await _firestore
          .collection('fighters')
          .orderBy('ranking')
          .limit(20)
          .get();
      for (final doc in fightersSnap.docs) {
        await set(
          'fighter_${doc.id}',
          doc.data(),
          ttl: const Duration(hours: 2),
          priority: CachePriority.high,
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }
}
