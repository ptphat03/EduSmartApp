import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'dart:math' as math;

class LiveTrackingMapScreen extends StatefulWidget {
  final LatLng destination;
  final Duration? eta; // ⬅ Thêm dòng này

  const LiveTrackingMapScreen({
    super.key,
    required this.destination,
    this.eta, // ⬅ Thêm dòng này
  });

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class LiveTrackingController {
  static Future<bool> startTracking(LatLng destination, Duration duration) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final current = LatLng(position.latitude, position.longitude);

      // Ước tính khoảng cách (đơn giản hóa)
      final double distance = Geolocator.distanceBetween(
          current.latitude, current.longitude, destination.latitude, destination.longitude);

      final double estimatedDurationSec = distance / 1.5; // ví dụ: tốc độ trung bình 1.5 m/s

      print("🟢 Bắt đầu tracking tới $destination, ETA: ${estimatedDurationSec ~/ 60} phút");

      // Đếm ngược ETA hoặc chạy logic nào đó (có thể dùng Timer hoặc callback tùy bạn)
      await Future.delayed(Duration(seconds: estimatedDurationSec.toInt()));

      print("✅ Đã đến nơi hoặc hết thời gian");

      return true;
    } catch (e) {
      print("❌ Lỗi tracking: $e");
      return false;
    }
  }
}
class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  GoogleMapController? mapController;
  LatLng? currentLocation;
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  StreamSubscription<Position>? positionSubscription;
  bool isTracking = false;
  double heading = 0;

  String instruction = "Hướng dẫn sẽ hiển thị ở đây";
  String eta = "-- min";
  String distance = "-- km";
  String arrivalTime = "--:--";

  Timer? countdownTimer;
  Duration remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _drawRoute(LatLng from, LatLng to) async {
    const apiKey = 'AIzaSyDYVFN1cOdEHVPvEnkro8Jk79vK2zhisII'; // ← nhớ thay API key của bạn
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
      instruction = leg['steps'][0]['html_instructions']
          .replaceAll(RegExp(r'<[^>]*>'), '');
      eta = leg['duration']['text'];
      distance = leg['distance']['text'];
      arrivalTime = leg['arrival_time']?['text'] ?? '--:--';

      // ✅ Đếm ngược ETA
      remainingTime = _parseDurationFromText(eta);
      countdownTimer?.cancel();
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingTime.inSeconds <= 0) {
          timer.cancel();
          if (isTracking) {
            _stopTracking();
            Navigator.pop(context, false); // ❌ Hết giờ chưa đến
          }
        } else {
          setState(() {
            remainingTime -= const Duration(seconds: 1);
            eta = _formatDuration(remainingTime);
          });
        }
      });
// ✅ Đếm ngược ETA từ widget nếu được truyền vào
      if (widget.eta != null) {
        remainingTime = widget.eta!;
        eta = _formatDuration(remainingTime);
      } else {
        remainingTime = _parseDurationFromText(eta);
      }
      countdownTimer?.cancel();
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingTime.inSeconds <= 0) {
          timer.cancel();
          if (isTracking) {
            _stopTracking();
            Navigator.pop(context, false); // ❌ Hết giờ chưa đến
          }
        } else {
          setState(() {
            remainingTime -= const Duration(seconds: 1);
            eta = _formatDuration(remainingTime);
          });
        }
      });


      setState(() {});
    }
  }

  Duration _parseDurationFromText(String text) {
    final RegExp regex = RegExp(r'(?:(\d+) giờ)? ?(?:(\d+) phút)?');
    final match = regex.firstMatch(text);
    if (match == null) return Duration.zero;

    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    return Duration(hours: hours, minutes: minutes);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }

  void _startTracking() async {
    setState(() => isTracking = true);

    final position = await Geolocator.getCurrentPosition();
    currentLocation = LatLng(position.latitude, position.longitude);
    heading = position.heading;

    await _drawRoute(currentLocation!, widget.destination);
    _updateMarkers();

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

      if (distanceToDestination <= 20) {
        _stopTracking();
        Navigator.pop(context, true); // ✅ Đã đến nơi
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
              // Text(
              //   instruction,
              //   style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 4),
              Text(
                "ETA: $eta  •  $distance  •  Đến lúc: $arrivalTime",
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

