import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class PokemonScreen extends StatefulWidget {
  const PokemonScreen({super.key});

  @override
  State<PokemonScreen> createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _player = AudioPlayer();
  Map<String, dynamic>? _pokemonData;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPlaying = false;

  Future<void> _fetchPokemon() async {
    final name = _controller.text.toLowerCase().trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa un nombre');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _pokemonData = null;
      _isPlaying = false;
    });

    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/$name'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _pokemonData = data);

        // Intentar reproducir sonido
        await _playPokemonSound(data['id']);
      } else {
        setState(() => _errorMessage = 'Pokémon no encontrado');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playPokemonSound(int id) async {
    try {
      final soundUrl = 'https://pokemoncries.com/cries/$id.mp3';
      await _player.play(UrlSource(soundUrl));
      setState(() => _isPlaying = true);
    } catch (e) {
      // No mostrar error si falla el sonido
    }
  }

  Future<void> _stopSound() async {
    await _player.stop();
    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.home, color: Colors.white),
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context, 
                              '/', 
                              (route) => false,
                            ),
                            tooltip: 'Ir al inicio',
                          ),
                        ),
                        const Text(
                          'Buscador de Pokémon',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 48), // Para centrar el título
                      ],
                    ),
                  ),

                  // Campo de búsqueda
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (value) => _fetchPokemon(),
                          decoration: InputDecoration(
                            labelText: 'Nombre del Pokémon',
                            labelStyle: const TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                            suffixIcon: _controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white70),
                                    onPressed: () {
                                      _controller.clear();
                                      setState(() {
                                        _pokemonData = null;
                                        _errorMessage = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Botón de búsqueda
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _fetchPokemon,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : const Text(
                                    'Buscar Pokémon',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mensaje de error
                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Mostrar datos del Pokémon
                  if (_pokemonData != null) _buildPokemonCard(),

                  // Botones de acción (solo cuando hay resultado)
                  if (_pokemonData != null)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => _fetchPokemon(),
                                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                                label: const Text(
                                  'Buscar Otro',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {
                                    _pokemonData = null;
                                    _errorMessage = '';
                                  });
                                },
                                icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                                label: const Text(
                                  'Limpiar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Placeholder cuando no hay datos
                  if (_pokemonData == null && _errorMessage.isEmpty && !_isLoading)
                    Container(
                      margin: const EdgeInsets.only(top: 50),
                      child: const Column(
                        children: [
                          Icon(Icons.catching_pokemon, size: 80, color: Colors.white60),
                          SizedBox(height: 20),
                          Text(
                            'Ingresa el nombre de un Pokémon para comenzar',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPokemonCard() {
    final name = _pokemonData!['name'];
    final id = _pokemonData!['id'];
    final imageUrl = _pokemonData!['sprites']['front_default'];
    final types = (_pokemonData!['types'] as List).map<String>((type) => type['type']['name'] as String).toList();
    final abilities = (_pokemonData!['abilities'] as List).map<String>((ability) => ability['ability']['name'] as String).toList();
    final stats = _pokemonData!['stats'] as List;
    final height = _pokemonData!['height'] / 10; // Convertir a metros
    final weight = _pokemonData!['weight'] / 10; // Convertir a kg

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Encabezado con ID y nombre
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${id.toString().padLeft(3, '0')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  name[0].toUpperCase() + name.substring(1),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Botón de sonido
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.volume_up : Icons.volume_off,
                      color: _isPlaying ? Colors.red.shade300 : Colors.white70,
                    ),
                    onPressed: _isPlaying ? _stopSound : () => _playPokemonSound(id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Imagen del Pokémon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 150,
                placeholder: (context, url) => const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            // Tipos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: types.map((type) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Características
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeature('Altura', '${height.toStringAsFixed(1)} m', Icons.height),
                _buildFeature('Peso', '${weight.toStringAsFixed(1)} kg', Icons.scale),
              ],
            ),
            const SizedBox(height: 20),

            // Habilidades
            const Text(
              'Habilidades',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: abilities.map((ability) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    ability,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Estadísticas
            const Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: stats.map<Widget>((stat) {
                final statName = stat['stat']['name'];
                final statValue = stat['base_stat'];
                return _buildStatBar(statName, statValue);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.white70),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String statName, int statValue) {
    final percentage = (statValue / 150).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              statName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                widthFactor: percentage,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getStatColor(statValue),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            statValue.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.yellow;
      case 'psychic':
        return Colors.pink;
      case 'ice':
        return Colors.lightBlue;
      case 'dragon':
        return Colors.indigo;
      case 'fairy':
        return Colors.pink.shade200;
      case 'fighting':
        return Colors.red.shade900;
      case 'poison':
        return Colors.purple;
      case 'ground':
        return Colors.orange.shade800;
      case 'flying':
        return Colors.blue.shade300;
      case 'bug':
        return Colors.green.shade600;
      case 'rock':
        return Colors.grey.shade700;
      case 'ghost':
        return Colors.purple.shade800;
      case 'steel':
        return Colors.grey;
      case 'dark':
        return Colors.grey.shade900;
      default:
        return Colors.grey;
    }
  }

  Color _getStatColor(int value) {
    if (value >= 100) return Colors.green;
    if (value >= 75) return Colors.yellow;
    if (value >= 50) return Colors.orange;
    return Colors.red;
  }
}
