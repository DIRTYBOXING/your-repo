import 'package:flutter/material.dart';

// DFC Metaverse Portal: Immersive event access, avatar customization, NFT ticketing
class MetaversePortalScreen extends StatelessWidget {
  const MetaversePortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DFC Metaverse Portal'),
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step into the DFC Metaverse!\n\nExperience live events, customize your avatar, and access exclusive NFT tickets. Connect your streams and become part of the global fight river.',
              style: TextStyle(color: Colors.amber, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.vrpano, color: Colors.black),
              label: const Text(
                'Enter VR/AR Event',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('VR/AR event access launching...'),
                    backgroundColor: Colors.amber,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.person, color: Colors.black),
              label: const Text(
                'Customize Avatar',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Avatar customization loading...'),
                    backgroundColor: Colors.amber,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.confirmation_num, color: Colors.black),
              label: const Text(
                'NFT Ticketing',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('NFT ticketing is in development — blockchain-verified event passes launching soon'),
                    backgroundColor: Colors.amber,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.connect_without_contact,
                color: Colors.black,
              ),
              label: const Text(
                'Connect Streams',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stream connection active.'),
                    backgroundColor: Colors.amber,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
