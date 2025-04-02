import 'dart:io';
import 'package:flutter/material.dart';
import '../model/resource_model.dart';
import '../controller/resource_controller.dart';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({Key? key}) : super(key: key);

  @override
  _ResourceScreenState createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  final ResourceController _controller = ResourceController();
  final TextEditingController _searchController = TextEditingController();

  List<Resource>? _searchResults;
  File? _selectedFile;
  bool _isUploading = false;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }

    final results = await _controller.searchResources(query);
    setState(() => _searchResults = results);
  }

  Future<void> _pickFile() async {
    final file = await _controller.pickFile();
    if (file != null) {
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _uploadResource() async {
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      setState(() => _isUploading = true);

      final tags =
          _tagsController.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();

      final success = await _controller.uploadResource(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: tags,
        file: _selectedFile!,
      );

      setState(() {
        _isUploading = false;
        if (success) {
          _selectedFile = null;
          _titleController.clear();
          _descriptionController.clear();
          _tagsController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resource uploaded successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload assignment')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,

          title: const Text(
            'Resources',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          bottom: const TabBar(
            labelColor: Colors.white, // Color for the selected tab text
            
            tabs: [
              Tab(text: 'Browse Resources', icon: Icon(Icons.search)),
              Tab(text: 'Share Resource', icon: Icon(Icons.upload_file)),
            ],
          ),
        ),
        body: TabBarView(children: [_buildBrowseTab(), _buildShareTab()]),
      ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by title, description or tags',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchResults = null);
                },
              ),
            ),
            onChanged: (_) => _handleSearch(),
          ),
        ),
        Expanded(
          child:
              _searchResults != null
                  ? _buildResourcesList(_searchResults!)
                  : StreamBuilder<List<Resource>>(
                    stream: _controller.getResources(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final assignments = snapshot.data ?? [];
                      return _buildResourcesList(assignments);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildResourcesList(List<Resource> assignments) {
    if (assignments.isEmpty) {
      return const Center(
        child: Text('No assignments found', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            title: Text(
              assignment.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(assignment.description),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children:
                      assignment.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              backgroundColor: Colors.blue.shade100,
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploaded on: ${_formatDate(assignment.uploadDate)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              onPressed: () => _controller.downloadFile(assignment),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildShareTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Share Your Resource',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
                hintText: 'math, physics, homework',
              ),
            ),
            const SizedBox(height: 24),
            _selectedFile == null
                ? OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Select File'),
                  onPressed: _pickFile,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                )
                : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile!.path.split('/').last,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() => _selectedFile = null),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Upload Resource'),
              onPressed:
                  _isUploading || _selectedFile == null
                      ? null
                      : _uploadResource,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            if (_isUploading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Uploading assignment...',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple date formatting, you might want to use intl package for better formatting
    return '${date.day}/${date.month}/${date.year}';
  }
}
