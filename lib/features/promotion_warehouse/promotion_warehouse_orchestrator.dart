// import 'package:flutter/material.dart'; // Removed unused import

// The master orchestrator for all promotion modules.
// Coordinates factory, carousel, swarm, beast, orange, and more.
import 'modules/carousel_module.dart';
import 'modules/swarm_module.dart';
import 'modules/factory_module.dart';
import 'modules/orange_pi_module.dart';
import 'modules/beast_module.dart';
import 'seo/seo_manager.dart';

class PromotionWarehouseOrchestrator {
  // Registry of all creative engines
  final Map<String, PromotionModule> _modules = {};
  final SEOManager _seoManager = SEOManager();

  PromotionWarehouseOrchestrator() {
    // Register all core modules
    registerModule('carousel', CarouselModule());
    registerModule('swarm', SwarmModule());
    registerModule('factory', FactoryModule());
    registerModule('orange_pi', OrangePiModule());
    registerModule('beast', BeastModule());
  }

  /// Register a module
  void registerModule(String name, PromotionModule module) {
    _modules[name] = module;
  }

  /// Run all modules and aggregate their output
  List<PromotionContent> runAll() {
    final List<PromotionContent> output = [];
    for (final module in _modules.values) {
      output.addAll(module.generateContent());
    }
    return output;
  }

  /// Generate meta tags for all promotion content
  List<Map<String, String>> generateAllMetaTags({
    String owner = 'DIRTYBOXING',
  }) {
    final List<Map<String, String>> metaTagsList = [];
    for (final content in runAll()) {
      metaTagsList.add(
        _seoManager.generateMetaTags(
          content.title,
          content.body,
          content.tags,
          owner: owner,
        ),
      );
    }
    return metaTagsList;
  }

  /// Generate hashes for all promotion content
  List<String> generateAllContentHashes() {
    final List<String> hashes = [];
    for (final content in runAll()) {
      hashes.add(_seoManager.generateContentHash(content.body));
    }
    return hashes;
  }

  /// Maximize SEO for all promotion content
  void maximizeSEO({String owner = 'DIRTYBOXING'}) {
    final metaTagsList = generateAllMetaTags(owner: owner);
    _seoManager.maximizeSEO(metaTagsList);
  }

  /// Find and destroy competitors (Orange Pi logic)
  void seekAndDestroyCompetitors() {
    final orangePi = _modules['orange_pi'];
    if (orangePi != null) {
      orangePi.generateContent();
    }
  }
}

/// Interface for creative modules
abstract class PromotionModule {
  List<PromotionContent> generateContent();
}

/// Example content model
class PromotionContent {
  final String title;
  final String body;
  final List<String> tags;
  PromotionContent({
    required this.title,
    required this.body,
    required this.tags,
  });
}
