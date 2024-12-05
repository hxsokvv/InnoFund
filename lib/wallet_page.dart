import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double walletBalance = 0.0;
  double totalDonated = 0.0;
  int totalTransactions = 0;
  int uniqueDonors = 0;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
    _fetchStatistics();
  }

  Future<void> _fetchWalletBalance() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        walletBalance =
            (userDoc.data() as Map<String, dynamic>)['walletBalance'] ?? 0.0;
      });
    }
  }

  Future<void> _fetchStatistics() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot transactionsSnapshot = await FirebaseFirestore.instance
          .collection('deposits')
          .where('userId', isEqualTo: user.uid)
          .get();

      final transactions = transactionsSnapshot.docs;
      double totalAmount = 0.0;
      Set<String> donorIds = {};

      for (var transaction in transactions) {
        Map<String, dynamic> data = transaction.data() as Map<String, dynamic>;
        totalAmount += (data['amount'] as num).toDouble();
        donorIds.add(data['userId']);
      }

      setState(() {
        totalTransactions = transactions.length;
        totalDonated = totalAmount;
        uniqueDonors = donorIds.length;
      });
    }
  }

  Widget _buildTransactionList() {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    print("UID actual del usuario: $userId"); // Depuración del UID actual

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deposits')
          .orderBy('timestamp',
              descending: true) // Eliminar filtro temporalmente
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error al cargar transacciones',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("No se encontraron transacciones.");
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No hay transacciones aún.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        final transactions = snapshot.data!.docs;

        print("Número de transacciones encontradas: ${transactions.length}");
        for (var doc in transactions) {
          print("Transacción recuperada: ${doc.data()}");
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> transactionData =
                transactions[index].data() as Map<String, dynamic>;

            String donorName = transactionData['userName'] ?? 'Anónimo';
            double amount = (transactionData['amount'] as num).toDouble();
            Timestamp timestamp = transactionData['timestamp'];

            String formattedDate = _formatDate(timestamp);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                "Donante: $donorName",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                'Donado el $formattedDate',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: Text(
                '+\$${amount.toStringAsFixed(0)} CLP',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cartera"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Botón de retroceso
          onPressed: () {
            Navigator.pop(context); // Retrocede a la pantalla anterior
          },
        ),
      ),
      body: Stack(
        children: [
          // Fondo con degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFe3f2fd), Color(0xFFe8f5e9)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Cabecera con saldo
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent.shade100,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Saldo en Cartera",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "\$${walletBalance.toStringAsFixed(0)} CLP",
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sección de estadísticas rápidas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickStat(
                        icon: Icons.trending_up,
                        title: "Transacciones",
                        value: totalTransactions.toString(),
                      ),
                      _buildQuickStat(
                        icon: Icons.attach_money,
                        title: "Total Donado",
                        value: "\$${totalDonated.toStringAsFixed(0)} CLP",
                      ),
                      _buildQuickStat(
                        icon: Icons.favorite,
                        title: "Donadores",
                        value: uniqueDonors.toString(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Historial de transacciones
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 10,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            "Historial de Transacciones",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(child: _buildTransactionList()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blueAccent.shade100,
          child: Icon(icon, size: 30, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
