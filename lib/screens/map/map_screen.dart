import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(connectionProvider.notifier).loadConnections());
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() => _pinnedLocation = point);
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
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(28.6139, 77.2090),
          initialZoom: 13,
          onTap: _onTap,
        ),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
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
    );
  }
}
