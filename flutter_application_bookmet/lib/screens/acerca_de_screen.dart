import 'package:flutter/material.dart';

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({Key? key}) : super(key: key);

  final Color kPrimaryOrange = const Color(0xFFFF8A00); // Naranja de tu imagen
  final Color kDarkBlue = const Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. La misma NavBar, pero ahora con funcionalidad
            _buildNavBar(context),

            // 2. Sección Principal Naranja (Basada en tu diseño de Figma)
            Container(
              width: double.infinity,
              color: kPrimaryOrange,
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.1, 
                vertical: 60
              ),
              child: size.width > 800 
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 4, child: _buildCircularImage()),
                        const SizedBox(width: 60),
                        Expanded(flex: 6, child: _buildTextContent()),
                      ],
                    )
                  : Column( // Si la pantalla es pequeña, apilamos los elementos
                      children: [
                        _buildCircularImage(),
                        const SizedBox(height: 40),
                        _buildTextContent(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- El placeholder del círculo con los libros ---
  Widget _buildCircularImage() {
    return Container(
      height: 400,
      width: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 8), // Borde blanco grueso
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 80, color: kPrimaryOrange),
            const SizedBox(height: 10),
            const Text(
              'SUMÉRGETE EN\nMUNDOS INFINITOS',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown),
            ),
          ],
        ),
      ),
    );
  }

  // --- El contenido de texto (Misión, Visión y Estadísticas) ---
  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¡Bienvenido a BOOKMET!',
          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text(
          'Accede a una de las colecciones más completas del país. Disfruta de espacios de estudio colaborativo, consulta bases de datos de clase mundial y encuentra el soporte académico necesario para llevar tu carrera al siguiente nivel. ¡Explora, investiga e innova con nosotros!',
          style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 30),
        
        // Misión
        const Text('Nuestra Misión', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Buscamos que el acceso a materiales de estudio en la UNIMET deje de ser un obstáculo. Nuestra misión es conectar a la comunidad universitaria a través de una plataforma donde el intercambio y la venta de materiales de estudio sean procesos ágiles, seguros y totalmente trazables.',
          style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 20),

        // Visión
        const Text('Nuestra Visión', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Queremos ser el ecosistema digital de referencia para el material académico en la universidad. Nos vemos como una herramienta centralizada que simplifique la vida del estudiante y el docente, haciendo que gestionar recursos sea algo orgánico y eficiente.',
          style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 40),

        // Estadísticas de la imagen
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStat('3k+', 'Recursos\nAcadémicos'),
            _buildStat('5K+', 'Miembros\nComunidad'),
            _buildStat('200+', 'Bases de Datos\ny Revistas'),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(number, style: const TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // --- NavBar (Reutilizada con rutas) ---
  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Row(
        children: [
          Icon(Icons.local_library_rounded, color: kPrimaryOrange, size: 40),
          const SizedBox(width: 10),
          Text('BOOKMET', style: TextStyle(color: kPrimaryOrange, fontSize: 22, fontWeight: FontWeight.bold)),
          const Spacer(), 
          if (MediaQuery.of(context).size.width > 800) ...[
            _buildNavLink(context, 'Inicio', '/'),
            _buildNavLink(context, 'Acerca de', '/acerca_de'),
            _buildNavLink(context, 'Catálogo', '/catalogo'),
            const SizedBox(width: 30),
          ],
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kDarkBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
            child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, String title, String route) {
    // Detecta en qué pantalla estamos para poner el texto en naranja o gris
    bool isActive = ModalRoute.of(context)?.settings.name == route;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: TextButton(
        // ¡Aquí está la magia de la navegación!
        onPressed: () => Navigator.pushReplacementNamed(context, route),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? kPrimaryOrange : Colors.grey[700],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}