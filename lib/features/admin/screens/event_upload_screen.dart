import 'package:datafightcentral/shared/services/auto_feed_orchestrator_service.dart'
    show AutoFeedOrchestratorService;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EventUploadScreen extends StatefulWidget {
  const EventUploadScreen({super.key});

  @override
  State<EventUploadScreen> createState() => _EventUploadScreenState();
}

class _EventUploadScreenState extends State<EventUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _imagePath = '';
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  DateTime _eventDate = DateTime.now();
  // Removed unused _source field
  String _selectedCampaign = 'Custom';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Event to Pipeline'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructional message
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fill in the event details below. Hover over the ? icons for help. Upload an image to make your event stand out!',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedCampaign,
                decoration: const InputDecoration(
                  labelText: 'Campaign',
                  labelStyle: TextStyle(color: Colors.amber),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                items:
                    [
                          'Custom',
                          'Gold Coin',
                          'Ultimate Legends',
                          'Mental Health',
                          'Coffee Campaign',
                        ]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCampaign = val ?? 'Custom';
                    // Pre-fill fields based on campaign
                    if (_selectedCampaign == 'Gold Coin') {
                      _title = 'Every Coin Counts';
                      _description =
                          '950,000 kids need our help. Start with one coin. Supporting neglected children and opportunity.';
                      _imagePath = 'assets/campaigns/gold_coin_hero.svg';
                      // Removed _source assignment
                    } else if (_selectedCampaign == 'Ultimate Legends') {
                      _title = 'Ultimate Legends Fight Night';
                      _description =
                          'The greatest legends return to the ring. Don\'t miss the action.';
                      _imagePath = 'assets/ultimate_legends_poster1.png';
                      // Removed _source assignment
                    } else if (_selectedCampaign == 'Mental Health') {
                      _title = 'Men\'s Mental Health Awareness';
                      _description =
                          'Support mental health for all. Join the movement.';
                      _imagePath = 'assets/campaigns/pink_shield_hero.svg';
                      // Removed _source assignment
                    } else if (_selectedCampaign == 'Coffee Campaign') {
                      _title = 'Coffee Campaign: Fresh Starts';
                      _description =
                          'LIFE, HOPE, FRESH STARTS. Every cup supports a new beginning.';
                      _imagePath = 'assets/campaigns/coffee_campaign_hero.svg';
                      // Removed _source assignment
                    } else {
                      _title = '';
                      _description = '';
                      _imagePath = '';
                      // Removed _source assignment
                    }
                  });
                },
                // Tooltip for campaign
                icon: const Tooltip(
                  message:
                      'Choose a campaign type. This will pre-fill some fields for you.',
                  child: Icon(Icons.help_outline, color: Colors.amber),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  labelStyle: TextStyle(color: Colors.amber),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter event title' : null,
                onSaved: (v) => _title = v ?? '',
                onChanged: (v) => _title = v,
                // Tooltip for event title
                autovalidateMode: AutovalidateMode.onUserInteraction,
                buildCounter:
                    (
                      BuildContext context, {
                      required int currentLength,
                      required bool isFocused,
                      required int? maxLength,
                    }) {
                      return const Tooltip(
                        message: 'Enter a short, clear title for your event.',
                        child: Icon(
                          Icons.help_outline,
                          color: Colors.amber,
                          size: 18,
                        ),
                      );
                    },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.amber),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter description' : null,
                onSaved: (v) => _description = v ?? '',
                onChanged: (v) => _description = v,
                // Tooltip for description
                autovalidateMode: AutovalidateMode.onUserInteraction,
                buildCounter:
                    (
                      BuildContext context, {
                      required int currentLength,
                      required bool isFocused,
                      required int? maxLength,
                    }) {
                      return const Tooltip(
                        message:
                            'Describe your event. What, when, where, and why.',
                        child: Icon(
                          Icons.help_outline,
                          color: Colors.amber,
                          size: 18,
                        ),
                      );
                    },
              ),
              const SizedBox(height: 16),
              // Image picker and preview (not inside TextFormField)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: const Row(
                  children: [
                    Text(
                      'Event Image',
                      style: TextStyle(color: Colors.amber, fontSize: 16),
                    ),
                    SizedBox(width: 6),
                    Tooltip(
                      message:
                          'Upload a photo or poster for your event. This will be shown in the event feed.',
                      child: Icon(
                        Icons.help_outline,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image, color: Colors.black),
                    label: const Text(
                      'Select Image',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    onPressed: () async {
                      final picked = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedImageFile = File(picked.path);
                          _imagePath = picked.path;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _selectedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImageFile!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _imagePath.isNotEmpty
                      ? const Text(
                          'Image selected',
                          style: TextStyle(color: Colors.greenAccent),
                        )
                      : const Text(
                          'No image',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Event Date:',
                    style: TextStyle(color: Colors.amber),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_eventDate.year}-${_eventDate.month}-${_eventDate.day}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.amber),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _eventDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) =>
                            Theme(data: ThemeData.dark(), child: child!),
                      );
                      if (picked != null) {
                        setState(() => _eventDate = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _formKey.currentState?.save();
                      AutoFeedOrchestratorService().addLegendsEvent(
                        id: '${_title}_${_eventDate.year}_${_eventDate.month}_${_eventDate.day}',
                        title: _title,
                        body: _description,
                        imageUrl: _imagePath,
                        publishedAt: _eventDate,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Event uploaded to pipeline!'),
                        ),
                      );
                    }
                  },
                  child: const Text('Upload Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
