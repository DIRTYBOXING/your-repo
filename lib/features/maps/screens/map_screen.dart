// ignore_for_file: unused_element_parameter, unused_element

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/web_route_test_hook.dart';
import '../../../shared/services/maps_service.dart';

// DFC Tier + Support enums retained for compatibility
enum DfcTier { none, bronze, silver, gold, diamond, platinum }

enum GymSupportTag { generalCommunity, mentorGoldDiamond, mentorPinkDiamond }

extension GymSupportTagExt on GymSupportTag {
  String get label {
    switch (this) {
      case GymSupportTag.generalCommunity:
        return 'Community';
      case GymSupportTag.mentorGoldDiamond:
        return 'Gold Diamond Mentor';
      case GymSupportTag.mentorPinkDiamond:
        return 'Pink Diamond Mentor';
    }
  }
}

// ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
// DFC MAP WARFARE ΓÇö Gym Finder ┬╖ Live Events ┬╖ Fighter Territories ┬╖ Drones
// The interactive nerve center of global combat sports geography
// ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;
  final MapsService _maps = MapsService();
  String _activeFilter = 'ALL';
  int _selectedGymIndex = -1;
  int _selectedEventIndex = -1;
  bool _showHeatmap = false;

  static const _filters = [
    'ALL',
    'MMA',
    'BOXING',
    'MUAY THAI',
    'BJJ',
    'KICKBOXING',
    'WRESTLING',
  ];

  // ΓöÇΓöÇ Global gym data (world regions) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  static const _worldGyms = [
    _GymPin(
      name: 'UFC Performance Institute',
      city: 'Las Vegas',
      country: '≡ƒç║≡ƒç╕',
      lat: 36.085,
      lng: -115.153,
      disciplines: ['MMA', 'Wrestling', 'BJJ'],
      rating: 4.9,
      fighters: 340,
      tier: 'elite',
      dx: 0.14,
      dy: 0.34,
    ),
    _GymPin(
      name: 'Tiger Muay Thai',
      city: 'Phuket',
      country: '≡ƒç╣≡ƒç¡',
      lat: 7.880,
      lng: 98.392,
      disciplines: ['Muay Thai', 'MMA', 'BJJ'],
      rating: 4.8,
      fighters: 280,
      tier: 'elite',
      dx: 0.73,
      dy: 0.50,
    ),
    _GymPin(
      name: 'American Top Team',
      city: 'Coconut Creek',
      country: '≡ƒç║≡ƒç╕',
      lat: 26.254,
      lng: -80.178,
      disciplines: ['MMA', 'Wrestling', 'Boxing'],
      rating: 4.8,
      fighters: 310,
      tier: 'elite',
      dx: 0.22,
      dy: 0.42,
    ),
    _GymPin(
      name: 'City Kickboxing',
      city: 'Auckland',
      country: '≡ƒç│≡ƒç┐',
      lat: -36.860,
      lng: 174.763,
      disciplines: ['MMA', 'Kickboxing', 'Wrestling'],
      rating: 4.9,
      fighters: 180,
      tier: 'elite',
      dx: 0.90,
      dy: 0.76,
    ),
    _GymPin(
      name: 'Evolve MMA',
      city: 'Singapore',
      country: '≡ƒç╕≡ƒç¼',
      lat: 1.280,
      lng: 103.851,
      disciplines: ['MMA', 'Muay Thai', 'BJJ'],
      rating: 4.7,
      fighters: 220,
      tier: 'elite',
      dx: 0.76,
      dy: 0.54,
    ),
    _GymPin(
      name: 'Tristar Gym',
      city: 'Montreal',
      country: '≡ƒç¿≡ƒçª',
      lat: 45.508,
      lng: -73.587,
      disciplines: ['MMA', 'BJJ', 'Wrestling'],
      rating: 4.9,
      fighters: 160,
      tier: 'elite',
      dx: 0.22,
      dy: 0.26,
    ),
    _GymPin(
      name: 'Alliance MMA',
      city: 'San Diego',
      country: '≡ƒç║≡ƒç╕',
      lat: 32.715,
      lng: -117.161,
      disciplines: ['MMA', 'Wrestling', 'BJJ'],
      rating: 4.7,
      fighters: 195,
      tier: 'premier',
      dx: 0.12,
      dy: 0.37,
    ),
    _GymPin(
      name: 'Fairtex Training Center',
      city: 'Pattaya',
      country: '≡ƒç╣≡ƒç¡',
      lat: 12.927,
      lng: 100.877,
      disciplines: ['Muay Thai', 'MMA'],
      rating: 4.8,
      fighters: 250,
      tier: 'elite',
      dx: 0.74,
      dy: 0.48,
    ),
    _GymPin(
      name: 'Jackson Wink MMA',
      city: 'Albuquerque',
      country: '≡ƒç║≡ƒç╕',
      lat: 35.084,
      lng: -106.650,
      disciplines: ['MMA', 'Kickboxing'],
      rating: 4.6,
      fighters: 210,
      tier: 'premier',
      dx: 0.13,
      dy: 0.36,
    ),
    _GymPin(
      name: 'Gracie Barra HQ',
      city: 'Rio de Janeiro',
      country: '≡ƒçº≡ƒç╖',
      lat: -22.906,
      lng: -43.172,
      disciplines: ['BJJ', 'MMA'],
      rating: 4.9,
      fighters: 400,
      tier: 'elite',
      dx: 0.30,
      dy: 0.64,
    ),
    _GymPin(
      name: 'Kill Cliff FC',
      city: 'Deerfield Beach',
      country: '≡ƒç║≡ƒç╕',
      lat: 26.318,
      lng: -80.099,
      disciplines: ['MMA', 'Wrestling', 'Boxing'],
      rating: 4.7,
      fighters: 170,
      tier: 'premier',
      dx: 0.22,
      dy: 0.41,
    ),
    _GymPin(
      name: 'Kings MMA',
      city: 'Huntington Beach',
      country: '≡ƒç║≡ƒç╕',
      lat: 33.660,
      lng: -117.999,
      disciplines: ['MMA', 'BJJ', 'Muay Thai'],
      rating: 4.8,
      fighters: 140,
      tier: 'premier',
      dx: 0.11,
      dy: 0.36,
    ),
    _GymPin(
      name: 'Bangtao Muay Thai',
      city: 'Phuket',
      country: '≡ƒç╣≡ƒç¡',
      lat: 7.980,
      lng: 98.297,
      disciplines: ['Muay Thai', 'Boxing'],
      rating: 4.6,
      fighters: 120,
      tier: 'standard',
      dx: 0.73,
      dy: 0.49,
    ),
    _GymPin(
      name: 'NYCFC / Serra-Longo',
      city: 'New York',
      country: '≡ƒç║≡ƒç╕',
      lat: 40.750,
      lng: -73.993,
      disciplines: ['MMA', 'Wrestling', 'Boxing'],
      rating: 4.7,
      fighters: 155,
      tier: 'premier',
      dx: 0.23,
      dy: 0.30,
    ),
    _GymPin(
      name: 'Crows Nest MMA',
      city: 'Sydney',
      country: '≡ƒçª≡ƒç║',
      lat: -33.826,
      lng: 151.203,
      disciplines: ['MMA', 'BJJ', 'Muay Thai'],
      rating: 4.5,
      fighters: 90,
      tier: 'standard',
      dx: 0.87,
      dy: 0.72,
    ),
    _GymPin(
      name: 'Absolute MMA',
      city: 'Melbourne',
      country: '≡ƒçª≡ƒç║',
      lat: -37.813,
      lng: 144.963,
      disciplines: ['MMA', 'Boxing', 'Kickboxing'],
      rating: 4.6,
      fighters: 110,
      tier: 'standard',
      dx: 0.86,
      dy: 0.75,
    ),
    _GymPin(
      name: 'Team Nogueira',
      city: 'S├úo Paulo',
      country: '≡ƒçº≡ƒç╖',
      lat: -23.550,
      lng: -46.633,
      disciplines: ['MMA', 'BJJ', 'Boxing'],
      rating: 4.5,
      fighters: 180,
      tier: 'premier',
      dx: 0.28,
      dy: 0.62,
    ),
    _GymPin(
      name: 'London Shootfighters',
      city: 'London',
      country: '≡ƒç¼≡ƒçº',
      lat: 51.507,
      lng: -0.127,
      disciplines: ['MMA', 'BJJ', 'Wrestling'],
      rating: 4.6,
      fighters: 130,
      tier: 'premier',
      dx: 0.47,
      dy: 0.22,
    ),
    _GymPin(
      name: 'ATOS Jiu-Jitsu',
      city: 'San Diego',
      country: '≡ƒç║≡ƒç╕',
      lat: 32.731,
      lng: -117.189,
      disciplines: ['BJJ'],
      rating: 4.9,
      fighters: 175,
      tier: 'elite',
      dx: 0.12,
      dy: 0.38,
    ),
    _GymPin(
      name: 'Marrok Force',
      city: 'Bangkok',
      country: '≡ƒç╣≡ƒç¡',
      lat: 13.756,
      lng: 100.501,
      disciplines: ['Muay Thai', 'MMA'],
      rating: 4.5,
      fighters: 95,
      tier: 'standard',
      dx: 0.74,
      dy: 0.47,
    ),
    // ΓöÇΓöÇ Australia Deep Dive ΓöÇΓöÇ
    _GymPin(
      name: 'Eternal MMA Training Centre',
      city: 'Brisbane',
      country: '≡ƒçª≡ƒç║',
      lat: -27.470,
      lng: 153.021,
      disciplines: ['MMA', 'BJJ', 'Muay Thai'],
      rating: 4.7,
      fighters: 85,
      tier: 'premier',
      dx: 0.89,
      dy: 0.70,
    ),
    _GymPin(
      name: 'Gold Coast Sports & Leisure Centre',
      city: 'Gold Coast',
      country: '≡ƒçª≡ƒç║',
      lat: -27.963,
      lng: 153.382,
      disciplines: ['MMA', 'Boxing', 'Kickboxing'],
      rating: 4.4,
      fighters: 60,
      tier: 'standard',
      dx: 0.89,
      dy: 0.71,
    ),
    _GymPin(
      name: 'Perth MMA Academy',
      city: 'Perth',
      country: '≡ƒçª≡ƒç║',
      lat: -31.950,
      lng: 115.860,
      disciplines: ['MMA', 'Wrestling'],
      rating: 4.5,
      fighters: 70,
      tier: 'standard',
      dx: 0.78,
      dy: 0.73,
    ),
    // ΓöÇΓöÇ Drone Racing Tracks ΓöÇΓöÇ
    _GymPin(
      name: 'DFC Drone Arena ΓÇö Sydney',
      city: 'Sydney',
      country: '≡ƒçª≡ƒç║',
      lat: -33.868,
      lng: 151.209,
      disciplines: ['Drone Racing'],
      rating: 4.8,
      fighters: 45,
      tier: 'drone',
      dx: 0.87,
      dy: 0.73,
    ),
    _GymPin(
      name: 'MultiGP Global HQ',
      city: 'Orlando',
      country: '≡ƒç║≡ƒç╕',
      lat: 28.538,
      lng: -81.379,
      disciplines: ['Drone Racing'],
      rating: 4.7,
      fighters: 120,
      tier: 'drone',
      dx: 0.21,
      dy: 0.40,
    ),
    _GymPin(
      name: 'DRL Drone Track ΓÇö London',
      city: 'London',
      country: '≡ƒç¼≡ƒçº',
      lat: 51.512,
      lng: -0.098,
      disciplines: ['Drone Racing'],
      rating: 4.6,
      fighters: 80,
      tier: 'drone',
      dx: 0.47,
      dy: 0.22,
    ),
  ];

  // ΓöÇΓöÇ Live event markers ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  static const _liveEvents = [
    _EventPin(
      name: 'IBC III',
      venue: 'Gold Coast Sports & Leisure Centre',
      org: 'IBC',
      date: 'Mar 7',
      status: 'TOMORROW',
      dx: 0.89,
      dy: 0.71,
      isLive: false,
      isPPV: false,
    ),
    _EventPin(
      name: 'UFC 323',
      venue: 'Qudos Bank Arena, Sydney',
      org: 'UFC',
      date: 'Mar 15',
      status: 'IN 9 DAYS',
      dx: 0.87,
      dy: 0.72,
      isLive: false,
      isPPV: true,
    ),
    _EventPin(
      name: 'ONE Friday Fights 144',
      venue: 'Lumpinee Stadium, Bangkok',
      org: 'ONE',
      date: 'LIVE',
      status: 'LIVE NOW',
      dx: 0.74,
      dy: 0.47,
      isLive: true,
      isPPV: false,
    ),
    _EventPin(
      name: 'Bellator 310',
      venue: 'Forum, Inglewood',
      org: 'Bellator',
      date: 'Mar 22',
      status: 'IN 16 DAYS',
      dx: 0.11,
      dy: 0.37,
      isLive: false,
      isPPV: false,
    ),
    _EventPin(
      name: 'RIZIN 53',
      venue: 'Saitama Super Arena',
      org: 'RIZIN',
      date: 'Mar 29',
      status: 'IN 23 DAYS',
      dx: 0.84,
      dy: 0.30,
      isLive: false,
      isPPV: true,
    ),
    _EventPin(
      name: 'Glory 102',
      venue: 'Ahoy, Rotterdam',
      org: 'Glory',
      date: 'LIVE',
      status: 'LIVE NOW',
      dx: 0.49,
      dy: 0.22,
      isLive: true,
      isPPV: false,
    ),
    _EventPin(
      name: 'Hex Fight Series 28',
      venue: 'Brisbane Ent Centre',
      org: 'Hex',
      date: 'Mar 14',
      status: 'IN 8 DAYS',
      dx: 0.89,
      dy: 0.69,
      isLive: false,
      isPPV: false,
    ),
    _EventPin(
      name: 'BKFC Australia 1',
      venue: 'Perth Arena',
      org: 'BKFC',
      date: 'Apr 5',
      status: 'IN 30 DAYS',
      dx: 0.78,
      dy: 0.73,
      isLive: false,
      isPPV: true,
    ),
  ];

  // ΓöÇΓöÇ Fighter territory zones ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  static const _territories = [
    _TerritoryZone(
      name: 'Wrestling Belt',
      region: 'USA Midwest/East',
      color: Color(0xFF00E5FF),
      dx: 0.18,
      dy: 0.32,
      radius: 0.06,
      dominantStyle: 'Wrestling',
      fighters: 4200,
    ),
    _TerritoryZone(
      name: 'BJJ Triangle',
      region: 'Southeast Brazil',
      color: Color(0xFF9C6FFF),
      dx: 0.30,
      dy: 0.62,
      radius: 0.05,
      dominantStyle: 'BJJ',
      fighters: 8900,
    ),
    _TerritoryZone(
      name: 'Muay Thai Heartland',
      region: 'Central Thailand',
      color: Color(0xFFFF6D00),
      dx: 0.74,
      dy: 0.48,
      radius: 0.04,
      dominantStyle: 'Muay Thai',
      fighters: 15200,
    ),
    _TerritoryZone(
      name: 'Boxing Kingdom',
      region: 'UK & Ireland',
      color: Color(0xFFFFD600),
      dx: 0.46,
      dy: 0.20,
      radius: 0.04,
      dominantStyle: 'Boxing',
      fighters: 6100,
    ),
    _TerritoryZone(
      name: 'K-1 Corridor',
      region: 'Japan / Netherlands',
      color: Color(0xFFFF1744),
      dx: 0.83,
      dy: 0.28,
      radius: 0.04,
      dominantStyle: 'Kickboxing',
      fighters: 3400,
    ),
    _TerritoryZone(
      name: 'MMA Oceania',
      region: 'Australia / NZ',
      color: Color(0xFF00E676),
      dx: 0.87,
      dy: 0.72,
      radius: 0.05,
      dominantStyle: 'MMA',
      fighters: 2800,
    ),
  ];

  // ΓöÇΓöÇ Drone racing tracks ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  static const _droneTracks = [
    _DroneTrack(
      name: 'DFC Sky Arena',
      city: 'Sydney',
      dx: 0.87,
      dy: 0.73,
      laps: 12,
      topSpeed: '185 km/h',
      record: '1:04.3',
    ),
    _DroneTrack(
      name: 'MultiGP Nationals',
      city: 'Orlando',
      dx: 0.21,
      dy: 0.40,
      laps: 8,
      topSpeed: '210 km/h',
      record: '0:58.1',
    ),
    _DroneTrack(
      name: 'DRL Championship',
      city: 'London',
      dx: 0.47,
      dy: 0.23,
      laps: 10,
      topSpeed: '195 km/h',
      record: '1:01.7',
    ),
    _DroneTrack(
      name: 'Asia FPV Cup',
      city: 'Tokyo',
      dx: 0.84,
      dy: 0.31,
      laps: 14,
      topSpeed: '200 km/h',
      record: '1:12.0',
    ),
    _DroneTrack(
      name: 'Gold Coast Drone Prix',
      city: 'Gold Coast',
      dx: 0.89,
      dy: 0.71,
      laps: 10,
      topSpeed: '175 km/h',
      record: '1:08.5',
    ),
  ];

  @override
  void initState() {
    super.initState();
    setWebRouteTestHook('map-global');
    _tabCtrl = TabController(length: 4, vsync: this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _maps.initialize();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030810),
      body: Semantics(
        label: 'data-test=map-canvas-global',
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildMapTab(),
                    _buildEventsTab(),
                    _buildTerritoriesTab(),
                    _buildDroneTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
  // HEADER
  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          bottom: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white54,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.public, color: AppColors.neonCyan, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DFC MAP WARFARE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Gyms ┬╖ Events ┬╖ Territories ┬╖ Drones',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Open Google Maps',
            onPressed: _openExternalMap,
            icon: const Icon(
              Icons.map_outlined,
              color: AppColors.neonCyan,
              size: 20,
            ),
          ),
          _buildLiveIndicator(),
        ],
      ),
    );
  }

  Future<void> _openExternalMap() async {
    final uri = Uri.parse('https://maps.google.com/?q=combat+gyms+near+me');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps on this device.'),
        ),
      );
    }
  }

  Widget _buildLiveIndicator() {
    final liveCount = _liveEvents.where((e) => e.isLive).length;
    if (liveCount == 0) return const SizedBox();

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(
              0xFFFF1744,
            ).withValues(alpha: 0.1 + _pulseCtrl.value * 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(
                0xFFFF1744,
              ).withValues(alpha: 0.3 + _pulseCtrl.value * 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF1744),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$liveCount LIVE',
                style: const TextStyle(
                  color: Color(0xFFFF1744),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: AppColors.neonCyan,
        labelColor: AppColors.neonCyan,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.location_on, size: 16), text: 'GYMS'),
          Tab(icon: Icon(Icons.stadium, size: 16), text: 'EVENTS'),
          Tab(icon: Icon(Icons.shield, size: 16), text: 'TERRITORY'),
          Tab(icon: Icon(Icons.flight, size: 16), text: 'DRONES'),
        ],
      ),
    );
  }

  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
  // TAB 1 ΓÇö GYM MAP
  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

  Widget _buildMapTab() {
    final filtered = _activeFilter == 'ALL'
        ? _worldGyms
        : _worldGyms
              .where(
                (g) =>
                    g.disciplines.any((d) => d.toUpperCase() == _activeFilter),
              )
              .toList();

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return Stack(
                children: [
                  _buildWorldMapBase(),
                  ...filtered.asMap().entries.map(
                    (e) => _buildGymMarker(e.value, e.key, constraints),
                  ),
                  if (_showHeatmap) _buildHeatmapOverlay(filtered, constraints),
                  // Scan line
                  AnimatedBuilder(
                    animation: _scanCtrl,
                    builder: (_, _) => Positioned(
                      top: 0,
                      bottom: 0,
                      left: constraints.maxWidth * _scanCtrl.value - 40,
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.neonCyan.withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Stats bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildMapStats(filtered.length),
                  ),
                ],
              );
            },
          ),
        ),
        if (_selectedGymIndex >= 0 && _selectedGymIndex < filtered.length)
          _buildGymDetailPanel(filtered[_selectedGymIndex]),
      ],
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          GestureDetector(
            onTap: () => setState(() => _showHeatmap = !_showHeatmap),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _showHeatmap
                    ? const Color(0xFFFF6D00).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showHeatmap
                      ? const Color(0xFFFF6D00)
                      : Colors.white12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.layers,
                    size: 12,
                    color: _showHeatmap
                        ? const Color(0xFFFF6D00)
                        : Colors.white38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'HEAT',
                    style: TextStyle(
                      color: _showHeatmap
                          ? const Color(0xFFFF6D00)
                          : Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ..._filters.map((f) {
            final active = f == _activeFilter;
            return GestureDetector(
              onTap: () => setState(() {
                _activeFilter = f;
                _selectedGymIndex = -1;
              }),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.neonCyan.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? AppColors.neonCyan : Colors.white12,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: active ? AppColors.neonCyan : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWorldMapBase() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.2),
          radius: 1.2,
          colors: [Color(0xFF0A1628), Color(0xFF030810)],
        ),
      ),
      child: CustomPaint(painter: _WorldOutlinePainter(), size: Size.infinite),
    );
  }

  Widget _buildGymMarker(_GymPin gym, int index, BoxConstraints constraints) {
    final x = constraints.maxWidth * gym.dx;
    final y = constraints.maxHeight * gym.dy;
    final isSelected = index == _selectedGymIndex;
    final color = gym.tier == 'elite'
        ? const Color(0xFFFFD600)
        : gym.tier == 'drone'
        ? const Color(0xFF9C6FFF)
        : gym.tier == 'premier'
        ? AppColors.neonCyan
        : const Color(0xFF00E676);

    return Positioned(
      left: x - (isSelected ? 10 : 6),
      top: y - (isSelected ? 10 : 6),
      child: GestureDetector(
        onTap: () => setState(
          () => _selectedGymIndex = _selectedGymIndex == index ? -1 : index,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 20 : 12,
          height: isSelected ? 20 : 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.9 : 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isSelected ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: isSelected ? 12 : 4,
              ),
            ],
          ),
          child: isSelected
              ? Icon(
                  gym.tier == 'drone' ? Icons.flight : Icons.fitness_center,
                  size: 10,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildHeatmapOverlay(List<_GymPin> gyms, BoxConstraints constraints) {
    return Stack(
      children: gyms.map((g) {
        final x = constraints.maxWidth * g.dx;
        final y = constraints.maxHeight * g.dy;
        final intensity = g.fighters / 400;
        return Positioned(
          left: x - 40,
          top: y - 40,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(
                    0xFFFF6D00,
                  ).withValues(alpha: intensity.clamp(0.05, 0.25)),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMapStats(int gymCount) {
    final totalFighters = _worldGyms.fold<int>(0, (s, g) => s + g.fighters);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF030810).withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('GYMS', '$gymCount', AppColors.neonCyan),
          _stat('COUNTRIES', '18', const Color(0xFF00E676)),
          _stat('FIGHTERS', '$totalFighters+', const Color(0xFFFFD600)),
          _stat(
            'LIVE EVENTS',
            '${_liveEvents.where((e) => e.isLive).length}',
            const Color(0xFFFF1744),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGymDetailPanel(_GymPin gym) {
    final color = gym.tier == 'elite'
        ? const Color(0xFFFFD600)
        : gym.tier == 'drone'
        ? const Color(0xFF9C6FFF)
        : gym.tier == 'premier'
        ? AppColors.neonCyan
        : const Color(0xFF00E676);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  gym.tier == 'drone' ? Icons.flight : Icons.fitness_center,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gym.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${gym.city}, ${gym.country}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  gym.tier.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _detailChip('Γ¡É ${gym.rating}', Colors.amber),
              _detailChip('≡ƒÑè ${gym.fighters} fighters', Colors.white54),
              ...gym.disciplines
                  .take(3)
                  .map((d) => _detailChip(d, color.withValues(alpha: 0.7))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
  // TAB 2 ΓÇö LIVE EVENTS MAP
  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

  Widget _buildEventsTab() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return Stack(
                children: [
                  _buildWorldMapBase(),
                  ..._liveEvents.asMap().entries.map(
                    (e) => _buildEventMarker(e.value, e.key, constraints),
                  ),
                  AnimatedBuilder(
                    animation: _scanCtrl,
                    builder: (_, _) => Positioned(
                      top: 0,
                      bottom: 0,
                      left: constraints.maxWidth * _scanCtrl.value - 40,
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFF1744).withValues(alpha: 0.03),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_selectedEventIndex >= 0)
          _buildEventDetailPanel(_liveEvents[_selectedEventIndex]),
        _buildEventList(),
      ],
    );
  }

  Widget _buildEventMarker(
    _EventPin event,
    int idx,
    BoxConstraints constraints,
  ) {
    final x = constraints.maxWidth * event.dx;
    final y = constraints.maxHeight * event.dy;
    final isSelected = idx == _selectedEventIndex;
    final color = event.isLive ? const Color(0xFFFF1744) : AppColors.neonCyan;

    return Positioned(
      left: x - (isSelected ? 12 : 8),
      top: y - (isSelected ? 12 : 8),
      child: GestureDetector(
        onTap: () => setState(
          () => _selectedEventIndex = _selectedEventIndex == idx ? -1 : idx,
        ),
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) {
            final pulse = event.isLive ? _pulseCtrl.value : 0.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: (isSelected ? 24 : 16) + (pulse * 4),
              height: (isSelected ? 24 : 16) + (pulse * 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isSelected ? 0.9 : 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: isSelected ? 2.5 : 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: event.isLive ? 0.5 : 0.2),
                    blurRadius: event.isLive ? 16 : 6,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  event.isLive ? Icons.circle : Icons.stadium,
                  size: isSelected ? 12 : 8,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventDetailPanel(_EventPin event) {
    final color = event.isLive ? const Color(0xFFFF1744) : AppColors.neonCyan;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              event.isLive ? Icons.live_tv : Icons.event,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  event.venue,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              event.status,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return Container(
      height: 120,
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _liveEvents.length,
        itemBuilder: (ctx, i) {
          final event = _liveEvents[i];
          final color = event.isLive
              ? const Color(0xFFFF1744)
              : AppColors.neonCyan;
          return GestureDetector(
            onTap: () => setState(() => _selectedEventIndex = i),
            child: Container(
              width: 180,
              margin: const EdgeInsets.only(right: 8, top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color.withValues(
                    alpha: i == _selectedEventIndex ? 0.6 : 0.15,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (event.isLive) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF1744),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        event.org,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      if (event.isPPV)
                        const Text(
                          'PPV',
                          style: TextStyle(
                            color: Color(0xFFFFD600),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.venue,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.status,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
  // TAB 3 ΓÇö FIGHTER TERRITORIES
  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

  Widget _buildTerritoriesTab() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return Stack(
                children: [
                  _buildWorldMapBase(),
                  ..._territories.map(
                    (t) => _buildTerritoryZone(t, constraints),
                  ),
                ],
              );
            },
          ),
        ),
        _buildTerritoryLegend(),
      ],
    );
  }

  Widget _buildTerritoryZone(_TerritoryZone zone, BoxConstraints constraints) {
    final x = constraints.maxWidth * zone.dx;
    final y = constraints.maxHeight * zone.dy;
    final size = constraints.maxWidth * zone.radius * 2;
    return Positioned(
      left: x - size / 2,
      top: y - size / 2,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) {
          final pulse = 1.0 + _pulseCtrl.value * 0.12;
          return Transform.scale(
            scale: pulse,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    zone.color.withValues(alpha: 0.3),
                    zone.color.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(color: zone.color.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      zone.dominantStyle.toUpperCase(),
                      style: TextStyle(
                        color: zone.color,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${zone.fighters}',
                      style: TextStyle(
                        color: zone.color.withValues(alpha: 0.7),
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTerritoryLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FIGHTER TERRITORIES',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _territories
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: t.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: t.color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: t.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${t.name} ┬╖ ${t.fighters}',
                          style: TextStyle(
                            color: t.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
  // TAB 4 ΓÇö DRONE RACING
  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

  Widget _buildDroneTab() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return Stack(
                children: [
                  _buildWorldMapBase(),
                  ..._droneTracks.map(
                    (t) => _buildDroneTrackMarker(t, constraints),
                  ),
                ],
              );
            },
          ),
        ),
        _buildDroneTrackList(),
      ],
    );
  }

  Widget _buildDroneTrackMarker(_DroneTrack track, BoxConstraints constraints) {
    final x = constraints.maxWidth * track.dx;
    final y = constraints.maxHeight * track.dy;
    return Positioned(
      left: x - 10,
      top: y - 10,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) => Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(
              0xFF9C6FFF,
            ).withValues(alpha: 0.6 + _pulseCtrl.value * 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF9C6FFF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C6FFF).withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.flight, size: 10, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildDroneTrackList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF9C6FFF).withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flight, color: Color(0xFF9C6FFF), size: 14),
              SizedBox(width: 6),
              Text(
                'DFC DRONE RACING TRACKS',
                style: TextStyle(
                  color: Color(0xFF9C6FFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._droneTracks.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _detailChip('${t.laps} laps', const Color(0xFF9C6FFF)),
                  const SizedBox(width: 6),
                  _detailChip(t.topSpeed, const Color(0xFF00E676)),
                  const SizedBox(width: 6),
                  _detailChip('≡ƒÅå ${t.record}', const Color(0xFFFFD600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
// CUSTOM PAINTER ΓÇö World outline (simplified continent shapes)
// ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

class _WorldOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final fill = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;

    for (int i = 1; i < 10; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 10),
        Offset(size.width, size.height * i / 10),
        gridPaint,
      );
      canvas.drawLine(
        Offset(size.width * i / 10, 0),
        Offset(size.width * i / 10, size.height),
        gridPaint,
      );
    }

    void drawContinent(List<Offset> points) {
      if (points.length < 3) return;
      final path = Path();
      path.moveTo(points[0].dx * size.width, points[0].dy * size.height);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx * size.width, points[i].dy * size.height);
      }
      path.close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, paint);
    }

    // North America
    drawContinent([
      const Offset(0.05, 0.15),
      const Offset(0.22, 0.12),
      const Offset(0.27, 0.18),
      const Offset(0.26, 0.30),
      const Offset(0.22, 0.42),
      const Offset(0.15, 0.48),
      const Offset(0.10, 0.38),
      const Offset(0.06, 0.25),
    ]);
    // South America
    drawContinent([
      const Offset(0.20, 0.52),
      const Offset(0.30, 0.48),
      const Offset(0.35, 0.55),
      const Offset(0.34, 0.70),
      const Offset(0.28, 0.85),
      const Offset(0.22, 0.78),
      const Offset(0.20, 0.62),
    ]);
    // Europe
    drawContinent([
      const Offset(0.44, 0.12),
      const Offset(0.54, 0.14),
      const Offset(0.56, 0.22),
      const Offset(0.52, 0.32),
      const Offset(0.46, 0.34),
      const Offset(0.44, 0.28),
      const Offset(0.42, 0.20),
    ]);
    // Africa
    drawContinent([
      const Offset(0.44, 0.36),
      const Offset(0.56, 0.34),
      const Offset(0.60, 0.45),
      const Offset(0.57, 0.65),
      const Offset(0.50, 0.72),
      const Offset(0.44, 0.60),
      const Offset(0.42, 0.45),
    ]);
    // Asia
    drawContinent([
      const Offset(0.58, 0.12),
      const Offset(0.85, 0.14),
      const Offset(0.88, 0.28),
      const Offset(0.82, 0.45),
      const Offset(0.70, 0.48),
      const Offset(0.60, 0.38),
      const Offset(0.56, 0.25),
    ]);
    // Australia
    drawContinent([
      const Offset(0.82, 0.62),
      const Offset(0.92, 0.64),
      const Offset(0.94, 0.72),
      const Offset(0.90, 0.80),
      const Offset(0.82, 0.78),
      const Offset(0.80, 0.70),
    ]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
// DATA MODELS
// ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

class _GymPin {
  final String name, city, country, tier;
  final double lat, lng, dx, dy, rating;
  final List<String> disciplines;
  final int fighters;
  const _GymPin({
    required this.name,
    required this.city,
    required this.country,
    required this.lat,
    required this.lng,
    required this.disciplines,
    required this.rating,
    required this.fighters,
    required this.tier,
    required this.dx,
    required this.dy,
  });
}

class _EventPin {
  final String name, venue, org, date, status;
  final double dx, dy;
  final bool isLive, isPPV;
  const _EventPin({
    required this.name,
    required this.venue,
    required this.org,
    required this.date,
    required this.status,
    required this.dx,
    required this.dy,
    required this.isLive,
    required this.isPPV,
  });
}

class _TerritoryZone {
  final String name, region, dominantStyle;
  final Color color;
  final double dx, dy, radius;
  final int fighters;
  const _TerritoryZone({
    required this.name,
    required this.region,
    required this.color,
    required this.dx,
    required this.dy,
    required this.radius,
    required this.dominantStyle,
    required this.fighters,
  });
}

class _DroneTrack {
  final String name, city, topSpeed, record;
  final double dx, dy;
  final int laps;
  const _DroneTrack({
    required this.name,
    required this.city,
    required this.dx,
    required this.dy,
    required this.laps,
    required this.topSpeed,
    required this.record,
  });
}
