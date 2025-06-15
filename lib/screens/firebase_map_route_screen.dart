import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class FirebaseMapRouteScreen extends StatefulWidget {
  @override
  _FirebaseMapRouteScreenState createState() => _FirebaseMapRouteScreenState();
}

class _FirebaseMapRouteScreenState extends State<FirebaseMapRouteScreen> {
  LatLng? school, student;
  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
    fetchDataAndRoute();
  }

  Future<void> fetchDataAndRoute() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('gradeGroups')
          .doc('UQuN6YNWxUuEtRi4Woqr')
          .get();

      final data = doc.data();
      if (data != null) {
        school = LatLng(data['schoolLat'], data['schoolLng']);
        student = LatLng(data['studentLat'], data['studentLng']);
        await fetchRoute();
        setState(() {});
      }
    } catch (e) {
      print("Firestore error: $e");
    }
  }

  Future<void> fetchRoute() async {
    if (school == null || student == null) return;

    final url =
        'https://router.project-osrm.org/route/v1/driving/${school!.longitude},${school!.latitude};${student!.longitude},${student!.latitude}?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'];
      routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
    } else {
      print("OSRM error: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chỉ đường từ Firestore")),
      body: (school == null || student == null)
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
        options: MapOptions(
          initialCenter: school!,
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.my_app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: school!,
                width: 40,
                height: 40,
                child: const Icon(Icons.school, color: Colors.blue),
              ),
              Marker(
                point: student!,
                width: 40,
                height: 40,
                child: const Icon(Icons.home, color: Colors.red),
              ),
            ],
          ),
          if (routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 4.0,
                  color: Colors.green,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
