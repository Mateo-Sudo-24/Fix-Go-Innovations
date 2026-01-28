import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Widget para seleccionar sector dinámicamente
class DynamicSectorSelector extends StatefulWidget {
  final Function(String sector, LatLng? exactLocation) onSectorSelected;
  final String? initialSector;
  final LatLng? initialLocation;

  const DynamicSectorSelector({
    Key? key,
    required this.onSectorSelected,
    this.initialSector,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<DynamicSectorSelector> createState() =>
      _DynamicSectorSelectorState();
}

class _DynamicSectorSelectorState extends State<DynamicSectorSelector> {
  late TextEditingController _sectorController;
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  String? _detectedSector;

  // Sectores disponibles (puedes cambiar esto por datos de BD)
  final List<String> _sectors = [
    'Centro',
    'Norte',
    'Sur',
    'Este',
    'Oeste',
    'Nor-Este',
    'Nor-Oeste',
    'Sur-Este',
    'Sur-Oeste',
    'Industrial',
    'Residencial',
    'Comercial',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _sectorController =
        TextEditingController(text: widget.initialSector ?? '');
    _currentLocation = widget.initialLocation;
    _detectedSector = widget.initialSector;
  }

  @override
  void dispose() {
    _sectorController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Por favor, habilita los servicios de ubicación'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Permiso de ubicación denegado'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );

      setState(() {
        _currentLocation =
            LatLng(position.latitude, position.longitude);
        _detectedSector = _estimateSector(position.latitude,
            position.longitude);
        if (_detectedSector != null) {
          _sectorController.text =
              _detectedSector!;
        }
        _isLoadingLocation = false;
      });

      widget.onSectorSelected(
        _sectorController.text,
        _currentLocation,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '📍 Sector detectado: $_detectedSector'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Estima el sector basado en coordenadas (ejemplo simple)
  String _estimateSector(
      double latitude, double longitude) {
    // Esto es un ejemplo - puedes implementar lógica más sofisticada
    if (latitude > 12.0 && longitude > -77.0) {
      return 'Nor-Este';
    } else if (latitude > 12.0) {
      return 'Nor-Oeste';
    } else if (longitude > -77.0) {
      return 'Sur-Este';
    } else {
      return 'Sur-Oeste';
    }
  }

  void _showSectorSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Selecciona un Sector',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _sectors.length,
                itemBuilder: (context, index) =>
                    ListTile(
                  title: Text(_sectors[index]),
                  selected:
                      _sectorController.text ==
                          _sectors[index],
                  onTap: () {
                    setState(() {
                      _sectorController.text =
                          _sectors[index];
                      _detectedSector =
                          _sectors[index];
                    });
                    widget.onSectorSelected(
                      _sectors[index],
                      _currentLocation,
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sector',
          style:
              Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _sectorController,
                decoration: InputDecoration(
                  hintText: 'Escribe o selecciona sector',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  prefixIcon:
                      const Icon(Icons.location_on),
                  suffixIcon: _sectorController
                          .text
                          .isNotEmpty
                      ? IconButton(
                          icon:
                              const Icon(Icons.clear),
                          onPressed: () {
                            _sectorController
                                .clear();
                            widget
                                .onSectorSelected(
                              '',
                              _currentLocation,
                            );
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  widget.onSectorSelected(
                    value,
                    _currentLocation,
                  );
                },
                onTap: () =>
                    _showSectorSelection(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _isLoadingLocation
                  ? null
                  : _getCurrentLocation,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.location_searching),
            ),
          ],
        ),
        if (_currentLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(
                  color: Colors.orange[200]!,
                ),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '📍 Ubicación: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}',
                      style:
                          Theme.of(context)
                              .textTheme
                              .labelSmall,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
