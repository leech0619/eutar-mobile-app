import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusMapOverviewScreen extends StatefulWidget {
  const BusMapOverviewScreen({super.key});

  @override
  _BusMapOverviewScreenState createState() => _BusMapOverviewScreenState();
}

class _BusMapOverviewScreenState extends State<BusMapOverviewScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMarkers(); // Initialize markers when the screen loads
  }

  void _initializeMarkers() {
    // Add markers for all stops
    final stops = [
      'UTAR Block D',
      'UTAR Block G',
      'UTAR Block N',
      'Stanford Bus Stop',
      'V2 Optical Shop',
      'Taman Mahsuri Impian',
      'Harvard & Cambridge',
      'Westlake 1',
      'Westlake 2',
      'Westlake 3',
      'Champs Elysees/The Trails',
    ];

    for (final stop in stops) {
      final position = _getLocationForStop(stop);
      _markers.add(
        Marker(
          markerId: MarkerId(stop),
          position: position,
          infoWindow: InfoWindow(title: stop),
        ),
      );
    }
  }

  LatLng _getLocationForStop(String stopName) {
    // Return the location for each stop
    switch (stopName) {
      case 'UTAR Block D':
        return const LatLng(4.338115104744316, 101.1438004149668);
      case 'UTAR Block G':
        return const LatLng(4.340407678390168, 101.14358161247885);
      case 'UTAR Block N':
        return const LatLng(4.338909947691619, 101.13661859791222);
      case 'Stanford Bus Stop':
        return const LatLng(4.326598839352191, 101.13491463433371);
      case 'V2 Optical Shop':
        return const LatLng(4.3262801748307735, 101.14343490343325);
      case 'Taman Mahsuri Impian':
        return const LatLng(4.328170722263601, 101.1511850798773);
      case 'Harvard & Cambridge':
        return const LatLng(4.3308804452733725, 101.13231301152658);
      case 'Westlake 1':
        return const LatLng(4.329125938362558, 101.13656163046677);
      case 'Westlake 2':
        return const LatLng(4.329897666191284, 101.13918033684243);
      case 'Westlake 3':
        return const LatLng(4.33078070699843, 101.13639460717039);
      case 'Champs Elysees/The Trails':
        return const LatLng(4.319810902677306, 101.12434723845445);
      default:
        debugPrint(
          "Warning: Unknown stop name '$stopName', using default location.",
        );
        return const LatLng(4.3328, 101.1236); // Default location
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text(
          'Bus Map Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),

        ),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(4.3331, 101.1345), // UTAR location
          zoom: 15.0,
        ),
        markers: _markers, // Add markers to the map
        polylines: _polylines,
        myLocationEnabled: true,
      ),
    );
  }
}