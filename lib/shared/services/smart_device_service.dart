import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SMART DEVICE SERVICE - Wearable & Health Device Integration
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Connects to:
/// - Apple Watch / HealthKit
/// - Garmin Connect
/// - Google Fit
/// - Whoop
// Removed erroneous variable declarations and misplaced code.

/// Connection status for smart devices
enum DeviceConnectionStatus { connected, disconnected, connecting, error }

/// Supported device types (2026 edition)
enum SmartDeviceType {
  // Premium smartwatches
  appleWatch,
  samsungGalaxy,
  garmin,
  suunto,
  coros,
  huawei,
  amazfit,

  // Wearable trackers & rings
  whoop,
  ouraRing,
  fitbit,
  xiaomiBand,

  // Health focused
  polar,
  withings,

  // Advanced biomarkers
  pfSweatPatch,
  drTwinAI,
  ultrahuman,
  nuralogixMirror,
  abbottLibreAssist,

  // Menstrual/fertility trackers
  ava,
  clue,
  flo,
  daysy,
  tempdrop,
  femometer,

  // Future tech
  teslaNeural,
  nvidiaBioAI,
  rolandBiofeedback,
  inshenzagonQuantum,
  nasaMoodSensor,

  // Comprehensive platforms
  googleFit,
  healthKit,

  // Smart home + recovery
  eightSleep,
  therabody,
}

/// Health metrics from devices (2026 comprehensive)
class HealthMetrics {
  // Cardiovascular
  final int heartRate;
  final int restingHR;
  final int maxHR;
  final int hrvScore;
  final int spo2;

  // Activity & energy
  final int steps;
  final double caloriesBurned;
  final double activeMinutes;

  // Sleep & recovery
  final double sleepHours;

  // Menstrual/fertility
  final String? cyclePhase; // e.g. follicular, ovulation, luteal, menstruation
  final DateTime? lastPeriodStart;
  final int? cycleLength;
  final int? periodLength;
  final double? basalBodyTemp;
  final double? hormoneEstrogen;
  final double? hormoneProgesterone;
  final double? hormoneLH;
  final double? hormoneFSH;
  final bool? ovulationDetected;
  final String? symptoms;
  final String? fertilityPrediction;
  final String? deviceSource; // e.g. Oura, Ava, Flo, TeslaNeural, etc.
  final int sleepQuality;
  final int sleepStages; // REM, light, deep

  // Performance metrics
  final double vo2Max;
  final double bodyTemperature;
  final double bloodPressureSystolic;
  final double bloodPressureDiastolic;

  // 2026 Advanced biomarkers
  final double lactateLevel; // mmol/L (from sweat patch)
  final double cortisol; // ng/mL (stress marker)
  final double glucose; // mg/dL (continuous monitoring)
  final double creatinine; // Kidney/muscle marker
  final int readinessScore; // 0-100 composite
  final double bodyComposition; // % muscle/fat
  final double hydrationLevel; // % optimal

  // Recovery & wellness
  final int trainingLoadAcute;
  final int trainingLoadChronic;
  final double acwr; // Acute:Chronic workload ratio
  final int recoveryTime; // hours until ready
  final int stressLevel; // 0-100
  final int moodScore; // 0-100

  // Genomic insights (Dr. Twin AI)
  final double diseaseRiskProfile; // composite risk 0-100

  // Room/environment (Ultrahuman Home)
  final double roomTemp;
  final int roomHumidity;
  final int airQualityPM25;
  final int noiseLevel;

  final DateTime timestamp;

