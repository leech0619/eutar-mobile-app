// --- Imports ---
// Provides access to platform-specific features like File handling.
import 'dart:io';
// Provides the core Flutter widgets (MaterialApp, Scaffold, Text, etc.).
import 'package:flutter/material.dart';
// Imports the data model for a Resource. Assumed to define the Resource class.
import '../model/resource_model.dart';
// Imports the controller handling business logic (fetching, searching, uploading).
import '../controller/resource_controller.dart';
// Imports the screen used to display details of a single resource.
import 'resource_detail_screen.dart';

// --- StatefulWidget Definition ---
// ResourceScreen is a StatefulWidget because its content needs to change
// based on user interaction (searching, uploading, fetching data).
class ResourceScreen extends StatefulWidget {
  // Constructor with an optional Key. const improves performance.
  const ResourceScreen({Key? key}) : super(key: key);

  // Creates the mutable state for this widget.
  @override
  _ResourceScreenState createState() => _ResourceScreenState();
}

// --- State Class Definition ---
// Holds the mutable state and logic for the ResourceScreen.
class _ResourceScreenState extends State<ResourceScreen> {
  // --- State Variables ---

  // Instance of the controller to interact with resource data logic.
  // final means it's initialized once and cannot be reassigned.
  final ResourceController _controller = ResourceController();

  // Controller for the search input field. Manages the text value.
  final TextEditingController _searchController = TextEditingController();

  // Controller for the 'Title' input field in the share tab.
  final TextEditingController _titleController = TextEditingController();
  // Controller for the 'Description' input field in the share tab.
  final TextEditingController _descriptionController = TextEditingController();
  // Controller for the 'Tags' input field in the share tab.
  final TextEditingController _tagsController = TextEditingController();

  // Holds the results of a search query. Null if no search is active.
  List<Resource>? _searchResults;
  // Holds the file selected by the user for uploading. Null if no file is selected.
  File? _selectedFile;
  // Flag to indicate if an upload operation is currently in progress.
  bool _isUploading = false;

  // GlobalKey associated with the Form widget in the 'Share' tab.
  // Used to validate and manage the form's state.
  final _formKey = GlobalKey<FormState>();

  // --- Lifecycle Methods ---

  @override
  void dispose() {
    // Clean up controllers when the widget is removed from the widget tree
    // to prevent memory leaks.
    _searchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose(); // Always call super.dispose() at the end.
  }

  // --- Event Handlers & Logic Methods ---

  // Performs a search based on the text in the search input field.
  Future<void> _handleSearch() async {
    // Get the search query, removing leading/trailing whitespace.
    final query = _searchController.text.trim();

    // If the query is empty, clear search results and show all resources.
    if (query.isEmpty) {
      // Check if the widget is still mounted before calling setState.
      if (mounted) {
        setState(() => _searchResults = null);
      }
      return;
    }

    // Call the controller to perform the search asynchronously.
    final results = await _controller.searchResources(query);


    if (mounted) {
      setState(() => _searchResults = results);
    }
  }

  // Opens a file picker for the user to select a file.
  Future<void> _pickFile() async {
    // Call the controller's method to handle file picking logic.
    final file = await _controller.pickFile();
    // If a file was successfully picked...
    if (file != null) {
      // Update the state to store the selected file, triggering a UI rebuild.
      // Check if the widget is still mounted before calling setState.
      if (mounted) {
        setState(() => _selectedFile = file);
      }
    }
  }

