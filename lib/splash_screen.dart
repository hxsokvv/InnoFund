import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController controller1;
  late AnimationController controller2;
  late AnimationController controller3;
  late AnimationController controller4;
  late AnimationController controller5;

  late Animation<double> animation1;
  late Animation<double> animation2;
  late Animation<double> animation3;
  late Animation<double> animation4;
  late Animation<double> animation5;

  @override
  void initState() {
    super.initState();

    // Configuración de animaciones para cada círculo
    controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    animation1 = Tween<double>(begin: 0.3, end: 0.4).animate(
      CurvedAnimation(parent: controller1, curve: Curves.easeInOut),
    );

    controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    animation2 = Tween<double>(begin: 0.75, end: 0.65).animate(
      CurvedAnimation(parent: controller2, curve: Curves.easeInOut),
    );

    controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
    animation3 = Tween<double>(begin: 0.5, end: 0.6).animate(
      CurvedAnimation(parent: controller3, curve: Curves.easeInOut),
    );

    controller4 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    animation4 = Tween<double>(begin: 0.2, end: 0.3).animate(
      CurvedAnimation(parent: controller4, curve: Curves.easeInOut),
    );

    controller5 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
    animation5 = Tween<double>(begin: 0.1, end: 0.15).animate(
      CurvedAnimation(parent: controller5, curve: Curves.easeInOut),
    );

    // Navegar al login después de 4 segundos
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    controller3.dispose();
    controller4.dispose();
    controller5.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xffEAEAEA),
      body: Stack(
        children: [
          // Animaciones de los círculos
          AnimatedBuilder(
            animation: controller1,
            builder: (context, child) {
              return Positioned(
                top: size.height * animation1.value,
                left: size.width * 0.15,
                child: CustomPaint(
                  painter: MyPainter(120, Colors.blueAccent.withOpacity(0.4)),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: controller2,
            builder: (context, child) {
              return Positioned(
                top: size.height * animation2.value,
                left: size.width * 0.3,
                child: CustomPaint(
                  painter: MyPainter(180, Colors.grey.withOpacity(0.3)),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: controller3,
            builder: (context, child) {
              return Positioned(
                top: size.height * animation3.value,
                left: size.width * 0.7,
                child: CustomPaint(
                  painter:
                      MyPainter(140, Colors.lightBlueAccent.withOpacity(0.5)),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: controller4,
            builder: (context, child) {
              return Positioned(
                top: size.height * animation4.value,
                left: size.width * 0.75,
                child: CustomPaint(
                  painter: MyPainter(100, Colors.blueGrey.withOpacity(0.5)),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: controller5,
            builder: (context, child) {
              return Positioned(
                top: size.height * animation5.value,
                left: size.width * 0.4,
                child: CustomPaint(
                  painter: MyPainter(160, Colors.blueAccent.withOpacity(0.3)),
                ),
              );
            },
          ),

          // Contenido principal: logo y texto
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo circular con "iF"
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white, // Fondo del círculo
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'i',
                            style: TextStyle(
                              color:
                                  Colors.blueAccent, // Color azul para la "i"
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          TextSpan(
                            text: 'F',
                            style: TextStyle(
                              color: Colors.black, // Color negro para la "F"
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Texto "InnoFund" (Título principal)
                const Text(
                  'InnoFund',
                  style: TextStyle(
                    fontSize: 36, // Tamaño más grande
                    fontWeight:
                        FontWeight.w700, // Bold para un diseño más marcado
                    color:
                        Color(0xFF222222), // Gris oscuro profundo (casi negro)
                    fontFamily: 'Roboto', // Fuente moderna
                  ),
                ),
                const SizedBox(height: 10),

                // Texto "Innovar, Crear" (Subtítulo)
                const Text(
                  'EMPRENDER, iNVERTIR',
                  style: TextStyle(
                    fontSize: 20, // Aumentamos el tamaño para mejor visibilidad
                    color: Colors.black, // Negro para mayor contraste
                    letterSpacing: 2, // Espaciado entre letras
                    fontWeight: FontWeight.w500, // Peso intermedio
                    fontFamily: 'Roboto', // Fuente clara y moderna
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final double radius;
  final Color color;

  MyPainter(this.radius, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true; // Redibujar siempre
  }
}
