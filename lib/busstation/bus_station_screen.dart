import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusStationScreen extends StatefulWidget {
  const BusStationScreen({super.key});

  @override
  _BusStationScreenState createState() => _BusStationScreenState();
}

class _BusStationScreenState extends State<BusStationScreen> {
  late GoogleMapController mapController;

  static const LatLng utarBusStation = LatLng(4.3331, 101.1345);
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(
        markerId: const MarkerId('utar_bus_station'),
        position: utarBusStation,
        infoWindow: const InfoWindow(
          title: 'UTAR Bus Station',
          snippet: 'Click for more info',
        ),
        onTap: () {
          _showBusStationInfo();
        },
      ),
    );
  }

  void _showBusStationInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('UTAR Bus Station'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This is the UTAR bus station where buses arrive and depart.'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Add logic to open the bus schedule PDF
                  Navigator.of(context).pop();
                },
                child: const Text('View Bus Schedule'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Station Map'),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition: const CameraPosition(
          target: utarBusStation,
          zoom: 14.0,
        ),
        markers: _markers,
      ),
    );
  }
}