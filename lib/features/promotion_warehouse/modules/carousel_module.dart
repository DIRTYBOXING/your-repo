import '../promotion_warehouse_orchestrator.dart';

/// CarouselModule: The workhorse for featured content rotation.
class CarouselModule implements PromotionModule {
  @override
  List<PromotionContent> generateContent() {
    // Carousel: rotating featured content for visibility
    return [
      PromotionContent(
        title: 'Carousel Feature',
        body: 'Rotating featured content for maximum visibility.',
        tags: ['carousel', 'featured', 'workhorse'],
      ),
    ];
  }
}
