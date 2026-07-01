import 'package:datafightcentral/shared/models/ppv_model.dart';
import 'package:datafightcentral/shared/models/ppv_presentation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PPVEvent buildEvent({
    String? posterUrl,
    bool isFinalPoster = false,
    String? posterAssetKind,
    List<PPVFight> fightCard = const [],
    String? subtitle,
  }) {
    return PPVEvent(
      id: 'ppv-test',
      eventId: 'event-test',
      promoterId: 'promoter-test',
      title: 'TEST EVENT',
      subtitle: subtitle,
      posterUrl: posterUrl,
      isFinalPoster: isFinalPoster,
      posterAssetKind: posterAssetKind,
      eventDate: DateTime(2026, 4, 12, 20),
      standardPriceCents: 4999,
      fightCard: fightCard,
    );
  }

  group('PPVEvent.fightersNormalized', () {
    test('normalizes fighters from fight card first', () {
      final event = buildEvent(
        fightCard: const [
          PPVFight(
            fightId: 'f1',
            fighter1Name: 'Alice',
            fighter2Name: 'Bob',
            weightClass: 'Lightweight',
            isMainEvent: true,
          ),
          PPVFight(
            fightId: 'f2',
            fighter1Name: 'Alice',
            fighter2Name: 'Cara',
            weightClass: 'Featherweight',
          ),
        ],
      );

      expect(event.fightersNormalized, ['Alice', 'Bob', 'Cara']);
    });

    test('falls back to subtitle parsing when fight card is empty', () {
      final event = buildEvent(subtitle: 'Alice vs Bob — Title Fight');

      expect(event.fightersNormalized, contains('Alice'));
      expect(event.fightersNormalized, contains('Bob'));
    });
  });

  group('PPVPresentationModel.fromEvent', () {
    test('uses fullArtwork for explicit final poster', () {
      final model = PPVPresentationModel.fromEvent(
        buildEvent(
          posterUrl: 'https://cdn.example.com/final-poster.jpg',
          isFinalPoster: true,
        ),
      );

      expect(model.posterKind, PosterAssetKind.finalPoster);
      expect(model.posterMode, PosterRenderMode.fullArtwork);
      expect(model.allowOverlayText, isFalse);
      expect(model.metadataInsideImage, isTrue);
    });

    test('uses generatedCard for generated fallback assets', () {
      final model = PPVPresentationModel.fromEvent(
        buildEvent(
          posterUrl: 'assets/ppv/ppv-ibc-03.png',
          posterAssetKind: 'generatedFallback',
        ),
      );

      expect(model.posterKind, PosterAssetKind.generatedFallback);
      expect(model.posterMode, PosterRenderMode.generatedCard);
      expect(model.allowOverlayText, isTrue);
      expect(model.metadataInsideImage, isFalse);
    });

    test('uses embeddedArtwork for tagged background art', () {
      final model = PPVPresentationModel.fromEvent(
        buildEvent(
          posterUrl: 'https://cdn.example.com/background.jpg',
          posterAssetKind: 'backgroundArt',
        ),
      );

      expect(model.posterKind, PosterAssetKind.backgroundArt);
      expect(model.posterMode, PosterRenderMode.embeddedArtwork);
      expect(model.allowOverlayText, isTrue);
      expect(model.metadataInsideImage, isFalse);
    });
  });
}
