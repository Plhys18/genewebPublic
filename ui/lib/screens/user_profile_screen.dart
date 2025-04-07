import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:faabul_color_picker/faabul_color_picker.dart';
import '../auth_provider.dart';
import '../utilities/api_service.dart';
import '../color_preference.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userData;
  List<ColorPreference> _colorPreferences = [];
  bool _isSavingPreference = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await ApiService().getRequest('user/profile/');
      final preferences = await ApiService().getRequest('preferences/');

      setState(() {
        _userData = userData;

        // Process motif preferences
        final motifPrefs = preferences['motifs'] as List? ?? [];
        final stagePrefs = preferences['stages'] as List? ?? [];

        _colorPreferences = [
          ...motifPrefs.map((pref) => ColorPreference.fromJson(pref, 'motif')),
          ...stagePrefs.map((pref) => ColorPreference.fromJson(pref, 'stage')),
        ];

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load user data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: TextStyle(color: colorScheme.error)))
          : _buildProfileContent(context),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _fetchUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Information', style: textTheme.titleLarge),
                    const Divider(),
                    _buildInfoRow('Username', _userData?['username'] ?? 'Unknown'),
                    _buildInfoRow('Email', _userData?['email'] ?? 'Not provided'),
                    _buildInfoRow('Group', _userData?['group'] ?? 'None'),
                    _buildInfoRow('Joined', _userData?['date_joined'] != null
                        ? DateTime.parse(_userData!['date_joined']).toString()
                        : 'Unknown'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Color Preferences', style: textTheme.titleLarge),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          onPressed: _fetchUserData,
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_colorPreferences.isEmpty)
                      const Text('No custom color preferences set.')
                    else
                      ..._colorPreferences.map((pref) => _buildColorPreferenceRow(pref)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Account Actions', style: textTheme.titleLarge),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Sign Out'),
                      onTap: () {
                        context.read<UserAuthProvider>().logOut();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreferenceRow(ColorPreference pref) {
    return ListTile(
      leading: InkWell(
        onTap: () => _showColorPicker(pref),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: pref.color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      title: Text(pref.name),
      subtitle: Text('${pref.type.toUpperCase()}, Stroke width: ${pref.strokeWidth}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isSavingPreference ? Icons.hourglass_empty : Icons.edit),
            onPressed: _isSavingPreference ? null : () => _showColorPicker(pref),
            tooltip: 'Edit color',
          )
        ],
      ),
    );
  }

  Future<void> _showColorPicker(ColorPreference pref) async {
    final newColor = await showColorPickerDialog(
      context: context,
      selected: pref.color,
    );

    if (newColor != null) {
      _updatePreference(pref.copyWith(color: newColor));
    }
  }

  Future<void> _updatePreference(ColorPreference pref) async {
    setState(() => _isSavingPreference = true);

    try {
      await ApiService().postRequest('preferences/set/', pref.toJson());

      // Update the local list
      setState(() {
        final index = _colorPreferences.indexWhere(
                (p) => p.name == pref.name && p.type == pref.type
        );

        if (index >= 0) {
          _colorPreferences[index] = pref;
        }

        _isSavingPreference = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated ${pref.type} "${pref.name}" color preferences')),
      );
    } catch (e) {
      setState(() => _isSavingPreference = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving preference: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetPreference(ColorPreference pref) async {
    setState(() => _isSavingPreference = true);

    try {
      await ApiService().getRequest(
          'preferences/reset/?type=${pref.type}&name=${pref.name}'
      );

      // Refresh data to get updated preferences
      await _fetchUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset ${pref.type} "${pref.name}" to default color')),
      );
    } catch (e) {
      setState(() => _isSavingPreference = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting preference: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}