import 'dart:convert';
import 'package:http/http.dart' as http;

class PayPalService {
  final String clientId = 'TU_CLIENT_ID';
  final String secret = 'TU_SECRETO';
  final String payPalUrl = 'https://api-m.sandbox.paypal.com';

  Future<String?> getAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('$payPalUrl/v1/oauth2/token'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$clientId:$secret'))}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: 'grant_type=client_credentials',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['access_token'];
      } else {
        print('Error al obtener el token de acceso: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de red: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createPayment(
      String accessToken, String amount) async {
    final response = await http.post(
      Uri.parse('$payPalUrl/v1/payments/payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode({
        "intent": "sale",
        "redirect_urls": {
          "return_url": "https://yourapp.com/return",
          "cancel_url": "https://yourapp.com/cancel"
        },
        "payer": {"payment_method": "paypal"},
        "transactions": [
          {
            "amount": {"total": amount, "currency": "USD"},
            "description": "Donación al proyecto"
          }
        ]
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Error al crear el pago: ${response.body}');
      return null;
    }
  }
}
