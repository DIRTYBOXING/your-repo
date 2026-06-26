import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/ppv_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../services/sales_service.dart';

/// Create PPV Event Screen - For promoters to create new PPV events
class CreatePPVScreen extends StatefulWidget {
  final String? eventId; // Optional: link to existing event

  const CreatePPVScreen({super.key, this.eventId});

  @override
  State<CreatePPVScreen> createState() => _CreatePPVScreenState();
}

class _CreatePPVScreenState extends State<CreatePPVScreen> {
  final _formKey = GlobalKey<FormState>();
  final PPVService _ppvService = PPVService();
  final SalesService _salesService = SalesService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '20.00');
  final _videoUrlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  final _trailerUrlController = TextEditingController();
  final _promoterShareController = TextEditingController(text: '85');

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPromoterVerification();
    });
  }

  void _checkPromoterVerification() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.userModel;
    if (user == null || user.businessVerified != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete promoter onboarding before creating events.'),
          backgroundColor: Colors.orange,
        ),
      );
      context.pushReplacement('/onboarding/promoter');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _videoUrlController.dispose();
    _thumbnailUrlController.dispose();
    _trailerUrlController.dispose();
    _promoterShareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create PPV Event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Title
            const Text(
              'Event Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a pay-per-view event and earn revenue',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),

            // Event Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Event Name *',
                hintText: 'IBC 4: Battle at the Beach',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter event name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description *',
                hintText:
                    'Describe your event, fighters, and what viewers can expect...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Event Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Event Date *'),
              subtitle: Text(
                _formatDate(_selectedDate),
                style: const TextStyle(color: Color(0xFF00F0FF)),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Price
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price (USD) *',
                      hintText: '20.00',
                      prefixText: '\$',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Invalid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _promoterShareController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Your Share %',
                      hintText: '85',
                      suffixText: '%',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final share = int.tryParse(value);
                      if (share == null || share < 50 || share > 95) {
                        return '50-95%';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: _buildRevenueCalculator(),
            ),
            const SizedBox(height: 24),

            // Video URL
            TextFormField(
              controller: _videoUrlController,
              decoration: InputDecoration(
                labelText: 'Video URL *',
                hintText: 'https://vimeo.com/your-video',
                helperText: 'Vimeo, YouTube, or direct video link',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter video URL';
                }
                if (!value.startsWith('http')) {
                  return 'Must be valid URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Thumbnail URL (optional)
            TextFormField(
              controller: _thumbnailUrlController,
              decoration: InputDecoration(
                labelText: 'Thumbnail URL (Optional)',
                hintText: 'https://your-image.com/thumbnail.jpg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 16),

            // Trailer URL (optional)
            TextFormField(
              controller: _trailerUrlController,
              decoration: InputDecoration(
                labelText: 'Trailer URL (Optional)',
                hintText: 'https://your-video.com/trailer.mp4',
                helperText: 'Free preview to attract buyers',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPPVEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Create PPV Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'How PPV Works',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Fans purchase access to watch your event\n'
                    '• You keep ${_promoterShareController.text}% of every sale\n'
                    '• Platform handles payments & video delivery\n'
                    '• Get paid weekly via Stripe\n'
                    '• No upfront costs - only pay when you earn',
                    style: TextStyle(color: Colors.grey[300], height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCalculator() {
    final price = double.tryParse(_priceController.text) ?? 20.0;
    final sharePercent = int.tryParse(_promoterShareController.text) ?? 85;
    final shareDecimal = sharePercent / 100;

    final scenarios = [100, 250, 500, 1000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calculate, size: 16, color: Colors.blue),
            SizedBox(width: 4),
            Text(
              'Revenue Calculator',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...scenarios.map((buyers) {
          final yourRevenue = (buyers * price * shareDecimal).toStringAsFixed(
            0,
          );
          final platformRevenue = (buyers * price * (1 - shareDecimal))
              .toStringAsFixed(0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '$buyers buyers → You: \$$yourRevenue | Platform: \$$platformRevenue',
              style: TextStyle(fontSize: 11, color: Colors.grey[300]),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createPPVEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final promoterId = auth.currentUser?.uid;
      if (promoterId == null) {
        throw Exception('Promoter session unavailable');
      }

      final eventId = await _ppvService.createPPVEvent(
        eventId: widget.eventId ?? '',
        title: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: _selectedDate,
        standardPriceCents: (double.parse(_priceController.text) * 100).round(),
        streamUrl: _videoUrlController.text.trim().isEmpty
            ? null
            : _videoUrlController.text.trim(),
        posterUrl: _thumbnailUrlController.text.trim().isEmpty
            ? null
            : _thumbnailUrlController.text.trim(),
        trailerUrl: _trailerUrlController.text.trim().isEmpty
            ? null
            : _trailerUrlController.text.trim(),
        platformFeePct: 1.0 - (int.parse(_promoterShareController.text) / 100),
      );

      final seededOffers = await _salesService.bootstrapEventSalesEngine(
        eventId: eventId,
        promoterId: promoterId,
        title: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: _selectedDate,
        basePriceCents: (double.parse(_priceController.text) * 100).round(),
        posterUrl: _thumbnailUrlController.text.trim().isEmpty
            ? null
            : _thumbnailUrlController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PPV Event created successfully. ${seededOffers.length} AI sales offers prepared.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(eventId);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