  // Handles the resource upload process.
  Future<void> _uploadResource() async {
    // 1. Validate the form fields using the GlobalKey.
    // 2. Check if a file has been selected.
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      // Set the uploading flag to true to show progress indicator and disable button.
      // Check if the widget is still mounted before calling setState.
      if (mounted) {
        setState(() => _isUploading = true);
      }

      // Process tags: split by comma, trim whitespace, remove empty tags.
      final tags =
          _tagsController.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();

      // Call the controller to handle the actual upload logic.
      final success = await _controller.uploadResource(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: tags,
        file:
            _selectedFile!, // Use ! because we already checked _selectedFile != null
      );

      // After upload attempt, update the UI based on success/failure.
      // Check if the widget is still mounted before calling setState.
      if (mounted) {
        setState(() {
          _isUploading = false; // Hide progress indicator
          if (success) {
            // Clear form and selected file on successful upload.
            _selectedFile = null;
            _titleController.clear();
            _descriptionController.clear();
            _tagsController.clear();
            // Show a success message.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Resource uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Potentially refresh the resource list or switch tabs here if desired.
          } else {
            // Show an error message.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload resource. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    } else if (_selectedFile == null) {
      // Show a message if the user tries to upload without selecting a file.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file to upload.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    // If form validation fails, the validator messages in TextFormFields will be shown automatically.
  }

  // --- Build Method ---
  // Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context) {
    // DefaultTabController coordinates the TabBar and TabBarView.
    // 'length: 2' corresponds to the two tabs ('Browse' and 'Share').
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          // Sets the background color of the AppBar.
          backgroundColor: Colors.blueAccent,
          // Sets the title text displayed in the AppBar.
          title: const Text(
            'Resources',
            // Styles the title text (white color, specific font size).
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          // The bottom part of the AppBar, used here to hold the TabBar.
          bottom: const TabBar(
            // Color of the selected tab's text and icon.
            labelColor: Colors.white,
            // Color of the unselected tabs' text and icons.
            unselectedLabelColor: Colors.white70,
            // Indicator (the line below the active tab) color.
            indicatorColor: Colors.white,
            // Defines the tabs themselves.
            tabs: [
              Tab(text: 'Browse Resources', icon: Icon(Icons.search)),
              Tab(text: 'Share Resource', icon: Icon(Icons.upload_file)),
            ],
          ),
          // Ensures the title is centered if desired (platform dependent otherwise).
          centerTitle: true,
        ),
        // Body of the Scaffold, containing the content for each tab.
        body: TabBarView(
          // The children widgets correspond to the tabs defined in the TabBar.
          children: [
            // Content for the first tab ('Browse Resources').
            _buildBrowseTab(),
            // Content for the second tab ('Share Resource').
            _buildShareTab(),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  // Builds the UI for the 'Browse Resources' tab.
  Widget _buildBrowseTab() {
    return Column(
      // Arranges children vertically.
      children: [
        // Padding around the search bar.
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            // Connects the TextField to its controller.
            controller: _searchController,
            // Defines the appearance of the TextField.
            decoration: InputDecoration(
              hintText: 'Search by title, description or tags',
              // Icon displayed at the beginning of the TextField.
              prefixIcon: const Icon(Icons.search),
              // Border style.
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              // Icon button displayed at the end of the TextField.
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear Search',
                // Action to perform when the clear button is pressed.
                onPressed: () {
                  _searchController.clear(); // Clear the text field.
                  // Call setState to clear search results and refresh the list.
                  setState(() => _searchResults = null);
                },
              ),
            ),
            // Function called whenever the text in the field changes.
            // Triggers the search logic.
            onChanged: (query) => _handleSearch(),

          ),
        ),
        // Takes up the remaining vertical space.
        Expanded(
          // Conditionally displays search results or the full list.
          child:
              _searchResults != null
                  // If search results exist, build the list using them.
                  ? _buildResourcesList(_searchResults!)
                  // Otherwise, use a StreamBuilder to listen for all resources.
                  : StreamBuilder<List<Resource>>(
                    // Specifies the stream to listen to (from the controller).
                    stream: _controller.getResources(),
                    // Builder function defines what to display based on stream state.
                    builder: (context, snapshot) {
                      // Show a loading indicator while waiting for data.
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      // Show an error message if the stream encounters an error.
                      if (snapshot.hasError) {
                        print(
                          "Error fetching resources: ${snapshot.error}",
                        ); // Log error
                        return Center(
                          child: Text(
                            'Error loading resources: ${snapshot.error}',
                          ),
                        );
                      }
                      // If data is received successfully (or stream is closed with data).
                      if (snapshot.hasData) {
                        final resources =
                            snapshot.data ??
                            []; // Get the list, default to empty list if null.
                        // Build the list using the fetched resources.
                        return _buildResourcesList(resources);
                      }
                      // Default case (e.g., stream is done with no data)
                      return const Center(
                        child: Text('No resources available.'),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  // Builds the list view to display resources.
  // Takes a list of Resource objects as input.
  Widget _buildResourcesList(List<Resource> resources) {
    // If the list is empty, display a message.
    if (resources.isEmpty) {
      return const Center(
        child: Text(
          'No resources found.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Use ListView.builder for efficient rendering of potentially long lists.
    return ListView.builder(
      // Number of items in the list.
      itemCount: resources.length,
      // Function called to build each item in the list.
      itemBuilder: (context, index) {
        // Get the resource data for the current index.
        final resource = resources[index];
        // Use a Card for better visual separation of list items.
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 3, // Subtle shadow.
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            // Main text of the list item (Resource title).
            title: Text(
              resource.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // Secondary text (Resource description).
            subtitle: Text(
              // Handle potential null or empty description gracefully.
              resource.description.isNotEmpty
                  ? resource.description
                  : 'No description provided.',
              maxLines: 2, // Limit description to 2 lines.
              overflow: TextOverflow.ellipsis, // Add '...' if text overflows.
            ),
            // Widgets displayed at the end of the ListTile.
            trailing: Row(
              mainAxisSize:
                  MainAxisSize.min, // Row takes minimum horizontal space.
              children: [
                // Button to view resource details.
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blueGrey),
                  tooltip: 'View Details',
                  onPressed: () {
                    // Navigate to the ResourceDetailScreen, passing the selected resource.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ResourceDetailScreen(
                              resource:
                                  resource, // Pass the specific resource object
                            ),
                      ),
                    );
                  },
                ),
                // Button to download the resource file.
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.blueAccent),
                  tooltip: 'Download File',
                  // Calls the controller method to handle the download.
                  onPressed: () async {
                    // Optional: Show feedback before starting download
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Starting download for ${resource.title}...',
                        ),
                      ),
                    );
                    try {
                      await _controller.downloadFile(resource);
                      // Optional: Show success message after download (controller might handle this)
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(content: Text('${resource.title} downloaded successfully.')),
                      // );
                    } catch (e) {
                      print("Error downloading file: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error downloading ${resource.title}.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            // Allows the ListTile to accommodate three lines of text if needed (title + 2 lines of subtitle).
            isThreeLine: true,
            // Optional: Add a visual cue like an icon at the beginning
            // leading: Icon(Icons.article_outlined, color: Colors.blueAccent),
          ),
        );
      },
    );
  }

  // Builds the UI for the 'Share Resource' tab.
  Widget _buildShareTab() {
    // Use SingleChildScrollView to prevent overflow if content exceeds screen height,
    // especially when the keyboard appears.
    return SingleChildScrollView(
      // Padding around the entire form content.
      padding: const EdgeInsets.all(20.0),
      child: Form(
        // Associates the form with the GlobalKey for validation.
        key: _formKey,
        child: Column(
          // Aligns children to the start (left) of the column.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title for the share section.
            const Text(
              'Share Your Resource',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24), // Spacing
            // Input field for the resource title.
            TextFormField(
              controller: _titleController, // Connects to the title controller.
              decoration: const InputDecoration(
                labelText: 'Title *', // Indicates required field.
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              // Validation logic for the title field.
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title'; // Error message if invalid.
                }
                return null; // Return null if valid.
              },
            ),
            const SizedBox(height: 16), // Spacing
            // Input field for the resource description.
            TextFormField(
              controller:
                  _descriptionController, // Connects to the description controller.
              decoration: const InputDecoration(
                labelText: 'Description *', // Indicates required field.
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3, // Allows multiple lines for description.
              // Validation logic for the description field.
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description'; // Error message if invalid.
                }
                return null; // Return null if valid.
              },
            ),
            const SizedBox(height: 16), // Spacing
            // Input field for tags.
            TextFormField(
              controller: _tagsController, // Connects to the tags controller.
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                hintText: 'e.g., math, calculus, chapter 5',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              // No validator here, tags are optional.
            ),
            const SizedBox(height: 24), // Spacing
            // --- File Selection Area ---
            // Conditionally display either the 'Select File' button or the selected file info.
            _selectedFile == null
                // Button to trigger the file picker.
                ? OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Select File *'), // Indicate required
                  // Calls the _pickFile method when pressed.
                  onPressed: _pickFile,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                )
                // Widget to display when a file IS selected.
                : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50, // Light green background
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      // Display the file name (extracted from the path).
                      Expanded(
                        child: Text(
                          _selectedFile!.path
                              .split('/')
                              .last, // Show only file name
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Button to clear the selected file.
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        tooltip: 'Remove File',
                        onPressed: () => setState(() => _selectedFile = null),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 32), // Spacing before upload button
            // --- Upload Button ---
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Resource'),
              // Action when pressed: call _uploadResource.
              // Button is disabled if an upload is in progress OR if no file is selected.
              onPressed:
                  _isUploading || _selectedFile == null
                      ? null
                      : _uploadResource,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.blueAccent, // Button background color
                foregroundColor: Colors.white, // Text and icon color
                // Style for the disabled state.
                disabledBackgroundColor: Colors.grey.shade400,
              ),
            ),

            // --- Upload Progress Indicator ---
            // Conditionally display the progress bar and text if _isUploading is true.
            if (_isUploading) ...[
              const SizedBox(height: 16),
              // Shows a linear progress indicator.
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Uploading resource, please wait...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
