import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

const String googleApiKey = 'AIzaSyDYVFN1cOdEHVPvEnkro8Jk79vK2zhisII'; // 🔑

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final bool editable;
  final String? title;

  const MapPickerScreen({
    super.key,
    this.initialLocation,
    this.editable = true,
    this.title,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late bool isEditMode;
  LatLng? selectedLatLng;
  GoogleMapController? mapController;
  final TextEditingController searchController = TextEditingController();
  List<dynamic> suggestions = [];

  @override
  void initState() {
    super.initState();
    isEditMode = false; // 👉 Luôn khởi tạo ở chế độ xem (dù editable: true)
    if (widget.initialLocation != null) {
      selectedLatLng = widget.initialLocation;
    } else {
      _getCurrentLocation();
    }
  }


  @override
  void dispose() {
    mapController?.dispose();
    searchController.dispose();
    super.dispose();
  }

  /* ─────────────────────────────  Google / Geolocator helpers  ───────────────────────────── */

  void _onMapCreated(GoogleMapController controller) => mapController = controller;

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    selectedLatLng = LatLng(pos.latitude, pos.longitude);
    setState(() {});
    mapController?.animateCamera(CameraUpdate.newLatLng(selectedLatLng!));
  }

  void _searchPlaces(String input) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$googleApiKey&language=vi&components=country:vn';
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);
    if (data['status'] == 'OK') {
      setState(() => suggestions = data['predictions']);
    }
  }

  Future<Map<String, dynamic>?> _fetchPlaceDetails(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey&language=vi';
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);
    return (data['status'] == 'OK') ? data['result'] : null;
  }

  /* ─────────────────────────────  UI helpers  ───────────────────────────── */

  void _showPlaceDetails(Map<String, dynamic> place) {
    final photoRef =
    place['photos'] != null && place['photos'].isNotEmpty ? place['photos'][0]['photo_reference'] : null;
    final photoUrl = photoRef != null
        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=600&photoreference=$photoRef&key=$googleApiKey'
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // 👈 Chỉ chiếm đúng chiều cao nội dung
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photoUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                place['name'] ?? '',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(place['formatted_address'] ?? ''),
              if (place['rating'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    Text(
                      ' ${place['rating']} (${place['user_ratings_total'] ?? 0})',
                    ),
                  ],
                ),
              ],
              if (place['opening_hours']?['weekday_text'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  place['opening_hours']['weekday_text']
                  [DateTime.now().weekday - 1],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Chọn vị trí này'),
                  onPressed: () {
                    Navigator.pop(context); // đóng sheet
                    Navigator.pop(context, {
                      'latlng': selectedLatLng,
                      'placeName': place['name'],
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

  }

  void _selectSuggestion(String placeId) async {
    final place = await _fetchPlaceDetails(placeId);
    if (place == null) return;

    final loc = place['geometry']['location'];
    selectedLatLng = LatLng(loc['lat'], loc['lng']);

    setState(() {
      suggestions.clear();
      searchController.text = place['name'];
    });

    mapController?.animateCamera(CameraUpdate.newLatLng(selectedLatLng!));
    _showPlaceDetails(place);
  }

  Future<void> _reverseGeocodeTap(LatLng latLng) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$googleApiKey&language=vi';
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data['status'] == 'OK' && data['results'].isNotEmpty) {
      final placeId = data['results'][0]['place_id'];
      _selectSuggestion(placeId);
    } else {
      // fallback chỉ đặt marker
      setState(() => selectedLatLng = latLng);
    }
  }

  /* ─────────────────────────────  Build  ───────────────────────────── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Chọn vị trí'),
        actions: [
          if (widget.editable)
            IconButton(
              tooltip: isEditMode ? 'Xem' : 'Chỉnh sửa',
              icon: Icon(isEditMode ? Icons.visibility : Icons.edit),
              onPressed: () {
                setState(() {
                  isEditMode = !isEditMode;
                });
              },
            ),
          if (isEditMode)
            IconButton(
              tooltip: 'Xác nhận',
              icon: const Icon(Icons.check),
              onPressed: () {
                if (selectedLatLng != null) {
                  Navigator.pop(context, {
                    'latlng': selectedLatLng,
                    'placeName': searchController.text.isNotEmpty
                        ? searchController.text
                        : 'Vị trí đã chọn',
                  });
                }
              },
            ),
        ],
      ),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLatLng ?? const LatLng(10.762622, 106.660172),
              zoom: 15,
            ),
            onMapCreated: _onMapCreated,
            onTap: isEditMode ? _reverseGeocodeTap : null,
            myLocationEnabled: true,
            markers: selectedLatLng != null
                ? {
              Marker(
                markerId: const MarkerId('picked'),
                position: selectedLatLng!,
              )
            }
                : {},
          ),

          /* ───── Search box + suggestion list ───── */
          if (isEditMode)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(8),
                    child: TextField(
                      controller: searchController,
                      onChanged: _searchPlaces,
                      decoration: InputDecoration(
                        hintText: 'Tìm địa điểm...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      constraints:
                      const BoxConstraints(maxHeight: 250), // 👈 giới hạn cao
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 5)
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        itemBuilder: (_, i) => ListTile(
                          title: Text(suggestions[i]['description']),
                          onTap: () =>
                              _selectSuggestion(suggestions[i]['place_id']),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Về vị trí hiện tại',
        child: const Icon(Icons.my_location),
        onPressed: () async {
          await _getCurrentLocation();
          if (selectedLatLng != null) {
            final url =
                'https://maps.googleapis.com/maps/api/geocode/json?latlng=${selectedLatLng!.latitude},${selectedLatLng!.longitude}&key=$googleApiKey&language=vi';
            final res = await http.get(Uri.parse(url));
            final data = jsonDecode(res.body);

            if (data['status'] == 'OK' && data['results'].isNotEmpty) {
              final placeId = data['results'][0]['place_id'];
              final placeDetails = await _fetchPlaceDetails(placeId);

              if (placeDetails != null) {
                setState(() {
                  searchController.text = placeDetails['name'];
                });
              }
            }
          }
        },
      ),

    );
  }
}