  HealthMetrics({
    this.heartRate = 72,
    this.restingHR = 58,
    this.maxHR = 195,
    this.hrvScore = 65,
    this.spo2 = 98,
    this.steps = 8432,
    this.caloriesBurned = 2150,
    this.activeMinutes = 52,
    this.sleepHours = 7.5,
    this.cyclePhase = '',
    this.lastPeriodStart,
    this.cycleLength,
    this.periodLength,
    this.basalBodyTemp,
    this.hormoneEstrogen = 0.0,
    this.hormoneProgesterone = 0.0,
    this.hormoneLH = 0.0,
    this.hormoneFSH = 0.0,
    this.ovulationDetected = false,
    this.symptoms = '',
    this.fertilityPrediction = '',
    this.deviceSource = '',
    this.sleepQuality = 82,
    this.sleepStages = 90,
    this.vo2Max = 48.5,
    this.bodyTemperature = 36.6,
    this.bloodPressureSystolic = 118,
    this.bloodPressureDiastolic = 76,
    this.lactateLevel = 2.1,
    this.cortisol = 12.5,
    this.glucose = 95,
    this.creatinine = 0.9,
    this.readinessScore = 78,
    this.bodyComposition = 18.5,
    this.hydrationLevel = 92,
    this.trainingLoadAcute = 185,
    this.trainingLoadChronic = 1420,
    this.acwr = 1.3,
    this.recoveryTime = 8,
    this.stressLevel = 35,
    this.moodScore = 82,
    this.diseaseRiskProfile = 15.2,
    this.roomTemp = 21.5,
    this.roomHumidity = 45,
    this.airQualityPM25 = 12,
    this.noiseLevel = 52,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Merge this with another HealthMetrics, preferring non-default values
  HealthMetrics merge(HealthMetrics other) {
    return HealthMetrics(
      heartRate: other.heartRate != 72 ? other.heartRate : heartRate,
      restingHR: other.restingHR != 58 ? other.restingHR : restingHR,
      maxHR: other.maxHR != 195 ? other.maxHR : maxHR,
      hrvScore: other.hrvScore != 65 ? other.hrvScore : hrvScore,
      spo2: other.spo2 != 98 ? other.spo2 : spo2,
      steps: other.steps != 8432 ? other.steps : steps,
      caloriesBurned: other.caloriesBurned != 2150
          ? other.caloriesBurned
          : caloriesBurned,
      activeMinutes: other.activeMinutes != 52
          ? other.activeMinutes
          : activeMinutes,
      sleepHours: other.sleepHours != 7.5 ? other.sleepHours : sleepHours,
      sleepQuality: other.sleepQuality != 82
          ? other.sleepQuality
          : sleepQuality,
      sleepStages: other.sleepStages != 90 ? other.sleepStages : sleepStages,
      vo2Max: other.vo2Max != 48.5 ? other.vo2Max : vo2Max,
      bodyTemperature: other.bodyTemperature != 36.6
          ? other.bodyTemperature
          : bodyTemperature,
      bloodPressureSystolic: other.bloodPressureSystolic != 118
          ? other.bloodPressureSystolic
          : bloodPressureSystolic,
      bloodPressureDiastolic: other.bloodPressureDiastolic != 76
          ? other.bloodPressureDiastolic
          : bloodPressureDiastolic,
      lactateLevel: other.lactateLevel != 2.1
          ? other.lactateLevel
          : lactateLevel,
      cortisol: other.cortisol != 12.5 ? other.cortisol : cortisol,
      glucose: other.glucose != 95 ? other.glucose : glucose,
      creatinine: other.creatinine != 0.9 ? other.creatinine : creatinine,
      readinessScore: other.readinessScore != 78
          ? other.readinessScore
          : readinessScore,
      bodyComposition: other.bodyComposition != 18.5
          ? other.bodyComposition
          : bodyComposition,
      hydrationLevel: other.hydrationLevel != 92
          ? other.hydrationLevel
          : hydrationLevel,
      trainingLoadAcute: other.trainingLoadAcute != 185
          ? other.trainingLoadAcute
          : trainingLoadAcute,
      trainingLoadChronic: other.trainingLoadChronic != 1420
          ? other.trainingLoadChronic
          : trainingLoadChronic,
      acwr: other.acwr != 1.3 ? other.acwr : acwr,
      recoveryTime: other.recoveryTime != 8 ? other.recoveryTime : recoveryTime,
      stressLevel: other.stressLevel != 35 ? other.stressLevel : stressLevel,
      moodScore: other.moodScore != 82 ? other.moodScore : moodScore,
      diseaseRiskProfile: other.diseaseRiskProfile != 15.2
          ? other.diseaseRiskProfile
          : diseaseRiskProfile,
      roomTemp: other.roomTemp != 21.5 ? other.roomTemp : roomTemp,
      roomHumidity: other.roomHumidity != 45
          ? other.roomHumidity
          : roomHumidity,
      airQualityPM25: other.airQualityPM25 != 12
          ? other.airQualityPM25
          : airQualityPM25,
      noiseLevel: other.noiseLevel != 52 ? other.noiseLevel : noiseLevel,
      timestamp: other.timestamp.isAfter(timestamp)
          ? other.timestamp
          : timestamp,
    );
  }
}

/// Connected device info
class ConnectedDevice {
  final String id;
  final String name;
  final SmartDeviceType type;
  final DeviceConnectionStatus status;
  final int batteryLevel;
  final DateTime? lastSync;

  ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    this.status = DeviceConnectionStatus.disconnected,
    this.batteryLevel = 100,
    this.lastSync,
  });

