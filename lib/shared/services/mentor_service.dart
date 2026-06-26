import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for a mentor profile
class MentorProfile {
  final String name;
  final String role;
  final String specialty;
  final String photoUrl;
  final String bio;
  final List<String> tags;

  const MentorProfile({
    required this.name,
    required this.role,
    required this.specialty,
    required this.photoUrl,
    required this.bio,
    required this.tags,
  });
}

/// MentorService — handles Firestore CRUD for mentors
class MentorService {
  final _mentorsRef = FirebaseFirestore.instance.collection('mentors');

  Future<List<MentorProfile>> fetchMentors() async {
    final snapshot = await _mentorsRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return MentorProfile(
        name: data['name'] ?? '',
        role: data['role'] ?? '',
        specialty: data['specialty'] ?? '',
        photoUrl: data['photoUrl'] ?? '',
        bio: data['bio'] ?? '',
        tags: List<String>.from(data['tags'] ?? []),
      );
    }).toList();
  }

  Future<void> addMentor(MentorProfile mentor) async {
    await _mentorsRef.add({
      'name': mentor.name,
      'role': mentor.role,
      'specialty': mentor.specialty,
      'photoUrl': mentor.photoUrl,
      'bio': mentor.bio,
      'tags': mentor.tags,
    });
  }

  Future<List<MentorProfile>> getMentors() async {
    return fetchMentors();
  }
}
