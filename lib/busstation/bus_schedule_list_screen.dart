import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'bus_route_detail_screen.dart';
import 'bus_map_overview_screen.dart';

class BusScheduleListScreen extends StatefulWidget {
  const BusScheduleListScreen({super.key});

  @override
  _BusScheduleListScreenState createState() => _BusScheduleListScreenState();
}

class _BusScheduleListScreenState extends State<BusScheduleListScreen> {
  late Map<String, dynamic> scheduleData;
  List<dynamic> filteredRoutes = [];
  String searchQuery = '';
  String selectedFilter = 'All';
  Set<String> favoriteRoutes = {};
  bool isLoading = true;
  List<String> generalNotes = [];

  @override
  void initState() {
    super.initState();
    _loadBusSchedule();
  }

  Future<void> _loadBusSchedule() async {
    try {
      final String response = await rootBundle.loadString('assets/json/bus_schedule.json');
      final data = json.decode(response);
      setState(() {
        scheduleData = data;
        filteredRoutes = List.from(data['routes']);
        generalNotes = List.from(data['generalNotes']);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading JSON file: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterRoutes(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredRoutes = List.from(scheduleData['routes']);
      } else {
        filteredRoutes = scheduleData['routes'].where((route) {
          final nameMatch = route['name'].toString().toLowerCase().contains(query.toLowerCase());
          final stopMatch = route['stops'].any((stop) => 
              stop.toString().toLowerCase().contains(query.toLowerCase()));
          return nameMatch || stopMatch;
        }).toList();
      }
      _applyFilter(selectedFilter);
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == 'All') {
        filteredRoutes = List.from(scheduleData['routes'].where((route) => 
            searchQuery.isEmpty ? true : 
            route['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
            route['stops'].any((stop) => 
                stop.toString().toLowerCase().contains(searchQuery.toLowerCase()))));
      } else if (filter == 'Favorites') {
        filteredRoutes = scheduleData['routes'].where((route) => 
            favoriteRoutes.contains(route['id']) &&
            (searchQuery.isEmpty ? true : 
             route['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))).toList();
      } else if (filter == 'Depart from UTAR') {
        filteredRoutes = scheduleData['routes'].where((route) => 
            route['stops'].first.toString().contains('UTAR') &&
            (searchQuery.isEmpty ? true : 
             route['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))).toList();
      }
    });
  }

  void _toggleFavorite(String routeId) {
    setState(() {
      if (favoriteRoutes.contains(routeId)) {
        favoriteRoutes.remove(routeId);
      } else {
        favoriteRoutes.add(routeId);
      }
      if (selectedFilter == 'Favorites') {
        _applyFilter('Favorites');
      }
    });
  }

  void _showGeneralNotes() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('General Notes'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Last Updated: ${scheduleData['lastUpdated']}'),
                Text('Effective Date: ${scheduleData['effectiveDate']}'),
                Text('Trimester: ${scheduleData['trimester']}'),
                const SizedBox(height: 16),
                ...generalNotes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• $note'),
                )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
        title: const Text('UTAR Bus Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGeneralNotes,
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusMapOverviewScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Location header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheduleData['campusName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scheduleData['trimester'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search bus routes or stops',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: _filterRoutes,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Favorites'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Depart from UTAR'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Route list
                Expanded(
                  child: filteredRoutes.isEmpty
                      ? const Center(child: Text('No routes found'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: filteredRoutes.length,
                          itemBuilder: (context, index) {
                            final route = filteredRoutes[index];
                            return _buildRouteCard(route, context);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: selectedFilter == label,
      onSelected: (selected) => _applyFilter(label),
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selectedFilter == label ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusRouteDetailScreen(route: route),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      route['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      favoriteRoutes.contains(route['id'])
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: favoriteRoutes.contains(route['id'])
                          ? Colors.red
                          : Colors.grey,
                    ),
                    onPressed: () {
                      _toggleFavorite(route['id']);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (route['stops'] != null && route['stops'].isNotEmpty)
                Text(
                  '${route['stops'].first} to ${route['stops'].last}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: route['trips'].take(3).map<Widget>((trip) {
                  return Chip(
                    label: Text('Trip ${trip['tripNumber']} - ${trip['departures'][0]['time']}'),
                    backgroundColor: Colors.blue[100],
                  );
                }).toList(),
              ),
              if (route['notes'] != null && route['notes'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Note: ${route['notes'][0]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}