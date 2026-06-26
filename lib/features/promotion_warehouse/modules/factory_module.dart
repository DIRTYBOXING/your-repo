import '../promotion_warehouse_orchestrator.dart';

/// FactoryModule: Automates batch uploads and campaign launches.
class FactoryModule implements PromotionModule {
  @override
  List<PromotionContent> generateContent() {
    // Factory: batch uploads and campaign automation
    return [
      PromotionContent(
        title: 'Factory Automation',
        body: 'Batch uploads and campaign launches automated.',
        tags: ['factory', 'automation', 'batch'],
      ),
    ];
  }
}
