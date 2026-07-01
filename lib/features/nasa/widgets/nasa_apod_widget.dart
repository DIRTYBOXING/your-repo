import 'package:flutter/material.dart';
import '../../../shared/services/nasa_api_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

class NasaApodWidget extends StatefulWidget {
  const NasaApodWidget({super.key});

  @override
  State<NasaApodWidget> createState() => _NasaApodWidgetState();
}

class _NasaApodWidgetState extends State<NasaApodWidget> {
  Map<String, dynamic>? apodData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchApod();
  }

  Future<void> _fetchApod() async {
    final service = NasaApiService();
    final data = await service.fetchApod();
    setState(() {
      apodData = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (apodData == null) {
      return const Center(child: Text('Failed to load NASA APOD'));
    }
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (apodData!["url"] != null && apodData!["media_type"] == 'image')
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: DfcNetworkImage(url: apodData!["url"]),
            )
          else if (apodData!["url"] != null &&
              apodData!["media_type"] == 'video')
            Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFF0A1628),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      color: Colors.white54,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Video — view on NASA site',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apodData!["title"] ?? '',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  apodData!["explanation"] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
