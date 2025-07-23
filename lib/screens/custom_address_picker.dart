import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class CustomAddressPickerScreen extends StatefulWidget {
  final String? title;
  final LatLng? initialFrom;
  final LatLng? initialTo;
  final bool isEditMode;

  const CustomAddressPickerScreen({
    super.key,
    this.title,
    this.initialFrom,
    this.initialTo,
    this.isEditMode = false, // ✅ giá trị mặc định
  });

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
  bool showBottomInfo = true;
  Set<Polyline> polylines = {};
  String durationText = '';
  String distanceText = '';
  Offset draggablePosition = const Offset(20, 80);
  late bool isEditMode;


  final TextEditingController searchController = TextEditingController();
  List<dynamic> suggestions = [];

  @override
  void initState() {
    super.initState();
    fromLatLng = widget.initialFrom;
    toLatLng = widget.initialTo;
    isEditMode = widget.isEditMode;

    if (fromLatLng != null) _getAddressFromLatLng(fromLatLng!, isFrom: true);
    if (toLatLng != null) _getAddressFromLatLng(toLatLng!, isFrom: false);
    if (fromLatLng != null && toLatLng != null) getDirections();
    if (fromLatLng == null) _getCurrentPosition();

    searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      fromLatLng = LatLng(position.latitude, position.longitude);
    });
    _getAddressFromLatLng(fromLatLng!, isFrom: true);
  }

  Future<void> selectCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    _onMapTap(latLng);
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
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey&language=vi';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final routes = data['routes'];
      if (routes != null && routes.isNotEmpty) {
        final overviewPolyline = routes[0]['overview_polyline']['points'];
        final duration = routes[0]['legs'][0]['duration']['text'];
        final distance = routes[0]['legs'][0]['distance']['text'];

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
          distanceText = distance;
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

  Future<void> _getPlaceSuggestions(String input) async {
    const apiKey = 'AIzaSyDYVFN1cOdEHVPvEnkro8Jk79vK2zhisII';
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&language=vi&components=country:vn';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        suggestions = data['predictions'];
      });
    }
  }

  Future<LatLng?> _getLatLngFromPlaceIdReturn(String placeId) async {
    const apiKey = 'AIzaSyDYVFN1cOdEHVPvEnkro8Jk79vK2zhisII';
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final location = data['result']['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 28, // ✅ To hơn một chút để nổi bật
        ),
        title: Text(
          widget.title ?? "Bản đồ quãng đường",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // ✅ In đậm
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isEditMode ? Icons.visibility : Icons.edit,
              color: Colors.white, // ✅ Bắt buộc nếu không dùng iconTheme
              size: 28, // ✅ To và nổi bật
            ),
            tooltip: isEditMode ? "Chế độ xem" : "Chế độ chỉnh sửa",
            onPressed: () {
              setState(() {
                isEditMode = !isEditMode;
              });
            },
          ),
        ],
      ),



      body: Stack(
        children: [
          Column(
            children: [
              if (isEditMode)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("Địa điểm đến"),
                    selected: isSelectingFrom,
                    onSelected: (selected) {
                      if (!isSelectingFrom) setState(() => isSelectingFrom = true);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Địa điểm về"),
                    selected: !isSelectingFrom,
                    onSelected: (selected) {
                      if (isSelectingFrom) setState(() => isSelectingFrom = false);
                    },
                  ),
                ],
              ),
              if (isEditMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm địa điểm...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              suggestions.clear();
                            });
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _getPlaceSuggestions(value);
                        } else {
                          setState(() => suggestions.clear());
                        }
                      },
                    ),
                    if (suggestions.isNotEmpty)
                      Container(
                        height: 200,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = suggestions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on),
                              title: Text(suggestion['description']),
                              onTap: () async {
                                final placeId = suggestion['place_id'];
                                final latLng = await _getLatLngFromPlaceIdReturn(placeId);
                                if (latLng != null) {
                                  _onMapTap(latLng);
                                  mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
                                }
                                setState(() {
                                  suggestions.clear();
                                  searchController.clear();
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: fromLatLng ?? const LatLng(10.762622, 106.660172),
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => mapController = controller,
                  onTap: isEditMode ? _onMapTap : null,
                  markers: {
                    if (fromLatLng != null)
                      Marker(
                        markerId: const MarkerId("from"),
                        position: fromLatLng!,
                        infoWindow: const InfoWindow(title: 'Địa điểm đến'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      ),
                    if (toLatLng != null)
                      Marker(
                        markerId: const MarkerId("to"),
                        position: toLatLng!,
                        infoWindow: const InfoWindow(title: 'Địa điểm về'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      ),
                  },
                  polylines: polylines,
                  myLocationEnabled: true,
                ),
              ),
            ],
          ),
          Positioned(
            bottom: draggablePosition.dy,
            right: draggablePosition.dx,
            child: Draggable(
              feedback: FloatingActionButton(
                heroTag: 'drag_feedback',
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                onPressed: null,
                child: const Icon(Icons.my_location),
              ),
              childWhenDragging: const SizedBox(),
              onDragEnd: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final localOffset = renderBox.globalToLocal(details.offset);
                setState(() {
                  draggablePosition = Offset(
                    MediaQuery.of(context).size.width - localOffset.dx - 56,
                    MediaQuery.of(context).size.height - localOffset.dy - 56 - kBottomNavigationBarHeight,
                  );
                });
              },
              child: FloatingActionButton(
                heroTag: 'current_location',
                onPressed: selectCurrentLocation,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                child: const Icon(Icons.my_location),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => showBottomInfo = !showBottomInfo),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        showBottomInfo ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        size: 28,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                if (showBottomInfo &&
                    (fromAddress.isNotEmpty || toAddress.isNotEmpty || durationText.isNotEmpty || distanceText.isNotEmpty))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (fromAddress.isNotEmpty)
                          Text("\uD83D\uDCCD Địa điểm đến: $fromAddress", style: const TextStyle(fontSize: 14)),
                        if (toAddress.isNotEmpty)
                          Text("\uD83C\uDFC1 Địa điểm về: $toAddress", style: const TextStyle(fontSize: 14)),
                        if (durationText.isNotEmpty || distanceText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (durationText.isNotEmpty)
                                  Text("\uD83D\uDD52 Thời gian: $durationText", style: const TextStyle(fontSize: 14)),
                                if (distanceText.isNotEmpty)
                                  Text("\uD83D\uDCCF Khoảng cách: $distanceText", style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text("Xác nhận địa chỉ"),
                            onPressed: (fromAddress.isNotEmpty && toAddress.isNotEmpty)
                                ? () {
                              Navigator.pop(context, {
                                'from': fromAddress,
                                'to': toAddress,
                                'fromLatLng': '${fromLatLng?.latitude},${fromLatLng?.longitude}',
                                'toLatLng': '${toLatLng?.latitude},${toLatLng?.longitude}',
                              });
                            }
                                : null,
                          ),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}