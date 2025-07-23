import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapViewScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String title;

  const MapViewScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title = "Chọn vị trí",
  });

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  String _searchAddress = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(widget.latitude, widget.longitude);
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
  }

  Future<void> _searchAndMoveToLocation() async {
    try {
      final locations = await locationFromAddress(_searchAddress);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        _mapController.animateCamera(CameraUpdate.newLatLng(latLng));
        setState(() {
          _selectedLocation = latLng;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không tìm thấy địa chỉ.")),
      );
    }
  }

  void _saveLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveLocation,
            tooltip: "Lưu vị trí",
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Nhập địa chỉ...",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => _searchAddress = value,
                    onSubmitted: (_) => _searchAndMoveToLocation(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _searchAndMoveToLocation,
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation!,
                zoom: 16,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: _onMapTap,
              markers: {
                Marker(
                  markerId: const MarkerId("picked_location"),
                  position: _selectedLocation!,
                  infoWindow: const InfoWindow(title: "Vị trí đã chọn"),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
