import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class BusRouteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> route;

  const BusRouteDetailScreen({super.key, required this.route});

  @override
  _BusRouteDetailScreenState createState() => _BusRouteDetailScreenState();
}

class _BusRouteDetailScreenState extends State<BusRouteDetailScreen> {
  // Make mapController nullable
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  int _selectedTripIndex = 0;
  // Removed _showAllStops as it wasn't used

  // initState is now simpler, no need to call _showRouteOnMap here
  @override
  void initState() {
    super.initState();
    // Data validation (optional but recommended)
    _validateRouteData();
  }
  Future<void> _initializeMap() async {
  try {
    // Your async initialization logic
    debugPrint("Initializing map...");
    await Future.delayed(const Duration(seconds: 1)); // Simulate delay
    debugPrint("Map initialized.");
  } catch (e) {
    debugPrint("Error initializing map: $e");
  }
}
  // Helper to validate incoming data structure (optional but good practice)
  void _validateRouteData() {
    if (widget.route['trips'] is! List ||
        (widget.route['trips'] as List).isEmpty) {
      debugPrint("Warning: Route data has missing or invalid 'trips'.");
      // Handle this case appropriately, maybe show an error message to the user
    }
    // Add more checks as needed based on your expected data structure
  }

  void _showRouteOnMap() {
    // Check if mounted and if mapController is initialized
    if (!mounted || mapController == null) return;

    // Ensure trips data is valid before proceeding
    final trips = widget.route['trips'];
    if (trips is! List || trips.isEmpty || _selectedTripIndex >= trips.length) {
      debugPrint('Error: Invalid trips data or selected index out of bounds.');
      // Optionally clear map and show feedback
      setState(() {
        _markers.clear();
        _polylines.clear();
      });
      return;
    }

    try {
      setState(() {
        _markers.clear();
        _polylines.clear();

        // Get the selected trip safely
        final selectedTripData = trips[_selectedTripIndex];
        if (selectedTripData is! Map<String, dynamic>) {
          debugPrint('Error: selectedTripData is not a Map.');
          return;
        }
        final selectedTrip = selectedTripData; // Now we know it's a Map

        final departures = selectedTrip['departures'];
        // Basic validation for departures
        if (departures is! List ||
            departures.isEmpty ||
            departures[0] is! Map<String, dynamic> ||
            departures[0]['stop'] == null) {
          debugPrint('Error: Invalid departures structure in selected trip.');
          // Handle error: maybe show a default state or message
          return;
        }
        final firstStopData = departures[0]['stop'];
        final firstStop = firstStopData.toString(); // Use toString for safety

        // --- Determine Direction and Order Stops ---
        final stopsRaw = widget.route['stops'];
        if (stopsRaw is! List) {
          debugPrint("Error: 'stops' data is not a List.");
          return; // Stop processing if stops data is invalid
        }
        // Filter out non-string stops for safety
        final allStops = stopsRaw.whereType<String>().toList();

        final isDepartingFromUTAR = firstStop.contains('UTAR');
        List<String> orderedStops = [];

        final utarStops =
            allStops.where((stop) => stop.contains('UTAR')).toList();
        final housingStops =
            allStops.where((stop) => !stop.contains('UTAR')).toList();

        // Define sorting order maps
        const Map<String, int> utarOrderDepart = {
          'UTAR Block D': 1,
          'UTAR Block G': 2,
          'UTAR Block N': 3,
        };
        const Map<String, int> utarOrderArrive = {
          'UTAR Block N': 1,
          'UTAR Block G': 2,
          'UTAR Block D': 3,
        };

        if (isDepartingFromUTAR) {
          // Sort UTAR stops D -> G -> N
          utarStops.sort(
            (a, b) =>
                (utarOrderDepart[a] ?? 99).compareTo(utarOrderDepart[b] ?? 99),
          ); // Use default high value for unknowns
          orderedStops = [...utarStops, ...housingStops];
        } else {
          // Sort UTAR stops N -> G -> D (Reverse logic applies here)
          utarStops.sort(
            (a, b) =>
                (utarOrderArrive[a] ?? 99).compareTo(utarOrderArrive[b] ?? 99),
          ); // Use default high value for unknowns
          orderedStops = [...housingStops, ...utarStops];
        }
        // --- End Direction and Order Stops ---

        // --- Add Markers ---
        if (orderedStops.isEmpty) {
          debugPrint("Warning: No ordered stops to display.");
          return; // Don't proceed if no stops
        }

        for (int i = 0; i < orderedStops.length; i++) {
          final stop = orderedStops[i];
          _markers.add(
            Marker(
              markerId: MarkerId(
                stop + i.toString(),
              ), // Add index for potential duplicate names
              position: _getLocationForStop(stop),
              infoWindow: InfoWindow(title: stop),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                i == 0
                    ? BitmapDescriptor
                        .hueGreen // First stop
                    : i == orderedStops.length - 1
                    ? BitmapDescriptor
                        .hueRed // Last stop
                    : BitmapDescriptor.hueBlue, // Intermediate stops
              ),
            ),
          );
        }
        // --- End Add Markers ---

        // --- Add Polyline ---
        final List<LatLng> routeCoordinates =
            orderedStops
                .map<LatLng>((stop) => _getLocationForStop(stop))
                .toList();

        if (routeCoordinates.length >= 2) {
          // Need at least 2 points for a polyline
          _polylines.add(
            Polyline(
              polylineId: PolylineId(
                widget.route['id']?.toString() ??
                    'default_route_${DateTime.now().millisecondsSinceEpoch}',
              ), // Ensure unique ID
              points: routeCoordinates,
              color: Colors.deepPurple, // Changed color slightly
              width: 5,
            ),
          );
        } else {
          debugPrint(
            "Warning: Not enough points (${routeCoordinates.length}) to draw a polyline.",
          );
        }
        // --- End Add Polyline ---
      }); // End of setState

      // Animate camera after state is updated and map potentially rebuilt
      Future.delayed(const Duration(milliseconds: 300), () {
        // Check mounted and mapController again, as delay occurred
        if (mounted && mapController != null && _markers.isNotEmpty) {
          try {
            mapController!.animateCamera(
              // Use ! because we checked for null
              CameraUpdate.newLatLngBounds(
                _getBoundsForMarkers(_markers),
                100.0, // Padding
              ),
            );
          } catch (e) {
            debugPrint('Error animating camera: $e');
          }
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error in _showRouteOnMap: $e\n$stackTrace');
      // Optionally show an error message to the user
    }
  }

  LatLng _getLocationForStop(String stopName) {
    // (Your _getLocationForStop implementation remains the same)
    switch (stopName) {
      // UTAR Campus Stops (verified approximate coordinates)
      case 'UTAR Block D':
        return const LatLng(
          4.338115104744316,
          101.1438004149668,
        ); // Near Faculty of Engineering 4.338115104744316, 101.1438004149668
      case 'UTAR Block G':
        return const LatLng(
          4.340407678390168,
          101.14358161247885,
        ); // Near Faculty of Science 4.340407678390168, 101.14358161247885
      case 'UTAR Block N':
        return const LatLng(
          4.338909947691619,
          101.13661859791222,
        ); // Near Faculty of Arts/Social Science 4.338909947691619, 101.13661859791222

      // Housing Areas (Kampar)
      case 'Stanford Bus Stop':
        return const LatLng(
          4.326598839352191,
          101.13491463433371,
        ); // Near Stanford Apartment entrance 4.326598839352191, 101.13491463433371
      case 'V2 Optical Shop':
        return const LatLng(
          4.3262801748307735,
          101.14343490343325,
        ); // Exact shop location 4.3262801748307735, 101.14343490343325
      case 'Taman Mahsuri Impian':
        return const LatLng(
          4.328170722263601,
          101.1511850798773,
        ); // Main entrance bus stop 4.328170722263601, 101.1511850798773
      case 'Harvard & Cambridge':
        return const LatLng(
          4.3308804452733725,
          101.13231301152658,
        ); // Between the two residences 4.3308804452733725, 101.13231301152658
      case 'Westlake 1':
        return const LatLng(
          4.329125938362558,
          101.13656163046677,
        ); // Westlake main bus stop got 3: 4.329125938362558, 101.13656163046677 / 4.329897666191284, 101.13918033684243 / 4.33078070699843, 101.13639460717039
      case 'Westlake 2':
        return const LatLng(4.329897666191284, 101.13918033684243);
      case 'Westlake 3':
        return const LatLng(4.33078070699843, 101.13639460717039);
      case 'Champs Elysees/The Trails':
        return const LatLng(
          4.319810902677306,
          101.12434723845445,
        ); // Near security post 4.319810902677306, 101.12434723845445

      default:
        debugPrint(
          "Warning: Unknown stop name '$stopName', using default location.",
        );
        // Consider logging unknown stop names to identify data issues
        return const LatLng(
          4.3328,
          101.1236,
        ); // Default to UTAR main entrance (or maybe Kampar town center?)
    }
  }

  LatLngBounds _getBoundsForMarkers(Set<Marker> markers) {
    if (markers.isEmpty) {
      // Return a default bound if no markers exist, e.g., centered on UTAR
      return LatLngBounds(
        southwest: const LatLng(4.330, 101.130),
        northeast: const LatLng(4.340, 101.140),
      );
    }

    // Original bounding box calculation logic is fine
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (var marker in markers) {
      minLat = min(minLat, marker.position.latitude);
      maxLat = max(maxLat, marker.position.latitude);
      minLng = min(minLng, marker.position.longitude);
      maxLng = max(maxLng, marker.position.longitude);
    }

    // Add a small padding if southwest and northeast are the same (single marker)
    if (minLat == maxLat && minLng == maxLng) {
      const padding = 0.001;
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Safe Access to Selected Trip ---
    final trips = widget.route['trips'];
    Map<String, dynamic>? selectedTrip; // Make it nullable initially

    if (trips is List &&
        trips.isNotEmpty &&
        _selectedTripIndex < trips.length) {
      final tripData = trips[_selectedTripIndex];
      if (tripData is Map<String, dynamic>) {
        selectedTrip = tripData;
      } else {
        debugPrint(
          "Error: Selected trip data at index $_selectedTripIndex is not a Map.",
        );
      }
    } else {
      debugPrint(
        "Error: Invalid 'trips' data or selected index $_selectedTripIndex out of bounds.",
      );
    }
    // --- End Safe Access ---

    // Handle case where selectedTrip couldn't be loaded
    if (selectedTrip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bus Schedule')),
        body: const Center(
          child: Text('Error loading trip details. Please check the data.'),
        ),
      );
    }

    // Now we know selectedTrip is a valid Map<String, dynamic>
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Schedule'), // Use null check
      ),
      body: Column(
        children: [
          // Map section
          Expanded(
            flex: 2,
            child: // Replace the GoogleMap widget in the build method with this updated version
GoogleMap(
  onMapCreated: (GoogleMapController controller) {
    // Assign the controller
    mapController = controller;
    
    // Delay to ensure the map is fully initialized before trying to show the route
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild and ensure map is ready
        });
        _showRouteOnMap();
      }
    });
  },
  initialCameraPosition: const CameraPosition(
    target: LatLng(4.3331, 101.1345), // UTAR Kampar center
    zoom: 14.0,
  ),
  markers: _markers,
  polylines: _polylines,
  myLocationEnabled: true,
  myLocationButtonEnabled: true,
  // Add these parameters to fix the dark mode issues
  mapType: MapType.normal,
  compassEnabled: true,
  zoomControlsEnabled: true,
),
          ),

          // Route details section
          Expanded(
            flex: 4, // Give details slightly more space perhaps
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [Tab(text: 'Schedule'), Tab(text: 'Stops')],
                    labelColor:
                        Theme.of(
                          context,
                        ).colorScheme.primary, // Use ColorScheme
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Schedule Tab - Pass the non-null selectedTrip
                        _buildScheduleTab(selectedTrip),

                        // Stops Tab
                        _buildStopsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildScheduleTab(Map<String, dynamic> selectedTrip) {
    // Safely access data within selectedTrip and widget.route
    final allTripsData = widget.route['trips'];
    final departuresData = selectedTrip['departures'];
    final arrivalData = selectedTrip['arrival']; // Keep raw data first
    final notesData = widget.route['notes'];

    // Use .whereType for safer list handling
    final allTrips =
        (allTripsData is List)
            ? allTripsData.whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];
    final departures =
        (departuresData is List)
            ? departuresData.whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];
    final notes =
        (notesData is List)
            ? notesData.whereType<String>().toList()
            : <String>[];

    // Safely handle arrival data
    final arrivals =
        (arrivalData is List)
            ? arrivalData.whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          Text(
            widget.route['name'] ?? 'Unknown Route',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Available Trips Section
          if (allTrips.isNotEmpty) ...[
            const Text(
              'Available Trips:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8, // Allow multiple rows
              children: List.generate(allTrips.length, (index) {
                final trip = allTrips[index];
                final tripNumber =
                    trip['tripNumber']?.toString() ?? 'Trip ${index + 1}';
                return ChoiceChip(
                  label: Text(tripNumber),
                  selected: _selectedTripIndex == index,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTripIndex = index;
                        _showRouteOnMap();
                      });
                    }
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          // Blocks Section
          Text(
            'Blocks: ${selectedTrip['blocks']?.toString() ?? 'N/A'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Departure Times Section
          const Text(
            'Departure Times:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (departures.isEmpty)
            const ListTile(title: Text('No departure times listed.'))
          else
            ...departures.map<Widget>((departure) {
              final stopName = departure['stop']?.toString() ?? 'Unknown Stop';
              final time = departure['time']?.toString() ?? '-';
              return ListTile(
                leading: const Icon(Icons.departure_board),
                title: Text(stopName),
                trailing: Text(time),
                dense: true,
              );
            }).toList(),
          const SizedBox(height: 16),

          // Arrival Times Section
          const Text(
            'Arrival Times:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (arrivals.isEmpty)
            const ListTile(title: Text('No arrival times listed.'))
          else
            ...arrivals.map<Widget>((arrival) {
              final stopName = arrival['stop']?.toString() ?? 'Unknown Stop';
              final time = arrival['time']?.toString() ?? '-';
              return ListTile(
                leading: const Icon(Icons.flag),
                title: Text(stopName),
                trailing: Text(time),
                dense: true,
              );
            }).toList(),
          const SizedBox(height: 16),

          // Special Note Section
          if (selectedTrip['specialNote'] != null &&
              selectedTrip['specialNote'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Note: ${selectedTrip['specialNote']}',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Route Notes Section
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Route Notes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...notes
                .map<Widget>(
                  (note) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $note'),
                  ),
                )
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStopsTab() {
    // Safely access stops data
    final stopsData = widget.route['stops'];
    final stopsToShow =
        (stopsData is List)
            ? stopsData.whereType<String>().toList()
            : <String>[];

    if (stopsToShow.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No stops listed for this route."),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: stopsToShow.length,
      itemBuilder: (context, index) {
        final stop = stopsToShow[index];
        final bool isFirst = index == 0;
        final bool isLast = index == stopsToShow.length - 1;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 2, // Add subtle shadow
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isFirst
                      ? Colors.greenAccent[700] // Darker green
                      : isLast
                      ? Colors.redAccent[700] // Darker red
                      : Theme.of(
                        context,
                      ).colorScheme.secondary, // Use theme color
              foregroundColor: Colors.white, // Ensure text is white
              child: Text('${index + 1}'),
            ),
            title: Text(stop),
            subtitle:
                isFirst
                    ? const Text(
                      'Starting Point',
                      style: TextStyle(color: Colors.green),
                    )
                    : isLast
                    ? const Text(
                      'Terminal Point',
                      style: TextStyle(color: Colors.red),
                    )
                    : null,
            trailing: IconButton(
              icon: Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
              ), // Theme color
              tooltip: 'Show on map', // Add tooltip
              onPressed: () {
                // Use local variable and null check for safety
                final controller = mapController;
                if (controller != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      _getLocationForStop(stop),
                      16.5,
                    ), // Zoom in a bit more
                  );
                } else {
                  // Optionally show a message if map isn't ready
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Map is initializing...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
  

  @override
  void dispose() {
    // Safely dispose the controller using the null-aware operator
    mapController?.dispose();
    super.dispose();
  }
}
