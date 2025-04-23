import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl package for date formatting: flutter pub add intl
import '../model/resource_model.dart';
import '../controller/resource_controller.dart'; // To call download

class ResourceDetailScreen extends StatelessWidget {
  final Resource resource;
  final ResourceController _controller = ResourceController(); // Instantiate controller

  ResourceDetailScreen({Key? key, required this.resource}) : super(key: key);

  // Helper function for date formatting
  String _formatDate(DateTime date) {
    // Using intl package for better formatting
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(resource.title), // Show resource title in AppBar
        backgroundColor: Colors.blueAccent,
         foregroundColor: Colors.white, // Make title and back button white
      ),
      body: SingleChildScrollView( // Allow scrolling if content is long
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title ---
            Text(
              resource.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // --- Description ---
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              resource.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),

             // --- Tags ---
            if (resource.tags.isNotEmpty) ...[
              Text(
                'Tags:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: resource.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                )).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // --- Metadata ---
            Divider(height: 20, thickness: 1),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.person_outline, 'Uploaded by:', resource.uploadedByName.isNotEmpty ? resource.uploadedByName : 'Unknown'), // Display uploaderId. Ideally fetch user name.
            const SizedBox(height: 10),
            _buildInfoRow(Icons.calendar_today_outlined, 'Uploaded on:', _formatDate(resource.uploadDate)),
             const SizedBox(height: 10),
             _buildInfoRow(Icons.file_present_outlined, 'File Name:', resource.fileName), // Display original file name
            const SizedBox(height: 30),

            // --- Download Button ---
            Center( // Center the download button
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download, color: Colors.white,),
                label: const Text('Download File'),
                onPressed: () {
                  // Add a confirmation or direct download
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Initiating download for ${resource.fileName}...'))
                  );
                  _controller.downloadFile(resource,context); // Call controller method
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Use a distinct color for download
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20), // Add some padding at the bottom
          ],
        ),
      ),
    );
  }

  // Helper widget for consistent info rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 10),
        Text(
          '$label ',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ),
        Expanded( // Allow value text to wrap if long
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade900),
            overflow: TextOverflow.ellipsis, // Show ellipsis if too long on one line
          ),
        ),
      ],
    );
  }
}