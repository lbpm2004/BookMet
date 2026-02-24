import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // Definimos los colores del diseño para usarlos fácilmente
  final Color kPrimaryOrange = const Color(0xFFF57C00); // Naranja similar al diseño
  final Color kDarkBlue = const Color(0xFF0D47A1);      // Azul oscuro del botón

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para hacer el diseño responsivo si es necesario
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco limpio
      body: SingleChildScrollView(
        // Permite scroll si la pantalla es muy pequeña verticalmente
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Barra de Navegación Superior (NavBar)
            _buildNavBar(context),

            const SizedBox(height: 60), // Espacio vertical

            // 2. Contenido Principal (Texto Central)
            _buildMainContent(size),

            const SizedBox(height: 40), // Espacio antes de la ilustración

            // 3. Ilustración y Footer Inferior
            _buildFooterIllustration(size),
          ],
        ),
      ),
    );
  }

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
            // ¡Navegación al Login!
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
    bool isActive = ModalRoute.of(context)?.settings.name == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: TextButton(
        // ¡Navegación a las otras pantallas!
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

  // --- Widget del Contenido Central de Texto ---
  Widget _buildMainContent(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1), // Margen horizontal dinámico
      child: Column(
        children: [
          Text(
            '¡Tu Centro de Conocimiento te Espera!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kPrimaryOrange,
              fontSize: size.width > 600 ? 42 : 32, // Fuente más pequeña en móviles
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            constraints: const BoxConstraints(maxWidth: 800), // Limita el ancho del párrafo
            child: Text(
              'Bienvenido al corazón académico de la UNIMET. Únete a nuestra comunidad de aprendizaje y sumérgete en un entorno en constante evolución, donde cada libro y recurso digital es una oportunidad para innovar e inspirar tu futuro profesional.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 18,
                height: 1.5, // Altura de línea para mejor lectura
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget de la Ilustración y Footer ---
  Widget _buildFooterIllustration(Size size) {
    // Usamos un Stack para superponer el libro sobre la onda naranja
    return SizedBox(
      height: 300, // Altura fija para el área del footer
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Capa inferior: La onda naranja
          // --- REEMPLAZAR ESTE CONTAINER POR TU IMAGEN DE LA ONDA NARANJA ---
          // Image.asset('assets/images/footer_wave.png', width: double.infinity, fit: BoxFit.cover),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: kPrimaryOrange,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(50), // Simulando un poco la onda
                topRight: Radius.circular(50),
              ),
            ),
          ),

          // Capa superior: El libro abierto
          Positioned(
            bottom: 20, // Lo subimos un poco para que parezca salir de la onda
            // --- REEMPLAZAR ESTE ICONO POR TU IMAGEN DEL LIBRO ---
            // child: Image.asset('assets/images/open_book_illustration.png', height: 250),
            child: Icon(
              Icons.menu_book_rounded, // Icono temporal de libro
              size: 200,
              color: kPrimaryOrange.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}