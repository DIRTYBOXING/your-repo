import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class PpvExploreScreen extends StatefulWidget {
  const PpvExploreScreen({super.key});

  @override
  State<PpvExploreScreen> createState() => _PpvExploreScreenState();
}

class _PpvExploreScreenState extends State<PpvExploreScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Using a WebView to render a 3D Earth using WebGL/Mapbox/ThreeJS
    // This allows for high-performance 3D rendering cross-platform
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF020810))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Inject events data into the globe once loaded
            _injectEventsData();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: \${error.description}');
          },
        ),
      )
      ..loadHtmlString(_getEarthHtml());
  }

  void _injectEventsData() {
    // Inject the mock events data into the 3D globe to draw the neon shockwaves
    const String data = '''
      [
        { "id": "1", "name": "DFC 300: Tokyo Drift", "lat": 35.6762, "lng": 139.6503, "color": "#FF00FF" },
        { "id": "2", "name": "Underground Series: NY", "lat": 40.7128, "lng": -74.0060, "color": "#00FFFF" },
        { "id": "3", "name": "London Brawl", "lat": 51.5074, "lng": -0.1278, "color": "#00FF00" },
        { "id": "4", "name": "Sydney Showdown", "lat": -33.8688, "lng": 151.2093, "color": "#FF9800" }
      ]
    ''';
    _controller.runJavaScript('window.loadEvents(\$data);');
  }

  String _getEarthHtml() {
    // This is a minimal Three.js/WebGL HTML stub that renders a 3D globe.
    // In production, you would host this file on a CDN or embed the full ThreeJS library.
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          body { margin: 0; padding: 0; background-color: #020810; overflow: hidden; }
          #canvas-container { width: 100vw; height: 100vh; }
          .overlay-text { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); color: rgba(0, 255, 255, 0.5); font-family: monospace; font-size: 24px; text-align: center; pointer-events: none; }
        </style>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js"></script>
      </head>
      <body>
        <div id="canvas-container"></div>
        <div class="overlay-text" id="loading-text">INITIALIZING GLOBAL GRID...</div>
        <script>
          let scene, camera, renderer, globe, controls;
          const markers = [];
          
          function init() {
            const container = document.getElementById('canvas-container');
            
            // Scene
            scene = new THREE.Scene();
            
            // Camera
            camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
            camera.position.z = 3;
            
            // Renderer
            renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.setPixelRatio(window.devicePixelRatio);
            container.appendChild(renderer.domElement);
            
            // Globe Geometry
            const geometry = new THREE.SphereGeometry(1, 64, 64);
            
            // Tech/Wireframe Material
            const material = new THREE.MeshBasicMaterial({
              color: 0x0a192f,
              wireframe: true,
              transparent: true,
              opacity: 0.3
            });
            
            globe = new THREE.Mesh(geometry, material);
            scene.add(globe);
            
            // Inner solid sphere to block seeing through
            const innerGeo = new THREE.SphereGeometry(0.99, 32, 32);
            const innerMat = new THREE.MeshBasicMaterial({ color: 0x020810 });
            const innerGlobe = new THREE.Mesh(innerGeo, innerMat);
            scene.add(innerGlobe);
            
            // Controls
            controls = new THREE.OrbitControls(camera, renderer.domElement);
            controls.enableDamping = true;
            controls.dampingFactor = 0.05;
            controls.enablePan = false;
            controls.minDistance = 1.5;
            controls.maxDistance = 5;
            controls.autoRotate = true;
            controls.autoRotateSpeed = 0.5;
            
            // Handle resize
            window.addEventListener('resize', onWindowResize, false);
            
            // Remove loading text
            document.getElementById('loading-text').style.display = 'none';
            
            animate();
          }
          
          function onWindowResize() {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
          }
          
          function animate() {
            requestAnimationFrame(animate);
            controls.update();
            
            // Animate shockwaves
            markers.forEach(marker => {
              marker.scale.x += 0.02;
              marker.scale.y += 0.02;
              marker.material.opacity -= 0.01;
              if (marker.material.opacity <= 0) {
                marker.scale.set(1, 1, 1);
                marker.material.opacity = 1;
              }
            });
            
            renderer.render(scene, camera);
          }
          
          // Function called from Flutter to inject data
          window.loadEvents = function(data) {
            data.forEach(event => {
              // Convert lat/lng to 3D spherical coordinates
              const phi = (90 - event.lat) * (Math.PI / 180);
              const theta = (event.lng + 180) * (Math.PI / 180);
              
              const x = -(Math.sin(phi) * Math.cos(theta));
              const z = (Math.sin(phi) * Math.sin(theta));
              const y = (Math.cos(phi));
              
              // Create a neon shockwave ring
              const ringGeo = new THREE.RingGeometry(0.01, 0.04, 32);
              const ringMat = new THREE.MeshBasicMaterial({ 
                color: new THREE.Color(event.color), 
                side: THREE.DoubleSide,
                transparent: true,
                opacity: 1
              });
              
              const ring = new THREE.Mesh(ringGeo, ringMat);
              
              // Position on the surface of the globe
              ring.position.set(x, y, z);
              
              // Orient the ring to face outwards from the sphere center
              ring.lookAt(new THREE.Vector3(x * 2, y * 2, z * 2));
              
              globe.add(ring);
              markers.push(ring);
              
              // Add a solid center dot
              const dotGeo = new THREE.CircleGeometry(0.01, 16);
              const dotMat = new THREE.MeshBasicMaterial({ color: 0xffffff });
              const dot = new THREE.Mesh(dotGeo, dotMat);
              dot.position.set(x * 1.001, y * 1.001, z * 1.001);
              dot.lookAt(new THREE.Vector3(x * 2, y * 2, z * 2));
              globe.add(dot);
            });
          };
          
          init();
        </script>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020810),
      body: Stack(
        children: [
          // The 3D WebGL Globe
          WebViewWidget(controller: _controller),
          
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.neonCyan),
            ),
            
          // Top Overlay UI
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 20,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF020810).withValues(alpha: 0.9),
                    const Color(0xFF020810).withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'GLOBAL EVENTS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
          ),
          
          // Bottom Event Carousel Overlay
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildEventCard('DFC 300: Tokyo Drift', 'Tokyo, Japan', 'Oct 24', AppTheme.neonMagenta),
                  _buildEventCard('Underground Series: NY', 'New York, USA', 'Nov 12', AppTheme.neonCyan),
                  _buildEventCard('London Brawl', 'London, UK', 'Dec 05', AppTheme.neonGreen),
                  _buildEventCard('Sydney Showdown', 'Sydney, AUS', 'Jan 15', Colors.orange),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEventCard(String title, String location, String date, Color color) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  date,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.public, color: Colors.white.withValues(alpha: 0.3), size: 16),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}