  String get iconName {
    switch (type) {
      case SmartDeviceType.appleWatch:
      case SmartDeviceType.samsungGalaxy:
      case SmartDeviceType.garmin:
      case SmartDeviceType.suunto:
      case SmartDeviceType.coros:
      case SmartDeviceType.huawei:
      case SmartDeviceType.amazfit:
        return 'watch';
      case SmartDeviceType.whoop:
      case SmartDeviceType.fitbit:
        return 'track_changes';
      case SmartDeviceType.ouraRing:
        return 'radio_button_checked';
      case SmartDeviceType.xiaomiBand:
        return 'fitness_center';
      case SmartDeviceType.polar:
      case SmartDeviceType.withings:
        return 'favorite';
      case SmartDeviceType.pfSweatPatch:
        return 'skin_lesion';
      case SmartDeviceType.drTwinAI:
        return 'dna';
      case SmartDeviceType.ultrahuman:
        return 'home';
      case SmartDeviceType.nuralogixMirror:
        return 'mirror';
      case SmartDeviceType.abbottLibreAssist:
        return 'medical_information';
      case SmartDeviceType.googleFit:
      case SmartDeviceType.healthKit:
        return 'cloud_done';
      case SmartDeviceType.eightSleep:
        return 'bed';
      case SmartDeviceType.therabody:
        return 'spa';
      default:
        return 'device_unknown';
    }
  }
}

/// Smart Device Service
class SmartDeviceService extends ChangeNotifier {
  static final SmartDeviceService _instance = SmartDeviceService._internal();
  factory SmartDeviceService() => _instance;
  SmartDeviceService._internal();

  // State
  final List<ConnectedDevice> _devices = [];
  HealthMetrics? _latestMetrics;
  bool _isScanning = false;
  final bool _autoSync = true;

  // Getters
  List<ConnectedDevice> get devices => List.unmodifiable(_devices);
  HealthMetrics? get latestMetrics => _latestMetrics;
  bool get isScanning => _isScanning;
  bool get autoSync => _autoSync;
  bool get hasConnectedDevices =>
      _devices.any((d) => d.status == DeviceConnectionStatus.connected);

