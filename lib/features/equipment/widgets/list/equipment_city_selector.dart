import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EquipmentCitySelector extends StatefulWidget {
  const EquipmentCitySelector({super.key});

  @override
  State<EquipmentCitySelector> createState() => _EquipmentCitySelectorState();
}

class _EquipmentCitySelectorState extends State<EquipmentCitySelector> {
  String _currentCity = "Atyrau, Kazakhstan"; // Default fallback
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineCity();
  }

  Future<void> _determineCity() async {
    try {
      // 1. Check & Request Permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // 2. Get Coordinates
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        );

        // 3. Convert Lat/Long to City Name
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          setState(() {
            // .locality usually contains the city name
            _currentCity = placemarks.first.locality ?? "Atyrau, Kazakhstan";
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      return;
    }

    // Fallback if everything fails
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: _isLoading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.location_on, size: 16, color: Colors.orange),
        label: Text(_currentCity),
        onPressed: () {
          // later: open city picker
        },
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
