import 'package:flutter/material.dart';
import 'publicacion_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({Key? key}) : super(key: key);

  @override
  _CatalogoScreenState createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  // Variables de los nuevos filtros
  String _filtroCarrera = 'Carrera (Todas)';
  String _filtroMateria = 'Materia (Todas)';
  String _filtroOrden = 'Más reciente';
  String _filtroCondicion = 'Condición (Todas)';
  DateTime? _fechaSeleccionada;

  // Función para elegir una fecha exacta de publicación
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.orange),
          ),
          child: child!,
        );
      },
    );
    if (seleccion != null && seleccion != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = seleccion;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. ZONA DE BÚSQUEDA Y FILTROS
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Buscador
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por título o autor...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Filtros (Usamos Wrap para que se acomoden solos en varias líneas)
              Wrap(
                spacing: 8.0, // Espacio horizontal entre filtros
                runSpacing: 8.0, // Espacio vertical si bajan de línea
                children: [
                  _buildDropdownFiltro(
                    valorActual: _filtroCarrera,
                    opciones: ['Carrera (Todas)', 'Ing. Sistemas', 'Ing. Civil', 'Administración'],
                    alCambiar: (val) => setState(() => _filtroCarrera = val!),
                  ),
                  _buildDropdownFiltro(
                    valorActual: _filtroMateria,
                    opciones: ['Materia (Todas)', 'Programación I', 'Matemáticas I', 'Física I'],
                    alCambiar: (val) => setState(() => _filtroMateria = val!),
                  ),
                  _buildDropdownFiltro(
                    valorActual: _filtroCondicion,
                    opciones: ['Condición (Todas)', 'Disponible', 'Reservado'],
                    alCambiar: (val) => setState(() => _filtroCondicion = val!),
                  ),
                  _buildDropdownFiltro(
                    valorActual: _filtroOrden,
                    opciones: ['Más reciente', 'Menos reciente'],
                    alCambiar: (val) => setState(() => _filtroOrden = val!),
                  ),
                  // Botón para filtro por fecha exacta
                  OutlinedButton.icon(
                    onPressed: () => _seleccionarFecha(context),
                    icon: const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
                    label: Text(
                      _fechaSeleccionada == null 
                          ? 'Fecha exacta' 
                          : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
                      style: const TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  // Botón para limpiar la fecha
                  if (_fechaSeleccionada != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                      onPressed: () => setState(() => _fechaSeleccionada = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                ],
              ),
            ],
          ),
        ),

        // 2. CUADRÍCULA DE LIBROS (4 columnas)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // ¡4 COLUMNAS POR FILA!
              childAspectRatio: 0.55, // Hacemos las tarjetas un poco más altas para que quepa el texto
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 12, // Libros de ejemplo
            itemBuilder: (context, index) {
              return LibroGridCardInteractiva(index: index); // Usamos el nuevo widget
            },
          ),
        ),
      ],
    );
  }

  // Menú desplegable compacto para los filtros
  Widget _buildDropdownFiltro({required String valorActual, required List<String> opciones, required Function(String?) alCambiar}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valorActual,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.orange, size: 20),
          isDense: true, // Lo hace más compacto
          items: opciones.map((String opcion) {
            return DropdownMenuItem<String>(
              value: opcion,
              child: Text(opcion, style: const TextStyle(fontSize: 12)), // Letra pequeña para ahorrar espacio
            );
          }).toList(),
          onChanged: alCambiar,
        ),
      ),
    );
  }
}

// Nuevo Widget interactivo para cada libro del Grid
class LibroGridCardInteractiva extends StatefulWidget {
  final int index;
  const LibroGridCardInteractiva({Key? key, required this.index}) : super(key: key);

  @override
  _LibroGridCardInteractivaState createState() => _LibroGridCardInteractivaState();
}

class _LibroGridCardInteractivaState extends State<LibroGridCardInteractiva> {
  bool _isHovered = false; // Controla si el ratón está encima

  @override
  Widget build(BuildContext context) {
    bool disponible = widget.index % 3 != 0; 

    // MouseRegion detecta el ratón y cambia el cursor a la "manito"
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PublicacionScreen()), 
          );
        },
        // AnimatedScale hace que la tarjeta crezca un 3% cuando _isHovered es true
        child: AnimatedScale(
          scale: _isHovered ? 1.03 : 1.0, 
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Card(
            elevation: _isHovered ? 8 : 2, // La sombra también crece
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    color: disponible ? Colors.orange[100] : Colors.grey[300], 
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.menu_book, size: 30, color: disponible ? Colors.orange : Colors.grey),
                        if (!disponible)
                          Container(
                            color: Colors.black54,
                            width: double.infinity,
                            child: const Text('RESERVADO', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Libro ${widget.index}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('Ing. Sistemas', style: TextStyle(color: Colors.grey[600], fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Text(
                          disponible ? 'Disponible' : 'No Disponible', 
                          style: TextStyle(color: disponible ? Colors.green : Colors.red, fontSize: 9, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}