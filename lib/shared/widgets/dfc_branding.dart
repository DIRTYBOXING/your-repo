import 'package:flutter/material.dart';
import '../../core/constants/image_assets.dart';
import 'dfc_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DFC Demo',
      theme: ThemeData.dark(),
      home: const DfcDemoPage(),
    );
  }
}

class DfcDemoPage extends StatefulWidget {
  const DfcDemoPage({super.key});
  @override
  State<DfcDemoPage> createState() => _DfcDemoPageState();
}

class _DfcDemoPageState extends State<DfcDemoPage> {
  String? generatedPosterUrl;

  @override
  void initState() {
    super.initState();

    // Web platform view registration disabled — needs modern Flutter web API update
  }

  void generatePoster() {
    // This just shows a sample image. Replace with your real image generator if you have one.
    setState(() {
      generatedPosterUrl = ImageAssets.bgAction;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DFC All-in-One Demo')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                'PosterBoy Image Generator',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: generatePoster,
                child: const Text('Generate Poster'),
              ),
              const SizedBox(height: 12),
              if (generatedPosterUrl != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 48,
                  ),
                  child: DfcNetworkImage(
                    url: generatedPosterUrl!,
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
