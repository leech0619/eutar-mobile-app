import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bus_route_detail_screen.dart';
import 'bus_map_overview_screen.dart';
import '../Controller/favouriteRouteService.dart';
import '../model/favouriteRoute.dart';

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
  late FavoriteRouteService _favoriteService;
  StreamSubscription<Set<String>>? _favoritesSubscription;

  @override
  void initState() {
    super.initState();
    _favoriteService = FavoriteRouteService();
    _loadBusSchedule();
    _setupFavoritesListener();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  void _setupFavoritesListener() {
    _favoritesSubscription = _favoriteService.getFavoriteRouteIds().listen((favorites) {
      if (mounted) {
        setState(() {
          favoriteRoutes = favorites;
          if (selectedFilter == 'Favorites') {
            _applyFilter('Favorites');
          }
        });
      }
    });
  }

  Future<void> _loadBusSchedule() async {
    try {
      final String response = await rootBundle.loadString('assets/json/bus_schedule.json');
      final data = json.decode(response);
      if (mounted) {
        setState(() {
          scheduleData = data;
          filteredRoutes = List.from(data['routes']);
          generalNotes = List.from(data['generalNotes'] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading JSON file: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _filterRoutes(String query) {
    setState(() {
      searchQuery = query;
      
      if (scheduleData == null || scheduleData['routes'] == null) return;
      
      if (query.isEmpty) {
        filteredRoutes = List.from(scheduleData['routes']);
      } else {
        filteredRoutes = scheduleData['routes'].where((route) {
          final nameMatch = route['name'].toString().toLowerCase().contains(query.toLowerCase());
          final stopMatch = route['stops']?.any((stop) => 
              stop.toString().toLowerCase().contains(query.toLowerCase())) ?? false;
          return nameMatch || stopMatch;
        }).toList();
      }
      _applyFilter(selectedFilter);
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      
      if (scheduleData == null || scheduleData['routes'] == null) return;
      
      if (filter == 'All') {
        filteredRoutes = scheduleData['routes'].where((route) => 
            searchQuery.isEmpty ? true : 
            route['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
            route['stops']?.any((stop) => 
                stop.toString().toLowerCase().contains(searchQuery.toLowerCase())) ?? false).toList();
      } else if (filter == 'Favorites') {
        filteredRoutes = scheduleData['routes'].where((route) => 
            favoriteRoutes.contains(route['id']) &&
            (searchQuery.isEmpty ? true : 
             route['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))).toList();
      } 
    });
  }

  Future<void> _toggleFavorite(String routeId) async {
    try {
      final isFavorite = favoriteRoutes.contains(routeId);
      await _favoriteService.toggleFavorite(routeId, isFavorite);
      
      // No need to update state here as we have a stream listener
      // that will automatically update the UI when Firestore changes
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorites: $e')),
      );
    }
  }

  void _showGeneralNotes() {
    if (scheduleData == null) return;
    
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
                Text('Last Updated: ${scheduleData['lastUpdated'] ?? 'N/A'}'),
                Text('Effective Date: ${scheduleData['effectiveDate'] ?? 'N/A'}'),
                Text('Trimester: ${scheduleData['trimester'] ?? 'N/A'}'),
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
        backgroundColor: Colors.blue,
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
                        scheduleData['campusName'] ?? 'Campus',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scheduleData['trimester'] ?? 'Current Term',
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
                      _buildFilterChip('Favorites')
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
    final routeId = route['id']?.toString() ?? '';
    final isFavorite = favoriteRoutes.contains(routeId);
    
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
              // Route Name and Favorite Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      route['name'] ?? 'Unknown Route',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () {
                      _toggleFavorite(routeId);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
  
              // Stops (First to Last)
              if (route['stops'] != null && (route['stops'] as List).isNotEmpty)
                Text(
                  '${route['stops'].first} to ${route['stops'].last}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              const SizedBox(height: 12),
  
              // Total Trips
              Text(
                'Total Trips: ${(route['trips'] as List?)?.length ?? 0}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
  
              // Notes (if available)
              if (route['notes'] != null && (route['notes'] as List).isNotEmpty)
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