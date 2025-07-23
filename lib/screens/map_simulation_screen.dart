import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

// ⚠️ Thay bằng API key thật của bạn (đã bật Routes API)
const String googleApiKey = 'AIzaSyDYVFN1cOdEHVPvEnkro8Jk79vK2zhisII';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  LatLng? _destinationPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String? distanceText;
  String? durationText;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Vị trí hiện tại'),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition!, 15),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onTap(LatLng tappedPoint) async {
    setState(() {
      _destinationPosition = tappedPoint;
      _markers.removeWhere((m) => m.markerId == const MarkerId('destination'));
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: tappedPoint,
          infoWindow: const InfoWindow(title: 'Điểm đến'),
        ),
      );
    });

    if (_currentPosition != null) {
      await _drawRoute(_currentPosition!, tappedPoint);
    }
  }

  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    final response = await http.post(
      Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': googleApiKey,
        'X-Goog-FieldMask':
        'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
      },
      body: jsonEncode({
        "origin": {
          "location": {
            "latLng": {
              "latitude": origin.latitude,
              "longitude": origin.longitude
            }
          }
        },
        "destination": {
          "location": {
            "latLng": {
              "latitude": destination.latitude,
              "longitude": destination.longitude
            }
          }
        },
        "travelMode": "DRIVE",
      }),
    );

    final data = json.decode(response.body);

    if (data['routes'] != null && data['routes'].isNotEmpty) {
      final route = data['routes'][0];
      final polyline = route['polyline']['encodedPolyline'];

      final decodedPoints = PolylinePoints().decodePolyline(polyline);

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: decodedPoints
                .map((e) => LatLng(e.latitude, e.longitude))
                .toList(),
          ),
        );

        final distanceMeters = route['distanceMeters'];
        final durationSeconds = _parseDuration(route['duration']);

        distanceText = "${(distanceMeters / 1000).toStringAsFixed(1)} km";
        durationText = _formatDuration(durationSeconds);
      });
    } else {
      debugPrint("Không có route trả về: $data");
    }
  }

  int _parseDuration(String duration) {
    final regex = RegExp(r'(\d+)s$');
    final match = regex.firstMatch(duration);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).round();
    return "$minutes phút";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Map & Directions')),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            polylines: _polylines,
            onTap: _onTap,
            mapType: MapType.normal,
            zoomControlsEnabled: true,
            compassEnabled: true,
          ),
          if (distanceText != null && durationText != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Khoảng cách: $distanceText\nThời gian ước tính: $durationText",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
