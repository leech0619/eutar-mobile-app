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
  final TextEditingController _searchController = TextEditingController();
  Set<String> favoriteStops = {};
  final PanelController _panelController = PanelController();
  bool isLoading = true;

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
      final data = json.decode(response);
      print('Loaded bus schedule: ${data['routes'].length} routes found');
      return data;
    } catch (e) {
      print('Error loading JSON file: $e');
      return {};
    }
  }

  void _loadAndDisplayBusSchedule() async {
  setState(() {
    isLoading = true;
  });
  
  final data = await loadBusSchedule();
  
  // Check if data is valid and has routes
  if (data.isEmpty || !data.containsKey('routes')) {
    print('Error: Invalid or empty bus schedule data');
    setState(() {
      isLoading = false;
    });
    return;
  }
  
  // Print the structure of the first route for debugging
  if (data['routes'].isNotEmpty) {
    print('First route structure: ${data['routes'][0]}');
    if (data['routes'][0].containsKey('stops') && data['routes'][0]['stops'].isNotEmpty) {
      print('First stop structure: ${data['routes'][0]['stops'][0]}');
    }
  }
  
  try {
    setState(() {
      busScheduleData = data;
      filteredRoutes = List.from(data['routes']); // Create a copy for filtering
      
      _markers.clear();
      _polylines.clear();
      
      // Add markers for default view (all stops)
      for (var route in data['routes']) {
        // Ensure stops is a list
        List<dynamic> stops = route['stops'] is List ? route['stops'] : [];
        
        for (var stop in stops) {
          // Safely access properties with null checks
          if (stop != null && stop['name'] != null && stop['lat'] != null && stop['lng'] != null) {
            _markers.add(
              Marker(
                markerId: MarkerId(stop['name'].toString()),
                position: LatLng(
                  double.tryParse(stop['lat'].toString()) ?? 0.0,
                  double.tryParse(stop['lng'].toString()) ?? 0.0
                ),
                infoWindow: InfoWindow(
                  title: stop['name'].toString(),
                  snippet: 'Click for details',
                  onTap: () {
                    _showStopDetails(stop, route['trips'] ?? []);
                  },
                ),
              ),
            );
          }
        }
      }
      
      // Add all route polylines for initial view
      for (var route in data['routes']) {
        List<dynamic> stops = route['stops'] is List ? route['stops'] : [];
        
        final List<LatLng> routeCoordinates = [];
        for (var stop in stops) {
          if (stop != null && stop['lat'] != null && stop['lng'] != null) {
            routeCoordinates.add(
              LatLng(
                double.tryParse(stop['lat'].toString()) ?? 0.0,
                double.tryParse(stop['lng'].toString()) ?? 0.0
              )
            );
          }
        }

        if (routeCoordinates.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: PolylineId(route['id']?.toString() ?? "route_${data['routes'].indexOf(route)}"),
              points: routeCoordinates,
              color: Colors.blue,
              width: 5,
            ),
          );
        }
      }
      
      isLoading = false;
    });
  } catch (e) {
    print('Error processing bus schedule data: $e');
    setState(() {
      isLoading = false;
    });
  }
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
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      }
      
      // Reload all bus stops and routes
      if (busScheduleData != null) {
        for (var route in busScheduleData!['routes']) {
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
      }
    });
  }

  void _suggestNearestBusStation() {
    if (currentLocation == null) return;

    double minDistance = double.infinity;
    Marker? nearestMarker;

    for (var marker in _markers) {
      // Skip current location marker
      if (marker.markerId.value == 'currentLocation') continue;
      
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
        CameraUpdate.newLatLngZoom(nearestMarker.position, 15),
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
                Text('Distance: ${minDistance.toStringAsFixed(2)} km'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.favorite),
                      label: Text('Add to Favorites'),
                      onPressed: () {
                        if (nearestMarker != null) {
                          _toggleFavorite(nearestMarker.infoWindow.title!);
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    ),
                  ],
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
              Expanded(child: Text(stop['name'], overflow: TextOverflow.ellipsis)),
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
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All Departures:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final departure = trip['departures'].firstWhere(
                        (d) => d['stop'] == stop['name'],
                        orElse: () => null,
                      );
                      
                      if (departure != null) {
                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.directions_bus),
                            title: Text('Trip ${trip['tripNumber']}'),
                            subtitle: Text('Departure: ${departure['time']}'),
                          ),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
            ),
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

  void _toggleFavorite(String stopName) {
    setState(() {
      if (favoriteStops.contains(stopName)) {
        favoriteStops.remove(stopName);
      } else {
        favoriteStops.add(stopName);
      }
    });
  }

  void _searchRoutes(String query) {
    if (busScheduleData == null) return;
    
    setState(() {
      if (query.isEmpty) {
        filteredRoutes = List.from(busScheduleData!['routes']); // Reset to all routes
        _resetMap(); // Show all routes on map
      } else {
        filteredRoutes = busScheduleData!['routes']
            .where((route) => 
                route['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                (route['stops'] as List).any((stop) => 
                    stop['name'].toString().toLowerCase().contains(query.toLowerCase())))
            .toList();
        
        // If we have filtered routes, show the first one on the map
        if (filteredRoutes.isNotEmpty) {
          final firstRoute = filteredRoutes[0];
          if (firstRoute['trips'] != null && firstRoute['trips'].isNotEmpty) {
            _showTripOnMap(firstRoute, firstRoute['trips'][0]);
          }
        }
      }
    });
  }

  void _showTripOnMap(Map<String, dynamic> route, Map<String, dynamic> trip) {
    // Clear existing markers and polylines
    setState(() {
      _markers.clear();
      _polylines.clear();
      
      // Add current location marker if available
      if (currentLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: currentLocation!,
            infoWindow: const InfoWindow(title: 'You are here'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      }
      
      // Add markers for each stop in the selected route
      for (var stop in route['stops']) {
        final departure = trip['departures'].firstWhere(
          (d) => d['stop'] == stop['name'], 
          orElse: () => null
        );
        
        _markers.add(
          Marker(
            markerId: MarkerId(stop['name']),
            position: LatLng(stop['lat'], stop['lng']),
            infoWindow: InfoWindow(
              title: stop['name'],
              snippet: 'Next Trip: ${departure != null ? departure['time'] : 'N/A'}',
              onTap: () {
                _showStopDetails(stop, [trip]);
              },
            ),
            icon: favoriteStops.contains(stop['name']) 
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }

      // Add polyline for the selected route
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
    });
    
    // Focus the map on the route
    if (route['stops'].isNotEmpty) {
      LatLngBounds bounds = _getBoundsForRoute(route);
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
    
    // Partially collapse the panel to show more of the map
    _panelController.animatePanelToPosition(0.4);
  }

  // Helper method to get bounds for a route
  LatLngBounds _getBoundsForRoute(Map<String, dynamic> route) {
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    
    for (var stop in route['stops']) {
      double lat = stop['lat'];
      double lng = stop['lng'];
      
      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // Helper method to zoom the map to fit all routes
  void _zoomToFitAllRoutes(List<dynamic> routes) {
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    
    for (var route in routes) {
      for (var stop in route['stops']) {
        double lat = stop['lat'];
        double lng = stop['lng'];
        
        minLat = min(minLat, lat);
        maxLat = max(maxLat, lat);
        minLng = min(minLng, lng);
        maxLng = max(maxLng, lng);
      }
    }
    
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
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
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              _showFavoriteStops();
            },
          ),
        ],
      ),
      body: isLoading 
          ? Center(child: CircularProgressIndicator())
          : SlidingUpPanel(
              controller: _panelController,
              panel: _buildSlidingPanel(),
              collapsed: _buildCollapsedPanel(),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
              minHeight: 60,
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
                mapToolbarEnabled: true,
                zoomControlsEnabled: true,
              ),
            ),
    );
  }

  void _showFavoriteStops() {
    if (favoriteStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No favorite stops added yet')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Favorite Bus Stops'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: favoriteStops.length,
              itemBuilder: (context, index) {
                final stopName = favoriteStops.elementAt(index);
                return ListTile(
                  leading: Icon(Icons.favorite, color: Colors.red),
                  title: Text(stopName),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _toggleFavorite(stopName);
                      Navigator.of(context).pop();
                      _showFavoriteStops();
                    },
                  ),
                  onTap: () {
                    // Find the stop and show it on map
                    _focusOnStop(stopName);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
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
  
  void _focusOnStop(String stopName) {
    if (busScheduleData == null) return;
    
    for (var route in busScheduleData!['routes']) {
      for (var stop in route['stops']) {
        if (stop['name'] == stopName) {
          mapController.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(stop['lat'], stop['lng']), 16),
          );
          
          // Highlight this stop
          setState(() {
            _markers.clear();
            _polylines.clear();
            
            // Add current location marker if available
            if (currentLocation != null) {
              _markers.add(
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: currentLocation!,
                  infoWindow: const InfoWindow(title: 'You are here'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
              );
            }
            
            // Add the favorite stop marker
            _markers.add(
              Marker(
                markerId: MarkerId(stopName),
                position: LatLng(stop['lat'], stop['lng']),
                infoWindow: InfoWindow(
                  title: stopName,
                  snippet: 'Favorite Stop',
                  onTap: () {
                    _showStopDetails(stop, route['trips']);
                  },
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
              ),
            );
            
            // Add route polyline
            final List<LatLng> routeCoordinates = route['stops']
                .map<LatLng>((s) => LatLng(s['lat'], s['lng']))
                .toList();

            _polylines.add(
              Polyline(
                polylineId: PolylineId(route['id']),
                points: routeCoordinates,
                color: Colors.purple,
                width: 5,
              ),
            );
          });
          
          return;
        }
      }
    }
  }

  Widget _buildSlidingPanel() {
    return Column(
      children: [
        // Handle to drag the panel
        Container(
          height: 5,
          width: 40,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: _searchRoutes,
          ),
        ),
        
        Expanded(
          child: busScheduleData == null 
              ? const Center(child: CircularProgressIndicator())
              : filteredRoutes.isEmpty
                  ? Center(child: Text('No routes found. Try a different search.'))
                  : ListView.builder(
                      itemCount: filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final route = filteredRoutes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ExpansionTile(
                            title: Text(
                              route['name'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${route['stops'].length} stops'),
                            children: route['trips'].map<Widget>((trip) {
                              return ListTile(
                                title: Text('Trip ${trip['tripNumber']}'),
                                subtitle: Text(
                                  'Departure: ${trip['departures'][0]['time']}',
                                ),
                                trailing: Icon(Icons.directions_bus),
                                onTap: () {
                                  _showTripOnMap(route, trip);
                                },
                              );
                            }).toList(),
                          ),
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
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              width: 40,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Swipe up for Bus Schedule',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}