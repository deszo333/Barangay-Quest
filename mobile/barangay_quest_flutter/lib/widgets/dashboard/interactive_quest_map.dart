// lib/widgets/interactive_quest_map.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import '../theme/app_theme.dart'; // Still needed for AppTheme.accent

class InteractiveQuestMap extends StatefulWidget {
  final Set<Marker> markers;
  final Function(LatLng)? onMapTap;
  final Function(GoogleMapController)? onMapCreated;
  final LatLng initialCenter;
  final double initialZoom;

  const InteractiveQuestMap({
    super.key,
    required this.markers,
    this.onMapTap,
    this.onMapCreated,
    this.initialCenter = const LatLng(14.5995, 120.9842),
    this.initialZoom = 12.0,
  });

  @override
  State<InteractiveQuestMap> createState() => _InteractiveQuestMapState();
}

class _InteractiveQuestMapState extends State<InteractiveQuestMap> {
  final Completer<GoogleMapController> _controller = Completer();
  MapType _currentMapType = MapType.normal;
  loc.Location location = loc.Location();
  bool _serviceEnabled = false;
  loc.PermissionStatus _permissionGranted = loc.PermissionStatus.denied;

  // State for pan controls
  bool _showPanControls = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  // Toggle function
  void _togglePanControls() {
    setState(() {
      _showPanControls = !_showPanControls;
    });
  }

  Future<void> _checkLocationPermission() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _goToMyLocation() async {
    if (_permissionGranted != loc.PermissionStatus.granted) {
      _showPermissionDialog();
      return;
    }
    final GoogleMapController controller = await _controller.future;
    try {
      final loc.LocationData userLocation = await location.getLocation();
      if (userLocation.latitude != null && userLocation.longitude != null) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(userLocation.latitude!, userLocation.longitude!),
              zoom: 16.0,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Could not get user location: $e");
    }
  }

  void _showPermissionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text(
            'Location permission is required. Please enable it in app settings.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _fitToMarkers() async {
    final GoogleMapController controller = await _controller.future;
    if (widget.markers.isEmpty) {
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: widget.initialCenter, zoom: widget.initialZoom),
      ));
      return;
    }
    if (widget.markers.length == 1) {
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: widget.markers.first.position, zoom: 15.0),
      ));
      return;
    }
    LatLngBounds bounds = _getBounds(widget.markers);
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  LatLngBounds _getBounds(Set<Marker> markers) {
    double minLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLat = markers.first.position.latitude;
    double maxLng = markers.first.position.longitude;
    for (var marker in markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _cycleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.satellite;
      } else if (_currentMapType == MapType.satellite) {
        _currentMapType = MapType.terrain;
      } else {
        _currentMapType = MapType.normal;
      }
    });
  }

  Future<void> _panMap(double dx, double dy) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.scrollBy(dx, dy));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bg2.withOpacity(0.5)),
      ),
      child: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            initialCameraPosition: CameraPosition(
              target: widget.initialCenter,
              zoom: widget.initialZoom,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              // Pass the controller back up to the parent screen
              widget.onMapCreated?.call(controller);
            },
            markers: widget.markers,
            onTap: widget.onMapTap,
            myLocationButtonEnabled: false,
            myLocationEnabled:
                _permissionGranted == loc.PermissionStatus.granted,
            zoomControlsEnabled: true, // Keep the native zoom
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
          ),
          // Top-Right Controls
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.explore_outlined, // Compass icon
                  tooltip: 'Toggle Pan Controls',
                  onPressed: _togglePanControls,
                  isSelected: _showPanControls, // Will light up when active
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.my_location,
                  tooltip: 'My Location',
                  onPressed: _goToMyLocation,
                ),
                if (widget.markers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.zoom_out_map,
                    tooltip: 'Fit to Quests',
                    onPressed: _fitToMarkers,
                  ),
                ],
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.layers_outlined,
                  tooltip: 'Cycle Map Type',
                  onPressed: _cycleMapType,
                ),
              ],
            ),
          ),
          // Bottom-Left Pan Controls
          Positioned(
            bottom: 24,
            left: 12,
            child: Visibility(
              visible: _showPanControls,
              child: Column(
                children: [
                  _MapControlButton(
                    icon: Icons.keyboard_arrow_up,
                    tooltip: 'Pan Up',
                    onPressed: () => _panMap(0, -100),
                    isSmall: true,
                  ),
                  Row(
                    children: [
                      _MapControlButton(
                        icon: Icons.keyboard_arrow_left,
                        tooltip: 'Pan Left',
                        onPressed: () => _panMap(-100, 0),
                        isSmall: true,
                      ),
                      const SizedBox(width: 44), // Spacer
                      _MapControlButton(
                        icon: Icons.keyboard_arrow_right,
                        tooltip: 'Pan Right',
                        onPressed: () => _panMap(100, 0),
                        isSmall: true,
                      ),
                    ],
                  ),
                  _MapControlButton(
                    icon: Icons.keyboard_arrow_down,
                    tooltip: 'Pan Down',
                    onPressed: () => _panMap(0, 100),
                    isSmall: true,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isSmall;
  final bool isSelected;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isSmall = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final constraints = isSmall
        ? const BoxConstraints(minWidth: 40, minHeight: 40)
        : const BoxConstraints(minWidth: 48, minHeight: 48);

    // --- NEW STYLING TO MATCH NATIVE ZOOM ---
    // Icon color: Blue if selected (like native 'my location'),
    // otherwise dark grey to match zoom controls
    final Color iconColor =
        isSelected ? AppTheme.accent : Colors.grey.shade800;
    
    // Background color: White, semi-transparent
    final Color bgColor = Colors.white.withOpacity(0.9);
    
    // Elevation: A subtle shadow
    final double elevation = 2.0;

    return Material(
      color: bgColor, // White, semi-transparent
      borderRadius: BorderRadius.circular(24), // Keep circular shape
      elevation: elevation,
      child: IconButton(
        icon: Icon(icon, color: iconColor), // Dark icon
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: constraints,
        iconSize: isSmall ? 20 : 24,
      ),
    );
  }
}