  /// Initialize the service
  Future<void> initialize() async {
    // Load demo connected devices (2026 premium setup)
    _devices.clear();
    _devices.addAll([
      // Flagship smartwatch
      ConnectedDevice(
        id: 'apple_watch_ultra_2',
        name: 'Apple Watch Series 11',
        type: SmartDeviceType.appleWatch,
        status: DeviceConnectionStatus.connected,
        batteryLevel: 82,
        lastSync: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      // Recovery-focused wearable
      ConnectedDevice(
        id: 'whoop_5',
        name: 'WHOOP 5.5',
        type: SmartDeviceType.whoop,
        status: DeviceConnectionStatus.connected,
        batteryLevel: 88,
        lastSync: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      // Ring tracker
      ConnectedDevice(
        id: 'oura_gen5',
        name: 'Oura Ring Gen 5',
        type: SmartDeviceType.ouraRing,
        status: DeviceConnectionStatus.connected,
        batteryLevel: 95,
        lastSync: DateTime.now(),
      ),
      // Sports-oriented watch
      ConnectedDevice(
        id: 'garmin_forerunner_970',
        name: 'Garmin Forerunner 970',
        type: SmartDeviceType.garmin,
        status: DeviceConnectionStatus.connected,
        batteryLevel: 76,
        lastSync: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      // Advanced biomarker patch
      ConnectedDevice(
        id: 'pf_sweat_patch_1',
        name: 'Point Fit Sweat Patch',
        type: SmartDeviceType.pfSweatPatch,
        status: DeviceConnectionStatus.connected,
        batteryLevel: 92,
        lastSync: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      // Home health monitor
      ConnectedDevice(
        id: 'ultrahuman_home_1',
        name: 'Ultrahuman Home',
        type: SmartDeviceType.ultrahuman,
        status: DeviceConnectionStatus.connected,
        lastSync: DateTime.now(),
      ),
    ]);

    // Load latest metrics (comprehensive 2026 data)
    _latestMetrics = HealthMetrics(
      heartRate: 68,
      restingHR: 56,
      maxHR: 188,
      hrvScore: 72,
      spo2: 99,
      steps: 9821,
      caloriesBurned: 2450,
      activeMinutes: 68,
      sleepHours: 7.8,
      sleepQuality: 87,
      sleepStages: 95,
      vo2Max: 52.3,
      bodyTemperature: 36.5,
      bloodPressureSystolic: 116,
      bloodPressureDiastolic: 74,
      lactateLevel: 1.8,
      cortisol: 10.2,
      glucose: 92,
      creatinine: 0.88,
      readinessScore: 84,
      bodyComposition: 17.2,
      hydrationLevel: 95,
      trainingLoadAcute: 195,
      trainingLoadChronic: 1380,
      acwr: 1.41,
      recoveryTime: 6,
      stressLevel: 28,
      moodScore: 88,
      diseaseRiskProfile: 12.5,
      roomTemp: 21.8,
      roomHumidity: 48,
      airQualityPM25: 8,
      noiseLevel: 48,
    );

    notifyListeners();
    debugPrint('📱 Smart Device Service initialized (2026 edition)');
  }

  /// Scan for nearby devices
  Future<List<ConnectedDevice>> scanForDevices() async {
    _isScanning = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _isScanning = false;
    notifyListeners();

    // Return mock 2026 devices that could be discovered
    return [
      ConnectedDevice(
        id: 'samsung_galaxy_7',
        name: 'Samsung Galaxy Watch 7',
        type: SmartDeviceType.samsungGalaxy,
      ),
      ConnectedDevice(
        id: 'fitbit_sense_3',
        name: 'Fitbit Sense 3',
        type: SmartDeviceType.fitbit,
      ),
      ConnectedDevice(
        id: 'xiaomi_band_10',
        name: 'Xiaomi Smart Band 10',
        type: SmartDeviceType.xiaomiBand,
      ),
      ConnectedDevice(
        id: 'nuralogix_mirror',
        name: 'NuraLogix Longevity Mirror',
        type: SmartDeviceType.nuralogixMirror,
      ),
      ConnectedDevice(
        id: 'abbott_libre_assist',
        name: 'Abbott Libre Assist AI',
        type: SmartDeviceType.abbottLibreAssist,
      ),
      ConnectedDevice(
        id: 'eight_sleep_pod',
        name: 'Eight Sleep Pod Pro',
        type: SmartDeviceType.eightSleep,
      ),
    ];
  }

  /// Connect to a device
  Future<bool> connectDevice(ConnectedDevice device) async {
    final index = _devices.indexWhere((d) => d.id == device.id);

    if (index == -1) {
      _devices.add(
        ConnectedDevice(
          id: device.id,
          name: device.name,
          type: device.type,
          status: DeviceConnectionStatus.connecting,
        ),
      );
    }

    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));

    // Update to connected
    final deviceIndex = _devices.indexWhere((d) => d.id == device.id);
    if (deviceIndex != -1) {
      _devices[deviceIndex] = ConnectedDevice(
        id: device.id,
        name: device.name,
        type: device.type,
        status: DeviceConnectionStatus.connected,
        batteryLevel: 85,
        lastSync: DateTime.now(),
      );
    }

    notifyListeners();
    debugPrint('📱 Connected to ${device.name}');
    return true;
  }

  /// Disconnect a device
  Future<void> disconnectDevice(String deviceId) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      final device = _devices[index];
      _devices[index] = ConnectedDevice(
        id: device.id,
        name: device.name,
        type: device.type,
      );
      notifyListeners();
    }
  }

  /// Sync all connected devices
  Future<void> syncAll() async {
    for (final device in _devices) {
      if (device.status == DeviceConnectionStatus.connected) {
        await _syncDevice(device);
      }
    }
  }

