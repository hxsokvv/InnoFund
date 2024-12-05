import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Importa las páginas necesarias
import 'post_detail_page.dart';
import 'comments_page.dart';
import 'wallet_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImageUrl;
  String? _coverImageUrl;

  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _studyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _hometownController = TextEditingController();

  // Variables para niveles
  int currentLevel = 1;
  double progressToNextLevel = 0.0;
  List<dynamic> benefits = [];

  // Variable para el tipo de usuario
  String userType = 'Emprendedor'; // Valor por defecto

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserLevel();
  }

  // Cargar datos del usuario
  Future<void> _loadUserData() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(widget.userId).get();
    if (userDoc.exists) {
      var userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _profileImageUrl = userData['profilePicture'];
        _coverImageUrl = userData['coverPicture'];
        _bioController.text = userData['bio'] ?? '';
        _jobController.text = userData['job'] ?? '';
        _companyController.text = userData['company'] ?? '';
        _studyController.text = userData['study'] ?? '';
        _locationController.text = userData['location'] ?? '';
        _hometownController.text = userData['hometown'] ?? '';
        userType = userData['userType'] ?? 'Emprendedor'; // Agregado
      });
    }
  }

  // Cargar datos del nivel del usuario
  Future<void> _loadUserLevel() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(widget.userId).get();
    if (userDoc.exists) {
      var userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        currentLevel = userData['currentLevel'] ?? 1;
        progressToNextLevel =
            userData['progressToNextLevel']?.toDouble() ?? 0.0;
      });

      // Cargar beneficios del nivel actual
      QuerySnapshot levelsSnapshot = await _firestore
          .collection('levels')
          .where('levelNumber', isEqualTo: currentLevel)
          .get();

      if (levelsSnapshot.docs.isNotEmpty) {
        var levelData =
            levelsSnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          benefits = levelData['benefits'] ?? [];
        });
      }
    }
  }

  // Método para subir y actualizar imágenes
  Future<void> _pickAndUploadImage({required bool isProfile}) async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      File imageFile = File(pickedFile.path);
      setState(() {
        _isLoading = true;
      });

      String? downloadUrl = await _uploadImage(imageFile, isProfile: isProfile);
      if (downloadUrl != null) {
        await _firestore.collection('users').doc(widget.userId).update({
          isProfile ? 'profilePicture' : 'coverPicture': downloadUrl,
        });
        setState(() {
          if (isProfile) {
            _profileImageUrl = downloadUrl;
          } else {
            _coverImageUrl = downloadUrl;
          }
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${isProfile ? "Foto de perfil" : "Foto de portada"} actualizada correctamente')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen: $e')),
      );
    }
  }

  // Subir imagen a Firebase Storage
  Future<String?> _uploadImage(File imageFile,
      {required bool isProfile}) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = FirebaseStorage.instance.ref().child(
          '${isProfile ? 'profilePictures' : 'coverPictures'}/${widget.userId}/$fileName');

      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot storageSnapshot = await uploadTask;

      return await storageSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error al subir la imagen: $e');
      return null;
    }
  }

  // Actualizar perfil del usuario
  Future<void> _updateProfile() async {
    try {
      await _firestore.collection('users').doc(widget.userId).update({
        'bio': _bioController.text,
        'job': _jobController.text,
        'company': _companyController.text,
        'study': _studyController.text,
        'location': _locationController.text,
        'hometown': _hometownController.text,
      });

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el perfil: $e')),
      );
    }
  }

  // Método para actualizar donaciones y niveles
  Future<void> _updateDonationsReceived(double donationAmount) async {
    DocumentReference userRef =
        _firestore.collection('users').doc(widget.userId);

    // Declarar variables fuera de la transacción
    int newLevel = currentLevel;
    double newDonations = 0.0;
    double newProgress = progressToNextLevel;
    bool levelUp = false;

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          throw Exception("Usuario no encontrado");
        }

        double currentDonations =
            (userSnapshot.get('donationsReceived') as num?)?.toDouble() ?? 0.0;
        newDonations = currentDonations + donationAmount;

        // Obtener los niveles ordenados por requiredDonations ascendente
        QuerySnapshot levelsSnapshot = await _firestore
            .collection('levels')
            .orderBy('requiredDonations', descending: false)
            .get();

        // Determinar el nuevo nivel basado en las donaciones
        for (var levelDoc in levelsSnapshot.docs) {
          double requiredDonations =
              (levelDoc.get('requiredDonations') as num).toDouble();
          if (newDonations >= requiredDonations) {
            newLevel = levelDoc.get('levelNumber');
          } else {
            break;
          }
        }

        // Capping del nivel máximo a 3
        if (newLevel > 3) {
          newLevel = 3;
        }

        // Calcular progreso hacia el siguiente nivel
        if (newLevel < 3) {
          double donationsForCurrentLevel = (levelsSnapshot.docs[newLevel - 1]
                  .get('requiredDonations') as num)
              .toDouble();
          double donationsForNextLevel =
              (levelsSnapshot.docs[newLevel].get('requiredDonations') as num)
                  .toDouble();
          newProgress = ((newDonations - donationsForCurrentLevel) /
                  (donationsForNextLevel - donationsForCurrentLevel)) *
              100;
        } else {
          newProgress = 100.0;
        }

        // Detectar si ha subido de nivel
        if (newLevel > currentLevel) {
          levelUp = true;
        }

        // Actualizar el documento del usuario
        transaction.update(userRef, {
          'donationsReceived': newDonations,
          'currentLevel': newLevel,
          'progressToNextLevel': newProgress.clamp(0.0, 100.0),
        });
      });

      // Recargar los datos del perfil para reflejar los cambios
      await _loadUserData();
      await _loadUserLevel();

      // Mostrar diálogo si subió de nivel
      if (levelUp) {
        _showLevelUpDialog(newLevel);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Donaciones y niveles actualizados correctamente.')),
      );
    } catch (error) {
      print("Error al actualizar donaciones y niveles: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar niveles: $error')),
      );
    }
  }

  // Mostrar diálogo al alcanzar un nuevo nivel
  void _showLevelUpDialog(int newLevel) {
    // Seleccionar un icono basado en el nuevo nivel
    IconData levelIcon;
    Color iconColor;

    switch (newLevel) {
      case 2:
        levelIcon = Icons.looks_two;
        iconColor = Colors.green;
        break;
      case 3:
        levelIcon = Icons.looks_3;
        iconColor = Colors.orange;
        break;
      default:
        levelIcon = Icons.star;
        iconColor = Colors.blue;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                levelIcon,
                color: iconColor,
                size: 30,
              ),
              const SizedBox(width: 10),
              const Text('¡Felicidades!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Has alcanzado el Nivel $newLevel',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _getBenefitsForLevel(newLevel),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Obtener beneficios para el nivel alcanzado
  String _getBenefitsForLevel(int level) {
    switch (level) {
      case 1:
        return "Beneficios:\n• Acceso básico\n• Soporte limitado";
      case 2:
        return "Beneficios:\n• Acceso intermedio\n• Soporte prioritario";
      case 3:
        return "Beneficios:\n• Acceso completo\n• Soporte dedicado\n• Beneficios exclusivos";
      default:
        return "Beneficios no definidos.";
    }
  }

  // Widget para mostrar los detalles del perfil
  Widget _buildDetailRow(IconData icon, String label,
      TextEditingController controller, bool isEditing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: label,
                    ),
                  )
                : Text(
                    controller.text.isNotEmpty
                        ? controller.text
                        : 'No especificado',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar la barra de progreso de nivel
  Widget _buildLevelProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Nivel Actual: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildLevelIcon(currentLevel),
              const SizedBox(width: 5),
              // Icono de información
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                ),
                onPressed: _showLevelsInfo,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progressToNextLevel / 100, // Convertir porcentaje a decimal
            backgroundColor: Colors.grey[300],
            color: Colors.blueAccent,
            minHeight: 10,
          ),
          const SizedBox(height: 4),
          Text(
            currentLevel < 3
                ? '${progressToNextLevel.toStringAsFixed(0)}% hacia el siguiente nivel'
                : '¡Has alcanzado el Nivel 3!',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Método para mostrar la información de los niveles
  void _showLevelsInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _buildLevelsInfoContent(),
        );
      },
    );
  }

  // Contenido de la ventana emergente de información de niveles
  Widget _buildLevelsInfoContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Información de Niveles',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20.0),
          // Lista de niveles
          Column(
            children: [
              _buildLevelInfoCard(
                  levelNumber: 1,
                  requiredDonations: 0,
                  benefits: ["Acceso básico", "Soporte limitado"],
                  icon: Icons.looks_one,
                  iconColor: Colors.blue),
              _buildLevelInfoCard(
                  levelNumber: 2,
                  requiredDonations: 600,
                  benefits: ["Acceso intermedio", "Soporte prioritario"],
                  icon: Icons.looks_two,
                  iconColor: Colors.green),
              _buildLevelInfoCard(
                  levelNumber: 3,
                  requiredDonations: 12000,
                  benefits: [
                    "Acceso completo",
                    "Soporte dedicado",
                    "Beneficios exclusivos"
                  ],
                  icon: Icons.looks_3,
                  iconColor: Colors.orange),
            ],
          ),
          const SizedBox(height: 20.0),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para cada tarjeta de información de nivel
  Widget _buildLevelInfoCard({
    required int levelNumber,
    required double requiredDonations,
    required List<String> benefits,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 40,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nivel $levelNumber',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Puntos Requeridos: $requiredDonations',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Beneficios:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  ...benefits.map((benefit) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                benefit,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar los beneficios del nivel
  Widget _buildBenefits() {
    if (benefits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Beneficios del Nivel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...benefits.map((benefit) => Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  // Widget para mostrar la barra de progreso de nivel y beneficios
  Widget _buildLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLevelProgressBar(),
        _buildBenefits(),
        const Divider(thickness: 1.0),
      ],
    );
  }

  // Widget para la sección de portafolio
  Widget _buildPortfolio() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('projects')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No hay proyectos en el portafolio.'));
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: snapshot.data!.docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            var project = snapshot.data!.docs[index];
            var projectData = project.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                // Navegar a la página de detalles del proyecto
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailPage(projectId: project.id),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: projectData['imageUrls'] != null &&
                                projectData['imageUrls'].isNotEmpty
                            ? Image.network(
                                projectData['imageUrls'][0],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        projectData['description'] ?? 'Sin descripción',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget para mostrar el icono del nivel
  Widget _buildLevelIcon(int level) {
    IconData iconData;
    Color iconColor;

    switch (level) {
      case 1:
        iconData = Icons.looks_one;
        iconColor = Colors.blue;
        break;
      case 2:
        iconData = Icons.looks_two;
        iconColor = Colors.green;
        break;
      case 3:
        iconData = Icons.looks_3;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.star;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor, size: 30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Usuario'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream:
                  _firestore.collection('users').doc(widget.userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Usuario no encontrado'));
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sección de foto de portada y foto de perfil
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_isEditing) {
                                _pickAndUploadImage(isProfile: false);
                              }
                            },
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: _coverImageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_coverImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.grey[300],
                              ),
                              child: _coverImageUrl == null
                                  ? Center(
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Colors.grey[700],
                                        size: 50,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: GestureDetector(
                                onTap: () {
                                  if (_isEditing) {
                                    _pickAndUploadImage(isProfile: true);
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundImage: _profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : const AssetImage(
                                              'assets/default_profile.png')
                                          as ImageProvider,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Información básica y detalles adicionales
                      Text(
                        userData['name'] ?? 'Nombre desconocido',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userData['email'] ?? 'Correo desconocido',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Barra de progreso de nivel y beneficios
                      _buildLevelSection(),

                      // Detalles del perfil
                      _buildDetailRow(FontAwesomeIcons.briefcase, 'Profesión',
                          _jobController, _isEditing),
                      _buildDetailRow(FontAwesomeIcons.building, 'Empresa',
                          _companyController, _isEditing),
                      _buildDetailRow(FontAwesomeIcons.graduationCap,
                          'Estudios', _studyController, _isEditing),
                      _buildDetailRow(FontAwesomeIcons.houseUser, 'Vive en:',
                          _locationController, _isEditing),
                      _buildDetailRow(FontAwesomeIcons.mapMarkerAlt, 'De:',
                          _hometownController, _isEditing),
                      const SizedBox(height: 16),
                      if (_isEditing)
                        ElevatedButton(
                          onPressed: _updateProfile,
                          child: const Text('Guardar Cambios'),
                        ),
                      const SizedBox(height: 16),

                      // Sección de portafolio (Solo para Emprendedores)
                      if (userType == 'Emprendedor') ...[
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Portafolio',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        _buildPortfolio(),
                      ],

                      // Botón para Simular Donación (Para Pruebas)
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _updateDonationsReceived(
                              300); // Simular una donación de 300 puntos
                        },
                        child: const Text('Simular Donación (+300 puntos)'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
