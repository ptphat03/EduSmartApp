// custom_address.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class CustomAddressPickerScreen extends StatefulWidget {
  final String? title;
  const CustomAddressPickerScreen({super.key, this.title});

  @override
  State<CustomAddressPickerScreen> createState() => _CustomAddressPickerScreenState();
}

class _CustomAddressPickerScreenState extends State<CustomAddressPickerScreen> {
  GoogleMapController? mapController;
  LatLng? fromLatLng;
  LatLng? toLatLng;
  String fromAddress = '';
  String toAddress = '';
  bool isSelectingFrom = true;

  Set<Polyline> polylines = {};
  String durationText = '';

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  Future<void> _getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      fromLatLng = LatLng(position.latitude, position.longitude);
    });
    _getAddressFromLatLng(fromLatLng!, isFrom: true);
  }

  Future<void> _getAddressFromLatLng(LatLng latLng, {required bool isFrom}) async {
    const apiKey = 'AIzaSyDYVFN1cOdEHVPvEnkro8Jk79vK2zhisII';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$apiKey&language=vi';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        setState(() {
          if (isFrom) {
            fromAddress = results[0]['formatted_address'];
          } else {
            toAddress = results[0]['formatted_address'];
          }
        });
      }
    }
  }

  Future<void> getDirections() async {
    if (fromLatLng == null || toLatLng == null) return;

    const apiKey = 'AIzaSyDYVFN1cOdEHVPvEnkro8Jk79vK2zhisII';
    final origin = '${fromLatLng!.latitude},${fromLatLng!.longitude}';
    final destination = '${toLatLng!.latitude},${toLatLng!.longitude}';
    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey&language=vi';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final routes = data['routes'];
      if (routes != null && routes.isNotEmpty) {
        final overviewPolyline = routes[0]['overview_polyline']['points'];
        final duration = routes[0]['legs'][0]['duration']['text'];

        final points = PolylinePoints().decodePolyline(overviewPolyline);
        final polylineCoordinates = points.map((p) => LatLng(p.latitude, p.longitude)).toList();

        setState(() {
          polylines = {
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              width: 5,
              points: polylineCoordinates,
            ),
          };
          durationText = duration;
        });
      }
    }
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      if (isSelectingFrom) {
        fromLatLng = latLng;
        _getAddressFromLatLng(latLng, isFrom: true);
      } else {
        toLatLng = latLng;
        _getAddressFromLatLng(latLng, isFrom: false);
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (fromLatLng != null && toLatLng != null) {
        getDirections();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? "Chọn địa chỉ")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text("Địa chỉ đi"),
                selected: isSelectingFrom,
                onSelected: (selected) {
                  if (!isSelectingFrom) setState(() => isSelectingFrom = true);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Địa chỉ về"),
                selected: !isSelectingFrom,
                onSelected: (selected) {
                  if (isSelectingFrom) setState(() => isSelectingFrom = false);
                },
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: fromLatLng ?? const LatLng(10.762622, 106.660172),
                zoom: 15,
              ),
              onMapCreated: (controller) => mapController = controller,
              onTap: _onMapTap,
              markers: {
                if (fromLatLng != null)
                  Marker(
                    markerId: const MarkerId("from"),
                    position: fromLatLng!,
                    infoWindow: const InfoWindow(title: 'Địa chỉ đi'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  ),
                if (toLatLng != null)
                  Marker(
                    markerId: const MarkerId("to"),
                    position: toLatLng!,
                    infoWindow: const InfoWindow(title: 'Địa chỉ về'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
              },
              polylines: polylines,
            ),
          ),
          if (fromAddress.isNotEmpty || toAddress.isNotEmpty || durationText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fromAddress.isNotEmpty)
                    Text("📍 Địa chỉ đi: $fromAddress", style: const TextStyle(fontSize: 14)),
                  if (toAddress.isNotEmpty)
                    Text("🏁 Địa chỉ về: $toAddress", style: const TextStyle(fontSize: 14)),
                  if (durationText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text("🕒 Thời gian dự kiến: $durationText", style: const TextStyle(fontSize: 14)),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Xác nhận địa chỉ"),
              onPressed: (fromAddress.isNotEmpty && toAddress.isNotEmpty)
                  ? () {
                Navigator.pop(context, {
                  'from': fromAddress,
                  'to': toAddress,
                });
              }
                  : null,
            ),
          )
        ],
      ),
    );
  }
}