  Future<void> _syncDevice(ConnectedDevice device) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate device sync by updating metrics with realistic variations
    if (_latestMetrics != null) {
      final random = DateTime.now().microsecond % 20;
      _latestMetrics = HealthMetrics(
        heartRate: _latestMetrics!.heartRate + (random - 10),
        restingHR: _latestMetrics!.restingHR + (random - 10),
        maxHR: _latestMetrics!.maxHR,
        hrvScore: _latestMetrics!.hrvScore + (random - 10),
        spo2: _latestMetrics!.spo2 + (random % 2),
        steps: _latestMetrics!.steps + (random * 50).toInt(),
        caloriesBurned: _latestMetrics!.caloriesBurned + (random * 10),
        activeMinutes: _latestMetrics!.activeMinutes + (random * 2),
        sleepHours: _latestMetrics!.sleepHours,
        sleepQuality: _latestMetrics!.sleepQuality + (random - 10),
        sleepStages: _latestMetrics!.sleepStages + (random - 10),
        vo2Max: _latestMetrics!.vo2Max,
        bodyTemperature:
            _latestMetrics!.bodyTemperature + ((random - 10) * 0.01),
        bloodPressureSystolic:
            _latestMetrics!.bloodPressureSystolic + (random - 10),
        bloodPressureDiastolic:
            _latestMetrics!.bloodPressureDiastolic + (random - 10),
        lactateLevel: _latestMetrics!.lactateLevel + ((random - 10) * 0.01),
        cortisol: _latestMetrics!.cortisol + ((random - 10) * 0.1),
        glucose: _latestMetrics!.glucose + (random - 10),
        creatinine: _latestMetrics!.creatinine,
        readinessScore: (_latestMetrics!.readinessScore + (random - 10))
            .clamp(0, 100)
            .toInt(),
        bodyComposition: _latestMetrics!.bodyComposition,
        hydrationLevel: (_latestMetrics!.hydrationLevel + (random - 12)).clamp(
          0,
          100,
        ),
        trainingLoadAcute:
            _latestMetrics!.trainingLoadAcute + (random * 5).toInt(),
        trainingLoadChronic: _latestMetrics!.trainingLoadChronic,
        acwr: _latestMetrics!.acwr + ((random - 10) * 0.01),
        recoveryTime: (_latestMetrics!.recoveryTime + (random - 10))
            .clamp(0, 24)
            .toInt(),
        stressLevel: (_latestMetrics!.stressLevel + (random - 10))
            .clamp(0, 100)
            .toInt(),
        moodScore: (_latestMetrics!.moodScore + (random - 10))
            .clamp(0, 100)
            .toInt(),
        diseaseRiskProfile: _latestMetrics!.diseaseRiskProfile,
        roomTemp: _latestMetrics!.roomTemp + ((random - 10) * 0.05),
        roomHumidity: (_latestMetrics!.roomHumidity + (random - 10))
            .clamp(0, 100)
            .toInt(),
        airQualityPM25: (_latestMetrics!.airQualityPM25 + (random - 10))
            .clamp(0, 500)
            .toInt(),
        noiseLevel: (_latestMetrics!.noiseLevel + (random - 10))
            .clamp(0, 100)
            .toInt(),
      );
      notifyListeners();
    }

    debugPrint('📱 Synced ${device.name} — latest metrics updated');
  }

  /// Get heart rate history (mock with realistic variations)
  List<int> getHeartRateHistory({int hours = 24}) {
    final List<int> history = [];
    final baseHR = (_latestMetrics?.restingHR ?? 58) + 10;

    for (int i = 0; i < hours * 4; i++) {
      // 15-min intervals
      final variation = (i % 40) - 20; // ±20 variation
      final timeOfDay = (i % (24 * 4)) / (24 * 4); // 0 to 1

      // Circadian rhythm: lower at night, higher during day
      final circadianEffect = (timeOfDay < 0.3 || timeOfDay > 0.9)
          ? -15
          : (timeOfDay > 0.4 && timeOfDay < 0.8)
          ? 15
          : 0;

      history.add(
        (baseHR + variation + circadianEffect).clamp(50, 180).toInt(),
      );
    }
    return history;
  }

  /// Record biometric data from manual entry or new device
  void recordBiometrics(HealthMetrics metrics) {
    _latestMetrics = metrics;
    notifyListeners();
    debugPrint('📱 Biometrics recorded at ${metrics.timestamp}');
  }

  /// Get device by ID
  ConnectedDevice? getDevice(String deviceId) {
    try {
      return _devices.firstWhere((d) => d.id == deviceId);
    } catch (e) {
      return null;
    }
  }
}
