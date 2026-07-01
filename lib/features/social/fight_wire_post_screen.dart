import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../shared/services/social_service.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/fighter_service.dart';
import '../../shared/services/campaign_service.dart';
import '../../shared/models/fighter_model.dart';
import '../../shared/models/gym_model.dart';
import '../../shared/models/marketing_campaign_model.dart';
import '../../shared/widgets/dfc_network_image.dart';

// Fight Wire: Create and publish fight news, event posts, and viral content
class FightWirePostScreen extends StatefulWidget {
  const FightWirePostScreen({super.key});

  @override
  State<FightWirePostScreen> createState() => _FightWirePostScreenState();
}

class _FightWirePostScreenState extends State<FightWirePostScreen> {
  String? _postTitle;
  String? _postContent;
  List<String> _images = [];
  bool _isPosting = false;
  String? _postStatus;
  final AuthService _authService = AuthService();
  final List<FighterModel> _selectedFighters = [];
  final List<GymModel> _selectedGyms = [];
  final List<MarketingCampaignModel> _selectedCampaigns = [];
  List<FighterModel> _fighterOptions = [];
  List<GymModel> _gymOptions = [];
  List<MarketingCampaignModel> _campaignOptions = [];
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    // Fighters
    final fighters = await FighterService().findAvailableFighters(limit: 50);
    // Gyms (direct Firestore query)
    final gymSnap = await FirebaseFirestore.instance
        .collection('gyms')
        .limit(50)
        .get();
    final gyms = gymSnap.docs
        .map(GymModel.fromFirestore)
        .toList();
    // Campaigns
    final campaigns = await CampaignService().getCampaigns();
    setState(() {
      _fighterOptions = fighters;
      _gymOptions = gyms;
      _campaignOptions = campaigns;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _authService.isAuthenticated;
    final user = _authService.userModel;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fight Wire – New Post'),
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a fight news post, event update, or viral content. Add images and publish to all feeds.',
                style: TextStyle(color: Colors.amber, fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (!isAuthenticated)
                Column(
                  children: [
                    const Text(
                      'Sign in to post',
                      style: TextStyle(color: Colors.redAccent, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Redirecting to sign in...'),
                            backgroundColor: Colors.deepPurple,
                          ),
                        );
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                )
              else ...[
                Row(
                  children: [
                    if (user?.photoUrl != null)
                      DfcCircleAvatar(
                        imageUrl: user!.photoUrl,
                      ),
                    const SizedBox(width: 12),
                    Text(
                      user?.displayName ?? 'Unknown',
                      style: const TextStyle(color: Colors.amber, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      user?.role.name ?? 'fan',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Tagging Fighters
                const Text(
                  'Tag Fighters:',
                  style: TextStyle(color: Colors.amber),
                ),
                Wrap(
                  spacing: 8,
                  children: _selectedFighters
                      .map(
                        (f) => Chip(
                          label: Text(f.fullName),
                          onDeleted: () =>
                              setState(() => _selectedFighters.remove(f)),
                        ),
                      )
                      .toList(),
                ),
                Autocomplete<FighterModel>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return [];
                    return _fighterOptions.where(
                      (f) => f.fullName.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  displayStringForOption: (f) => f.fullName,
                  onSelected: (f) {
                    if (!_selectedFighters.contains(f)) {
                      setState(() => _selectedFighters.add(f));
                    }
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Search Fighters',
                            labelStyle: TextStyle(color: Colors.amber),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.deepPurple,
                          ),
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                ),
                const SizedBox(height: 16),
                // Tagging Gyms
                const Text('Tag Gyms:', style: TextStyle(color: Colors.amber)),
                Wrap(
                  spacing: 8,
                  children: _selectedGyms
                      .map(
                        (g) => Chip(
                          label: Text(g.name),
                          onDeleted: () =>
                              setState(() => _selectedGyms.remove(g)),
                        ),
                      )
                      .toList(),
                ),
                Autocomplete<GymModel>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return [];
                    return _gymOptions.where(
                      (g) => g.name.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  displayStringForOption: (g) => g.name,
                  onSelected: (g) {
                    if (!_selectedGyms.contains(g)) {
                      setState(() => _selectedGyms.add(g));
                    }
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Search Gyms',
                            labelStyle: TextStyle(color: Colors.amber),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.deepPurple,
                          ),
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                ),
                const SizedBox(height: 16),
                // Tagging Campaigns
                const Text(
                  'Tag Campaigns:',
                  style: TextStyle(color: Colors.amber),
                ),
                Wrap(
                  spacing: 8,
                  children: _selectedCampaigns
                      .map(
                        (c) => Chip(
                          label: Text(c.title),
                          onDeleted: () =>
                              setState(() => _selectedCampaigns.remove(c)),
                        ),
                      )
                      .toList(),
                ),
                Autocomplete<MarketingCampaignModel>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return [];
                    return _campaignOptions.where(
                      (c) => c.title.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  displayStringForOption: (c) => c.title,
                  onSelected: (c) {
                    if (!_selectedCampaigns.contains(c)) {
                      setState(() => _selectedCampaigns.add(c));
                    }
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Search Campaigns',
                            labelStyle: TextStyle(color: Colors.amber),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.deepPurple,
                          ),
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Post Title',
                    labelStyle: TextStyle(color: Colors.amber),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.deepPurple,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() => _postTitle = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Post Content',
                    labelStyle: TextStyle(color: Colors.amber),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.deepPurple,
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 6,
                  onChanged: (value) => setState(() => _postContent = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image, color: Colors.black),
                      label: const Text(
                        'Add Images',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                      onPressed: () async {
                        final pickedFiles = await _picker.pickMultiImage(
                          imageQuality: 85,
                          maxWidth: 1200,
                          maxHeight: 1200,
                        );
                        if (pickedFiles.isEmpty) return;
                        final List<String> uploadedUrls = [];
                        for (final file in pickedFiles) {
                          final bytes = await file.readAsBytes();
                          final ext = file.name.split('.').last;
                          final fileName =
                              'fightwire_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
                          final ref = FirebaseStorage.instance
                              .ref()
                              .child('fightwire_posts')
                              .child(fileName);
                          final metadata = SettableMetadata(
                            contentType: 'image/$ext',
                          );
                          await ref.putData(bytes, metadata);
                          final url = await ref.getDownloadURL();
                          uploadedUrls.add(url);
                        }
                        setState(() {
                          _images = uploadedUrls;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    _images.isNotEmpty
                        ? Text(
                            'Images: ${_images.length}',
                            style: const TextStyle(color: Colors.greenAccent),
                          )
                        : const Text(
                            'No images added',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send, color: Colors.black),
                  label: const Text(
                    'Publish Post',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed:
                      _postTitle == null || _postContent == null || _isPosting
                      ? null
                      : () async {
                          setState(() {
                            _isPosting = true;
                            _postStatus = 'Posting...';
                          });
                          try {
                            await SocialService().createPost(
                              authorId: user?.id ?? 'unknown',
                              content: _postContent!,
                              displayName: _postTitle,
                              role: user?.role.name ?? 'fan',
                              mediaUrls: _images,
                              taggedFighterIds: _selectedFighters
                                  .map((f) => f.id)
                                  .toList(),
                              // Gym/campaign tagging pending SocialService extension
                            );
                            setState(() {
                              _isPosting = false;
                              _postStatus = 'Post published!';
                            });
                          } catch (e) {
                            setState(() {
                              _isPosting = false;
                              _postStatus = 'Post failed: ${e.toString()}';
                            });
                          }
                        },
                ),
                if (_postStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _postStatus!,
                      style: const TextStyle(color: Colors.amber),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
