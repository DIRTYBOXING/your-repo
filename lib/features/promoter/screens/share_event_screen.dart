import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/services/share_service.dart';

class ShareEventScreen extends StatefulWidget {
  const ShareEventScreen({super.key});

  @override
  State<ShareEventScreen> createState() => _ShareEventScreenState();
}

class _ShareEventScreenState extends State<ShareEventScreen> {
  // Poster/image/video upload
  XFile? _mediaFile;
  bool _isUploading = false;
  bool _isVideo = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Upload Image'),
              onTap: () async {
                final img = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (!context.mounted) return;
                Navigator.pop(ctx, img);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Upload Video'),
              onTap: () async {
                final vid = await picker.pickVideo(source: ImageSource.gallery);
                if (!context.mounted) return;
                Navigator.pop(ctx, vid);
              },
            ),
          ],
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _mediaFile = picked;
      _isVideo = picked.mimeType?.startsWith('video') ?? false;
    });
  }

  Future<void> _publishEvent() async {
    setState(() => _isUploading = true);
    String? mediaUrl;
    if (_mediaFile != null) {
      try {
        final ext = _isVideo ? 'event_videos' : 'event_posters';
        final storageRef = FirebaseStorage.instance.ref().child(
          '$ext/${DateTime.now().millisecondsSinceEpoch}_${_mediaFile!.name}',
        );
        await storageRef.putData(await _mediaFile!.readAsBytes());
        mediaUrl = await storageRef.getDownloadURL();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    // Save event/post to Firestore
    final eventService = EventService();
    final event = EventModel(
      id: '', // Firestore will auto-generate
      promoterId: FirebaseAuth.instance.currentUser?.uid ?? '',
      name: _titleController.text.trim(),
      description: _descController.text.trim(),
      venue: _locationController.text.trim(),
      city: '',
      state: '',
      country: '',
      eventDate:
          DateTime.tryParse(_dateController.text.trim()) ?? DateTime.now(),
      posterUrl: mediaUrl,
      isFeatured: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final eventId = await eventService.createEventDoc(event);
    if (!mounted) return;
    setState(() => _isUploading = false);
    if (eventId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event published!'),
          backgroundColor: Colors.green,
        ),
      );
      // Optionally share
      await ShareService.instance.shareFightCard(
        cardId: eventId,
        eventName: event.name,
        dateStr: _dateController.text.trim(),
        venue: _locationController.text.trim(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to publish event.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Event/Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                height: 180,
                color: Colors.grey[300],
                child: Center(
                  child: _mediaFile == null
                      ? const Text('Tap to upload Poster (Image/Video)')
                      : _isVideo
                      ? const Text('Video selected')
                      : Text('Image selected: ${_mediaFile!.name}'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Event Title'),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hashtagsController,
              decoration: const InputDecoration(
                labelText: 'Hashtags (comma separated)',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isUploading ? null : _publishEvent,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text('Publish/Share'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.facebook, color: Colors.blue),
                  tooltip: 'Share to Facebook',
                  onPressed: () async {
                    // ShareService: Facebook
                    await ShareService.instance.sharePost(
                      postId: 'event',
                      authorDisplayName: _titleController.text.trim(),
                      contentPreview: _descController.text.trim(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.lightBlue),
                  tooltip: 'Share to Twitter',
                  onPressed: () async {
                    await ShareService.instance.sharePost(
                      postId: 'event',
                      authorDisplayName: _titleController.text.trim(),
                      contentPreview: _descController.text.trim(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  tooltip: 'Share to WhatsApp',
                  onPressed: () async {
                    await ShareService.instance.sharePost(
                      postId: 'event',
                      authorDisplayName: _titleController.text.trim(),
                      contentPreview: _descController.text.trim(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.link, color: Colors.grey),
                  tooltip: 'Copy Link',
                  onPressed: () {
                    final url = '${AppConstants.publicWebBaseUrl}/event';
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
