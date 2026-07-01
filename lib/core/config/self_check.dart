import 'dart:io';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC LOCAL PROJECT SCANNER
/// Verifies the structural integrity of the Flutter project before deployment.
/// Run via: dart run tools/self_check.dart
/// ═══════════════════════════════════════════════════════════════════════════
void main() {
  print('🚀 Initiating DFC Local Integrity Scan...\n');

  bool hasErrors = false;

  // 1. Check Required Folders
  final requiredFolders = [
    'lib/core',
    'lib/shared/models',
    'lib/shared/services',
    'lib/shared/widgets',
    'lib/features/promoter',
    'lib/features/ppv',
    'lib/features/feed',
    'lib/features/profile',
    'lib/features/gym',
    'lib/features/admin',
    'lib/features/finance',
    'assets/images',
  ];

  print('📁 Checking Core Directories...');
  for (final folder in requiredFolders) {
    if (!Directory(folder).existsSync()) {
      print('   ❌ MISSING FOLDER: $folder');
      hasErrors = true;
    } else {
      print('   ✅ $folder');
    }
  }

  print('\n📄 Checking Critical Files...');
  // 2. Check Critical Services
  final criticalFiles = [
    'lib/shared/services/auth_service.dart',
    'lib/shared/services/governance_service.dart',
    'lib/core/config/router_config.dart',
    'functions/src/index.ts',
  ];

  for (final file in criticalFiles) {
    if (!File(file).existsSync()) {
      print('   ❌ MISSING CRITICAL FILE: $file');
      hasErrors = true;
    } else {
      print('   ✅ $file');
    }
  }

  if (hasErrors) {
    print('\n🛑 SCAN FAILED. Fix missing structure before deploying.');
  } else {
    print('\n🟢 SCAN PASSED. Project structure is sound.');
  }
}
