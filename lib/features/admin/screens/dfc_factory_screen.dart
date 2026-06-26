import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed unused import
import '../../../shared/services/events_service.dart';
import '../../../shared/models/event_model.dart';
// ...existing code...

/// DFC Factory: Super Admin Interface for Power Users
/// Batch uploads, global feed control, cross-country distribution, analytics
class DfcFactoryScreen extends StatefulWidget {
  const DfcFactoryScreen({super.key});

  @override
  State<DfcFactoryScreen> createState() => _DfcFactoryScreenState();
}

class _DfcFactoryScreenState extends State<DfcFactoryScreen> {
  bool _showHelp = false;
  String? _csvFileName;
  bool _isUploading = false;
  String? _uploadStatus;
  List<String> _selectedImages = [];
  // Feed routing state
  String? _selectedRegion;
  String? _selectedPlatform;
  final List<String> _regions = [
    'Global',
    'AU',
    'NZ',
    'US',
    'UK',
    'Asia',
    'Europe',
    'Africa',
    'South America',
  ];
  final List<String> _platforms = [
    'DFC Web',
    'DFC App',
    'YouTube',
    'Instagram',
    'Facebook',
    'TikTok',
    'Twitter',
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  Future<void> _handleBatchUpload() async {
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading...';
    });
    try {
      // CSV parsing placeholder — creates sample events for demo
      final events = [
        EventModel(
          id: '',
          promoterId: 'dfc',
          name: 'Sample Event',
          venue: 'DFC Arena',
          city: 'Sydney',
          country: 'AU',
          eventDate: DateTime.now().add(const Duration(days: 7)),
          fightIds: [],
        ),
      ];
      await EventsService().uploadEventsBatch(events);
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Batch upload complete!';
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Upload failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DFC Factory – Super Admin'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(
              _showHelp ? Icons.help : Icons.help_outline,
              color: Colors.amber,
            ),
            tooltip: 'Show onboarding help',
            onPressed: () {
              setState(() {
                _showHelp = !_showHelp;
              });
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to the DFC Factory!\n\nThis is your private control room for global feeds, batch uploads, and advanced analytics. Only trusted admins can access this area.',
                    style: TextStyle(color: Colors.amber, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _csvFileName != null
                          ? Text(
                              'Selected: $_csvFileName',
                              style: const TextStyle(color: Colors.greenAccent),
                            )
                          : const Text(
                              'No file selected',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                        onPressed: () {
                          // Image picker placeholder
                          setState(() {
                            _selectedImages = [
                              'event1.jpg',
                              'event2.jpg',
                            ]; // Placeholder
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      _selectedImages.isNotEmpty
                          ? Text(
                              'Images: ${_selectedImages.join(', ')}',
                              style: const TextStyle(color: Colors.greenAccent),
                            )
                          : const Text(
                              'No images added',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send, color: Colors.black),
                    label: const Text(
                      'Upload Batch',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    onPressed: _csvFileName == null || _isUploading
                        ? null
                        : _handleBatchUpload,
                  ),
                  if (_uploadStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _uploadStatus!,
                        style: const TextStyle(color: Colors.amber),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Metadata input fields
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metadata fields
                        const Text(
                          'Content Metadata',
                          style: TextStyle(color: Colors.amber, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags (comma separated)',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Global Feed Routing
                        const Row(
                          children: [
                            Icon(Icons.public, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              'Global Feed Routing',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 16,
                              ),
                            ),
                            Tooltip(
                              message:
                                  'Step 4: Select region and platform to distribute events globally.',
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Region:',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _selectedRegion,
                              hint: const Text(
                                'Select Region',
                                style: TextStyle(color: Colors.white70),
                              ),
                              dropdownColor: Colors.deepPurple.shade800,
                              items: _regions.map((region) {
                                return DropdownMenuItem<String>(
                                  value: region,
                                  child: Text(
                                    region,
                                    style: const TextStyle(color: Colors.amber),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRegion = value;
                                });
                              },
                            ),
                            const SizedBox(width: 24),
                            const Text(
                              'Platform:',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _selectedPlatform,
                              hint: const Text(
                                'Select Platform',
                                style: TextStyle(color: Colors.white70),
                              ),
                              dropdownColor: Colors.deepPurple.shade800,
                              items: _platforms.map((platform) {
                                return DropdownMenuItem<String>(
                                  value: platform,
                                  child: Text(
                                    platform,
                                    style: const TextStyle(color: Colors.amber),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPlatform = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Routing Summary: ${_selectedRegion ?? 'No region selected'} → ${_selectedPlatform ?? 'No platform selected'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send, color: Colors.black),
                          label: const Text(
                            'Distribute to Global Feeds',
                            style: TextStyle(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                          ),
                          onPressed:
                              _selectedRegion == null ||
                                  _selectedPlatform == null
                              ? null
                              : () async {
                                  // ...existing code...
                                  // ExternalFeedService.sendToPlatform is undefined, comment out or replace with valid logic
                                  // final result = await ExternalFeedService.sendToPlatform(
                                  //   platform: _selectedPlatform!,
                                  //   region: _selectedRegion!,
                                  //   eventData: eventData,
                                  // );
                                  // if (!mounted) return;
                                  // ScaffoldMessenger.of(context).showSnackBar(
                                  //   SnackBar(
                                  //     content: Text(result.success
                                  //         ? 'Distributed to ${_selectedRegion!} on ${_selectedPlatform!}'
                                  //         : 'Distribution failed: ${result.errorMessage}'),
                                  //     backgroundColor: result.success ? Colors.deepPurple : Colors.red,
                                  //   ),
                                  // );
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.analytics, color: Colors.black),
                    label: const Text(
                      'View Advanced Analytics',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Advanced analytics loading...'),
                          backgroundColor: Colors.amber,
                        ),
                      );
                    },
                  ),
                  // Add more super admin tools here
                ],
              ),
            ),
            if (_showHelp)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DFC Factory Onboarding',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '1. Upload your CSV file with event data.\n2. Add images for each event.\n3. Click "Upload Batch" to ingest events.\n4. Select region and platform for global feed routing.\n5. Distribute events to your chosen feeds.\n6. View analytics for performance tracking.',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.close, color: Colors.black),
                          label: const Text(
                            'Close Help',
                            style: TextStyle(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              _showHelp = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // External Feed Result
  // Move ExternalFeedResult and ExternalFeedService to top-level if needed
}
