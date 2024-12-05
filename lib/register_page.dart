import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  String? _studyHouse;
  String? _userType;
  bool _isLoading = false;
  bool _termsAccepted = false; // Control para aceptar términos

  // Control de pasos visibles
  int _currentStep = 1;

  // Lista de universidades en Chile
  final List<String> _universities = [
    "Universidad de Chile",
    "Pontificia Universidad Católica de Chile",
    "Universidad de Santiago de Chile",
    "Universidad de Valparaíso",
    "Universidad de Concepción",
    "Universidad de La Frontera",
    "Universidad de Talca",
    "Universidad de Antofagasta",
    "Universidad de Atacama",
    "Universidad de Tarapacá",
    "Universidad de Los Lagos",
    "Universidad de Magallanes",
    "Universidad de Playa Ancha",
    "Universidad Metropolitana de Ciencias de la Educación",
    "Universidad Tecnológica Metropolitana",
    "Universidad de O'Higgins",
    "Universidad de Aysén",
    "Universidad Técnica Federico Santa María",
    "Pontificia Universidad Católica de Valparaíso",
    "Universidad Austral de Chile",
    "Universidad Católica del Norte",
    "Universidad Diego Portales",
    "Universidad Adolfo Ibáñez",
    "Universidad Andrés Bello",
    "Universidad del Desarrollo",
    "Universidad Finis Terrae",
    "Universidad Mayor",
    "Universidad Alberto Hurtado",
    "Universidad de Los Andes",
    "Universidad San Sebastián",
    "Universidad Central de Chile",
    "Universidad Santo Tomás",
    "Universidad Católica Silva Henríquez",
    "Universidad Tecnológica de Chile INACAP",
  ];

  late List<String> _uniqueUniversities;

  // Controladores de animaciones del fondo
  late AnimationController controller1;
  late AnimationController controller2;
  late AnimationController controller3;
  late AnimationController controller4;

  late Animation<double> animation1;
  late Animation<double> animation2;
  late Animation<double> animation3;
  late Animation<double> animation4;

  @override
  void initState() {
    super.initState();

    // Elimina duplicados de la lista
    _uniqueUniversities = _universities.toSet().toList();

    // Configuración de animaciones de fondo
    controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    animation1 = Tween<double>(begin: .2, end: .25).animate(
      CurvedAnimation(
        parent: controller1,
        curve: Curves.easeInOut,
      ),
    );

    controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    animation2 = Tween<double>(begin: .05, end: .08).animate(
      CurvedAnimation(
        parent: controller2,
        curve: Curves.easeInOut,
      ),
    );

    controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    animation3 = Tween<double>(begin: .6, end: .5).animate(
      CurvedAnimation(
        parent: controller3,
        curve: Curves.easeInOut,
      ),
    );

    controller4 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    animation4 = Tween<double>(begin: 200, end: 150).animate(
      CurvedAnimation(
        parent: controller4,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    controller3.dispose();
    controller4.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    if (_nameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _studyHouse == null ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _userType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return false;
    }
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Debes aceptar los Términos y Condiciones')),
      );
      return false;
    }
    if (!_isValidPassword(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula, un número y un carácter especial.'),
        ),
      );
      return false;
    }
    return true;
  }

  bool _isValidPassword(String password) {
    final passwordRegExp = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegExp.hasMatch(password);
  }

  String _getPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[@$!%*?&]').hasMatch(password)) score++;

    if (score <= 2) return 'Débil';
    if (score == 3) return 'Media';
    return 'Fuerte';
  }

  double _getPasswordStrengthScore(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[@$!%*?&]').hasMatch(password)) score++;

    return score / 5; // Devuelve un valor entre 0.0 y 1.0
  }

  Future<void> _register() async {
    if (!_validateFields()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text,
        'name': _nameController.text,
        'lastName': _lastNameController.text,
        'studyHouse': _studyHouse,
        'userType': _userType,
        'uid': userCredential.user!.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado exitosamente')),
      );

      Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      if (e.code == 'email-already-in-use') {
        errorMessage = 'Este correo ya está en uso.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es muy débil.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'El correo no es válido.';
      } else {
        errorMessage = 'Ocurrió un error: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      print('Error al registrar el usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xffEAEAEA),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: controller1,
            builder: (context, child) {
              return Positioned(
                top: size.height * (animation2.value + .3),
                left: size.width * .15,
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
                top: size.height * .8,
                left: size.width * .3,
                child: CustomPaint(
                  painter:
                      MyPainter(animation4.value, Colors.grey.withOpacity(0.3)),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: controller3,
            builder: (context, child) {
              return Positioned(
                top: size.height * .5,
                left: size.width * .7,
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
                top: size.height * .2,
                left: size.width * (animation1.value + .05),
                child: CustomPaint(
                  painter: MyPainter(160, Colors.blueAccent.withOpacity(0.3)),
                ),
              );
            },
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Registro de Usuario',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_currentStep == 1) ...[
                    _buildStyledTextField(_nameController, 'Nombre'),
                    const SizedBox(height: 16),
                    _buildStyledTextField(_lastNameController, 'Apellido'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep++;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.purple[200],
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else if (_currentStep == 2) ...[
                    _buildStyledDropdown<String>(
                      label: 'Casa de estudio',
                      value: _studyHouse,
                      items: _uniqueUniversities,
                      onChanged: (String? newValue) {
                        setState(() {
                          _studyHouse = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildStyledTextField(
                        _emailController, 'Correo electrónico'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep++;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.purple[200],
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else if (_currentStep == 3) ...[
                    _buildStyledTextField(
                      _passwordController,
                      'Contraseña',
                      obscureText: true,
                      onChanged: (value) {
                        setState(() {}); // Actualiza la barra de progreso
                      },
                    ),
                    const SizedBox(height: 8),

                    // Barra de seguridad de la contraseña
                    LinearProgressIndicator(
                      value:
                          _getPasswordStrengthScore(_passwordController.text),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPasswordStrengthScore(_passwordController.text) <
                                0.4
                            ? Colors.red
                            : (_getPasswordStrengthScore(
                                        _passwordController.text) <
                                    0.8
                                ? Colors.orange
                                : Colors.green),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Seguridad: ${_getPasswordStrength(_passwordController.text)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    _buildStyledDropdown<String>(
                      label: 'Tipo de usuario',
                      value: _userType,
                      items: ['Inversionista', 'Emprendedor'],
                      onChanged: (String? newValue) {
                        setState(() {
                          _userType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: (value) {
                            setState(() {
                              _termsAccepted = value ?? false;
                            });
                          },
                        ),
                        const Text('Acepto los Términos y Condiciones'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: Colors.purple[200],
                            ),
                            child: const Text(
                              'Registrarse',
                              style: TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField(TextEditingController controller, String label,
      {bool obscureText = false, void Function(String)? onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildStyledDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<T>>((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
            border: InputBorder.none,
          ),
          isExpanded: true,
        ),
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
    return true;
  }
}
