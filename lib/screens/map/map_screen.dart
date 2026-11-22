import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../providers/alarm_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/auth_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _pinnedLocation;
  double _radius = 150;
  final _labelController = TextEditingController();
  final Set<String> _selectedTargets = {};

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _debounce;

  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(connectionProvider.notifier).loadConnections());
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _locationLoading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLocation = loc;
        _locationLoading = false;
      });
      _mapController.move(loc, 15);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((pos) {
        setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
      });
    } catch (_) {
      setState(() => _locationLoading = false);
    }
  }

  void _goToMyLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _searchLocation(query.trim()));
  }

  Future<void> _searchLocation(String query) async {
    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );
      final response = await http.get(uri, headers: {'User-Agent': 'GeoBuzzer/1.0'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _searchResults = data.map((item) => _SearchResult(
            displayName: item['display_name'] ?? '',
            lat: double.parse(item['lat']),
            lng: double.parse(item['lon']),
            type: item['type'] ?? '',
          )).toList();
          _showResults = _searchResults.isNotEmpty;
        });
      }
    } catch (_) {
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(_SearchResult result) {
    final point = LatLng(result.lat, result.lng);
    setState(() {
      _pinnedLocation = point;
      _showResults = false;
      _searchController.text = result.shortName;
    });
    _searchFocusNode.unfocus();
    _mapController.move(point, 16);
    _showAlarmSheet();
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _pinnedLocation = point;
      _showResults = false;
    });
    _searchFocusNode.unfocus();
    _showAlarmSheet();
  }

  void _showAlarmSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final connState = ref.read(connectionProvider);
          final accepted = connState.accepted;

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    const Text('Set Alarm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${_pinnedLocation!.latitude.toStringAsFixed(5)}, ${_pinnedLocation!.longitude.toStringAsFixed(5)}', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Text('Radius: ${_radius.round()}m'),
                    Slider(
                      value: _radius,
                      min: 50,
                      max: 500,
                      divisions: 18,
                      activeColor: const Color(0xFFFF8C00),
                      onChanged: (val) {
                        setSheetState(() => _radius = val);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: _labelController, decoration: const InputDecoration(labelText: 'Alarm Label', hintText: 'e.g. Come to this point')),
                    const SizedBox(height: 16),
                    const Text('Buzz who?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (accepted.isEmpty)
                      const Text('No connections yet. Add connections first.', style: TextStyle(color: Colors.grey))
                    else
                      ...accepted.map((c) {
                        final other = c.requester.id == (ref.read(authProvider).user?.id ?? '') ? c.recipient : c.requester;
                        return CheckboxListTile(
                          title: Text(other.name),
                          subtitle: Text('@${other.username}'),
                          value: _selectedTargets.contains(other.id),
                          activeColor: const Color(0xFFFF8C00),
                          onChanged: (val) {
                            setSheetState(() {
                              if (val == true) {
                                _selectedTargets.add(other.id);
                              } else {
                                _selectedTargets.remove(other.id);
                              }
                            });
                          },
                        );
                      }),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _selectedTargets.isEmpty ? null : () => _createAlarm(context),
                      child: const Text('Set Alarm'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createAlarm(BuildContext sheetContext) async {
    final success = await ref.read(alarmProvider.notifier).createAlarm(
      targetIds: _selectedTargets.toList(),
      lat: _pinnedLocation!.latitude,
      lng: _pinnedLocation!.longitude,
      radiusMeters: _radius,
      label: _labelController.text.trim(),
    );
    if (mounted) {
      Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Alarm set!' : 'Failed to create alarm')),
      );
      if (success) {
        setState(() {
          _pinnedLocation = null;
          _selectedTargets.clear();
          _labelController.clear();
          _radius = 150;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GeoBuzzer')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(28.6139, 77.2090),
              initialZoom: 13,
              onTap: _onTap,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              if (_currentLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, spreadRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ]),
              if (_pinnedLocation != null) ...[
                CircleLayer(circles: [
                  CircleMarker(
                    point: _pinnedLocation!,
                    radius: _radius,
                    useRadiusInMeter: true,
                    color: const Color(0xFFFF8C00).withOpacity(0.15),
                    borderColor: const Color(0xFFFF8C00),
                    borderStrokeWidth: 2,
                  ),
                ]),
                MarkerLayer(markers: [
                  Marker(
                    point: _pinnedLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin, color: Color(0xFFFF8C00), size: 40),
                  ),
                ]),
              ],
            ],
          ),
          // My location FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _currentLocation != null ? _goToMyLocation : null,
              child: _locationLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8C00)))
                  : Icon(
                      _currentLocation != null ? Icons.my_location : Icons.location_disabled,
                      color: _currentLocation != null ? const Color(0xFFFF8C00) : Colors.grey,
                    ),
            ),
          ),
          // Search bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFFF8C00)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _showResults = false;
                                });
                              },
                            )
                          : _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8C00))),
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                if (_showResults)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: Color(0xFFFF8C00)),
                          title: Text(result.shortName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: Text(result.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          dense: true,
                          onTap: () => _selectSearchResult(result),
                        );
                      },
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

class _SearchResult {
  final String displayName;
  final double lat;
  final double lng;
  final String type;

  _SearchResult({required this.displayName, required this.lat, required this.lng, required this.type});

  String get shortName {
    final parts = displayName.split(',');
    return parts.length >= 2 ? '${parts[0].trim()}, ${parts[1].trim()}' : parts[0].trim();
  }
}
