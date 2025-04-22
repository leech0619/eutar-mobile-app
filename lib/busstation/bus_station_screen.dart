import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'dart:math';

class BusStationScreen extends StatefulWidget {
  const BusStationScreen({super.key});

  @override
  _BusStationScreenState createState() => _BusStationScreenState();
}

class _BusStationScreenState extends State<BusStationScreen> {
  late GoogleMapController mapController;
  static const LatLng utarBusStation = LatLng(4.3331, 101.1345);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String filter = "All"; // Filter for routes (e.g., "Depart from UTAR")
  LatLng? currentLocation;
Map<String, dynamic>? busScheduleData; // To store the entire bus schedule JSON data
List<dynamic> filteredRoutes = []; // To store the filtered list of routes
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadAndDisplayBusSchedule();
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final locData = await location.getLocation();
    setState(() {
      currentLocation = LatLng(locData.latitude!, locData.longitude!);
    });

    // Add current location marker
    _resetMap();
  }

  Future<Map<String, dynamic>> loadBusSchedule() async {
    try {
      final String response = await rootBundle.loadString('assets/json/bus_schedule.json');
      return json.decode(response);
    } catch (e) {
      print('Error loading JSON file: $e');
      return {};
    }
  }

  void _loadAndDisplayBusSchedule() async {
    final data = await loadBusSchedule();
    final routes = data['routes'];
    _markers.clear();
    _polylines.clear();
setState(() {
    busScheduleData = data;
    filteredRoutes = data['routes']; // Initialize with all routes
  });
    for (var route in routes) {
      // Add markers for each stop
      for (var stop in route['stops']) {
        _markers.add(
          Marker(
            markerId: MarkerId(stop['name']),
            position: LatLng(stop['lat'], stop['lng']),
            infoWindow: InfoWindow(
              title: stop['name'],
              snippet: 'Click for details',
              onTap: () {
                _showStopDetails(stop, route['trips']);
              },
            ),
          ),
        );
      }

      // Add polylines for each route
      final List<LatLng> routeCoordinates = route['stops']
          .map<LatLng>((stop) => LatLng(stop['lat'], stop['lng']))
          .toList();

      _polylines.add(
        Polyline(
          polylineId: PolylineId(route['id']),
          points: routeCoordinates,
          color: Colors.blue,
          width: 5,
        ),
      );
    }
    setState(() {});
  }

  void _resetMap() {
    setState(() {
      _markers.clear();
      _polylines.clear();
      if (currentLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: currentLocation!,
            infoWindow: const InfoWindow(title: 'You are here'),
          ),
        );
      }
    });
  }

  void _suggestNearestBusStation() {
    if (currentLocation == null) return;

    double minDistance = double.infinity;
    Marker? nearestMarker;

    for (var marker in _markers) {
      final distance = _calculateDistance(
        currentLocation!.latitude,
        currentLocation!.longitude,
        marker.position.latitude,
        marker.position.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestMarker = marker;
      }
    }

    if (nearestMarker != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLng(nearestMarker.position),
      );

      // Show a modal bottom sheet for the nearest bus stop
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nearest Bus Stop',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Bus Stop: ${nearestMarker?.infoWindow.title}'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius of the Earth in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

    void _showStopDetails(Map<String, dynamic> stop, List<dynamic> trips) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stop['name']),
              IconButton(
                icon: Icon(
                  favoriteStops.contains(stop['name'])
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: favoriteStops.contains(stop['name'])
                      ? Colors.red
                      : null,
                ),
                onPressed: () {
                  _toggleFavorite(stop['name']);
                  Navigator.of(context).pop();
                  _showStopDetails(stop, trips); // Refresh dialog
                },
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('All Departures:'),
              ...trips.map((trip) {
                final departure = trip['departures'].firstWhere(
                  (d) => d['stop'] == stop['name'],
                  orElse: () => null,
                );
                return departure != null
                    ? Text('Trip ${trip['tripNumber']}: ${departure['time']}')
                    : const SizedBox.shrink();
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
Set<String> favoriteStops = {};
void _toggleFavorite(String stopName) {
  setState(() {
    if (favoriteStops.contains(stopName)) {
      favoriteStops.remove(stopName);
    } else {
      favoriteStops.add(stopName);
    }
  });
}
final TextEditingController _searchController = TextEditingController();
void _searchRoutes(String query) {
  setState(() {
    if (query.isEmpty) {
      filteredRoutes = busScheduleData!['routes']; // Reset to all routes
    } else {
      filteredRoutes = busScheduleData!['routes']
          .where((route) => route['name']
              .toLowerCase()
              .contains(query.toLowerCase()) ||
              route['stops'].any((stop) => stop['name']
                  .toLowerCase()
                  .contains(query.toLowerCase())))
          .toList();
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Station Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAndDisplayBusSchedule,
          ),
          IconButton(
            icon: const Icon(Icons.near_me),
            onPressed: _suggestNearestBusStation,
          ),
        ],
      ),
      body: SlidingUpPanel(
        panel: _buildSlidingPanel(),
        collapsed: _buildCollapsedPanel(),
        body: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: currentLocation ?? utarBusStation,
            zoom: 14.0,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
        ),
      ),
    );
  }

    Widget _buildSlidingPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search routes or stops',
              prefixIcon: Icon(Icons.search),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchRoutes('');
                },
              ),
            ),
            onChanged: _searchRoutes,
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: loadBusSchedule(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final routes = filteredRoutes;
              return ListView.builder(
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return ExpansionTile(
                    title: Text(route['name']),
                    children: route['trips'].map<Widget>((trip) {
                      return ListTile(
                        title: Text('Trip ${trip['tripNumber']}'),
                        subtitle: Text('Departure: ${trip['departures'][0]['time']}'),
                        onTap: () {
                          _showTripOnMap(route, trip);
                        },
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildCollapsedPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Center(
        child: Text(
          'Swipe up for Bus Schedule',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showTripOnMap(Map<String, dynamic> route, Map<String, dynamic> trip) {
    _markers.clear();
    _polylines.clear();

    for (var stop in route['stops']) {
      _markers.add(
        Marker(
          markerId: MarkerId(stop['name']),
          position: LatLng(stop['lat'], stop['lng']),
          infoWindow: InfoWindow(
            title: stop['name'],
            snippet: 'Next Trip: ${trip['departures'].firstWhere((d) => d['stop'] == stop['name'], orElse: () => null)?['time'] ?? 'N/A'}',
          ),
        ),
      );
    }

    final List<LatLng> routeCoordinates = route['stops']
        .map<LatLng>((stop) => LatLng(stop['lat'], stop['lng']))
        .toList();

    _polylines.add(
      Polyline(
        polylineId: PolylineId(route['id']),
        points: routeCoordinates,
        color: Colors.red,
        width: 5,
      ),
    );

    setState(() {});
  }
}