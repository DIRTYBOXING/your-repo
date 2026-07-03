import '../models/ppv_event_model.dart';

class PpvService {
  Future<PpvEventModel> fetchEvent(String id) async {
    // Simulated network delay
    await Future.delayed(const Duration(milliseconds: 600));

    return PpvEventModel(
      id: id,
      title: "DFC 2: REDEMPTION",
      date: "SAT, OCT 14",
      location: "MELBOURNE ARENA",
      posterUrl:
          "https://images.unsplash.com/photo-1599552375245-298069501538?auto=format&fit=crop&q=80&w=800",
      price: 59.99,
      fights: [
        PpvFightModel(
          id: "f1",
          redCorner: "Heath Ewart",
          blueCorner: "Kai Johnson",
          weightClass: "Lightweight Title Bout",
          isMainEvent: true,
        ),
        PpvFightModel(
          id: "f2",
          redCorner: "Mason Lee",
          blueCorner: "Alex Torres",
          weightClass: "Middleweight Bout",
        ),
        PpvFightModel(
          id: "f3",
          redCorner: "Marcus Vance",
          blueCorner: "Liam Davis",
          weightClass: "Welterweight Bout",
        ),
      ],
    );
  }
}
