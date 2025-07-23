import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'notification_service.dart'; // Add your NotificationService import

class LiveTrackingMapScreen extends StatefulWidget {
  final LatLng destination;
  final Duration? eta;
  final String type; // "start" or "end"

  const LiveTrackingMapScreen({
    super.key,
    required this.destination,
    this.eta,
    required this.type,
  });

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  GoogleMapController? mapController;
  LatLng? currentLocation;
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  StreamSubscription<Position>? positionSubscription;
  bool isTracking = false;
  bool hasArrived = false;
  double heading = 0;

  String etaText = "--";
  String distance = "-- km";
  Timer? countdownTimer;
  Duration remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _drawRoute(LatLng from, LatLng to) async {
    const apiKey = 'AIzaSyDYVFN1cOdEHVPvEnkro8Jk79vK2zhisII';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${from.latitude},${from.longitude}&destination=${to.latitude},${to.longitude}&key=$apiKey&language=vi';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['routes'].isNotEmpty) {
      final route = data['routes'][0];
      final points = PolylinePoints().decodePolyline(
        route['overview_polyline']['points'],
      );

      final polylineCoordinates =
      points.map((e) => LatLng(e.latitude, e.longitude)).toList();

      polylines.clear();
      polylines.add(Polyline(
        polylineId: const PolylineId("route"),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ));

      final leg = route['legs'][0];
      distance = leg['distance']['text'];

      setState(() {});
    }
  }

  void _startTracking() async {
    setState(() => isTracking = true);

    final position = await Geolocator.getCurrentPosition();
    currentLocation = LatLng(position.latitude, position.longitude);
    heading = position.heading;

    await _drawRoute(currentLocation!, widget.destination);
    _updateMarkers();

    if (widget.eta != null) {
      remainingTime = widget.eta!;
      etaText = _formatDuration(remainingTime);
      countdownTimer?.cancel();
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingTime.inSeconds <= 0) {
          timer.cancel();
          if (!hasArrived) {
            print('❌ Quá ETA nhưng chưa tới nơi');
            NotificationService().scheduleNotification(
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
              title: widget.type == 'start'
                  ? '⚠️ Không đến lớp đúng giờ'
                  : '⚠️ Chưa về nhà đúng giờ',
              body: widget.type == 'start'
                  ? 'Học sinh chưa đến lớp đúng giờ quy định.'
                  : 'Học sinh chưa về nhà đúng giờ quy định.',
              scheduledTime: DateTime.now().add(const Duration(seconds: 1)),
            );
            _stopTracking();
            Navigator.pop(context, false);
          }
        } else {
          setState(() {
            remainingTime -= const Duration(seconds: 1);
            etaText = _formatDuration(remainingTime);
          });
        }
      });
    }

    positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    ).listen((Position pos) {
      currentLocation = LatLng(pos.latitude, pos.longitude);
      heading = pos.heading;
      _updateMarkers();

      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLocation!, zoom: 17, bearing: heading),
        ),
      );

      double distanceToDestination = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        widget.destination.latitude,
        widget.destination.longitude,
      );

      if (distanceToDestination <= 20 && !hasArrived) {
        hasArrived = true;
        print('✅ Đã đến đích');
        NotificationService().scheduleNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: widget.type == 'start'
              ? '✅ Đã đến lớp'
              : '✅ Đã về đến nhà',
          body: widget.type == 'start'
              ? 'Học sinh đã đến lớp đúng giờ.'
              : 'Học sinh đã về nhà đúng giờ.',
          scheduledTime: DateTime.now().add(const Duration(seconds: 1)),
        );
        _stopTracking();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🟢 Đã đến điểm đến")),
        );
      }
    });
  }

  void _stopTracking() {
    setState(() => isTracking = false);
    positionSubscription?.cancel();
    countdownTimer?.cancel();
  }

  void _updateMarkers() {
    markers.clear();
    if (currentLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId("current"),
        position: currentLocation!,
        rotation: heading,
        infoWindow: const InfoWindow(title: "Vị trí hiện tại"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
      ));
    }
    markers.add(Marker(
      markerId: const MarkerId("destination"),
      position: widget.destination,
      infoWindow: const InfoWindow(title: "Điểm đến"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));
    setState(() {});
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Widget _buildInstructionPanel() {
    return Positioned(
      top: 5,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue.shade700,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ETA: $etaText  •  $distance",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📍 Theo dõi trực tiếp"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Stack(
        children: [
          currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLocation!,
              zoom: 15,
            ),
            onMapCreated: (controller) => mapController = controller,
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          _buildInstructionPanel(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    countdownTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}
