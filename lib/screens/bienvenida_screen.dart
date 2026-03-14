import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  final Color kPrimaryOrange = const Color(0xFFFF8200); 
  final Color kDarkBlue = const Color(0xFF003087);      

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white, 
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            _buildNavBar(context, user),

            const SizedBox(height: 60),
            _buildMainContent(size),

            const SizedBox(height: 40),
            _buildFooterIllustration(size),

            Transform.translate( 
              offset: const Offset(0, -1),
              child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, 
                      end: Alignment.bottomCenter, 
                      colors: [const Color(0xFFFFA522), kPrimaryOrange], 
                      stops: const [0.0, 0.2]
                    )
                  ),
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.1, vertical: 60),
                  child: size.width > 800 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children:[
                            Expanded(flex: 4, child: _buildCircularImage()),
                            const SizedBox(width: 60),
                            Expanded(flex: 6, child: _buildTextContent()),
                          ],
                        )
                      : Column( 
                          children:[
                            _buildCircularImage(),
                            const SizedBox(height: 40),
                            _buildTextContent(),
                          ],
                        ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, User? user) {
    //Detectando el ancho para saber si es un celular:
    final double ancho = MediaQuery.of(context).size.width;
    final bool esMovil = (ancho < 600);

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Header.png'),
          fit: BoxFit.cover,
        )
      ),
      //cambiado a padding dinámico dependiendo de si es un celular o no:
      padding: EdgeInsets.only(left: esMovil? 10 : 25, right: esMovil? 5 : 15, top: 20, bottom: 20),
      child: Row(
        children:[
          Icon(Icons.local_library_rounded, color: kPrimaryOrange, size: esMovil? 30 : 40),

          const SizedBox(width: 10),
          Text('BOOKMET', style: TextStyle(color: kPrimaryOrange, fontSize: esMovil? 16 : 22, fontWeight: FontWeight.bold)),
          
          const Spacer(), 

          // Botones si NO hay sesión
          Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user == null) ...[
                  _wrapFlexible(
                    esMovil: esMovil,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDarkBlue, // Mismo color (Azul oscuro)
                        padding: EdgeInsets.symmetric(horizontal: esMovil? 8 : 20, vertical: esMovil? 12 : 18),
                      ),
                      child: Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontSize: esMovil? 12 : 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                    SizedBox(width: esMovil ? 8 : 20),
                    _wrapFlexible(
                      esMovil: esMovil,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/registro'),            
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkBlue, // Cambiado al mismo color que Iniciar Sesión
                          padding: EdgeInsets.symmetric(horizontal: esMovil? 8 : 24, vertical: esMovil? 12 : 18),
                        ),
                        child: Text('Registrarse', style: TextStyle(color: Colors.white, fontSize: esMovil? 12 : 14, fontWeight: FontWeight.bold)),
                      )
                  )
                ] 
                // Botones si SÍ hay sesión
                else ...[
                ElevatedButton.icon(
                  onPressed: () => _redirigirAlPanel(context, user.uid),
                  icon: Icon(Icons.dashboard, color: Colors.white, size: esMovil? 18 : 24),
                  label: Text('Ir al Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkBlue, // Unificado al azul oscuro
                    padding: EdgeInsets.symmetric(horizontal: esMovil? 12 : 24, vertical: 18)
                  )
                ),
              ]
              ],
          )
      ]),
    );
  }

void _redirigirAlPanel(BuildContext context, String uid) async {
  try {
    // Consultamos el documento del usuario en la colección 'usuarios'
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    if (userDoc.exists) {
      String rol = userDoc.get('rol') ?? 'USER';

      if (rol == 'ADMINISTRADOR') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/usuario');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/usuario');
    }
  } catch (e) {
      print("Error al verificar rol: $e");
      Navigator.pushReplacementNamed(context, '/usuario');
  }
}

  Widget _buildMainContent(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
      child: Column(
        children:[
          Text(
            '¡Tu Centro de Conocimiento te Espera!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kPrimaryOrange,
              fontSize: size.width > 600 ? 42 : 32, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            constraints: const BoxConstraints(maxWidth: 800), 
            child: Text(
              'Bienvenido al corazón académico de la UNIMET. Únete a nuestra comunidad de aprendizaje y sumérgete en un entorno en constante evolución, donde cada libro y recurso digital es una oportunidad para innovar e inspirar tu futuro profesional.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 18, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapFlexible({required bool esMovil, required Widget child}) {
    return esMovil ? Flexible(fit: FlexFit.loose, child: child) : child;
  }

  Widget _buildFooterIllustration(Size size) {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/Book - transition.png',
        width: size.width,
        fit: BoxFit.fitWidth,
        gaplessPlayback: true,
      )
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text('¡Bienvenido a BOOKMET!', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const Text('Accede a una de las colecciones más completas del país. Disfruta de espacios de estudio colaborativo, consulta bases de datos de clase mundial y encuentra el soporte académico necesario para llevar tu carrera al siguiente nivel. ¡Explora, investiga e innova con nosotros!', style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        const SizedBox(height: 30),
        const Text('Nuestra Misión', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Buscamos que el acceso a materiales de estudio en la UNIMET deje de ser un obstáculo. Nuestra misión es conectar a la comunidad universitaria a través de una plataforma donde el intercambio y la venta de materiales de estudio sean procesos ágiles, seguros y totalmente trazables.', style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        const SizedBox(height: 20),
        const Text('Nuestra Visión', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Queremos ser el ecosistema digital de referencia para el material académico en la universidad. Nos vemos como una herramienta centralizada que simplifique la vida del estudiante y el docente, haciendo que gestionar recursos sea algo orgánico y eficiente.', style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            _buildStat('3k+', 'Recursos\nAcadémicos'),
            _buildStat('5K+', 'Miembros\nComunidad'),
            _buildStat('200+', 'Bases de Datos\ny Revistas'),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularImage() {
    return Container(
      height: 400,
      width: 400,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow:[BoxShadow(color: Colors.black26, blurRadius: 10)],
        image: DecorationImage(image: AssetImage('assets/images/Acerca_de.png'))
      ),
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text(number, style: const TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}