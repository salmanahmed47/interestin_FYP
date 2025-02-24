import 'dart:developer';

import 'package:event_managment/admin/admin_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class SetLocation extends StatefulWidget {
  final String documentId;

  const SetLocation({
    Key? key,
    required this.documentId,
  }) : super(key: key);

  @override
  State<SetLocation> createState() => _SetLocationState();
}

class _SetLocationState extends State<SetLocation> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  double _eventRadius = 0.0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_selectedLocation!, 15);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
    }

    try {
      Position position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_selectedLocation!, 15);
    } catch (e) {
      log('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Event Location"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.grey[300],
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _selectedLocation ?? LatLng(0, 0),
              zoom: 15,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _selectedLocation = latLng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      builder: (ctx) => const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              if (_selectedLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedLocation!,
                      radius: _eventRadius,
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for a location',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final query = _searchController.text;
                    if (query.isNotEmpty) {
                      try {
                        List<Location> locations =
                            await locationFromAddress(query);
                        if (locations.isNotEmpty) {
                          final loc = locations.first;
                          LatLng searchLocation =
                              LatLng(loc.latitude, loc.longitude);
                          _mapController.move(searchLocation, 15);
                          setState(() {
                            _selectedLocation = searchLocation;
                          });
                        }
                      } catch (e) {
                        showDialog(
                          // ignore: use_build_context_synchronously
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Error'),
                              content: Text('Could not find location: $e'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 100,
            child: Slider(
              min: 0,
              max: 500,
              value: _eventRadius,
              activeColor: Colors.deepPurple,
              inactiveColor: Colors.deepPurple.shade100,
              onChanged: (value) {
                setState(() {
                  _eventRadius = value;
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_selectedLocation != null) {
            await FirebaseFirestore.instance
                .collection("events")
                .doc(widget.documentId)
                .update({
              'latitude': _selectedLocation!.latitude,
              'longitude': _selectedLocation!.longitude,
              'range': _eventRadius,
            });
            // ignore: use_build_context_synchronously
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
              return const AdminEvents();
            }));
          } else {
            // ignore: use_build_context_synchronously
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: const Text('Please select a location'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.check),
      ),
    );
  }
}
