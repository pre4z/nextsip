import 'dart:convert';
import 'package:http/http.dart' as http;

/// representerer et kort med positivt saldo
class CardBalance {
  final String uid;
  final int balance;

  CardBalance({required this.uid, required this.balance});

  factory CardBalance.fromJson(Map<String, dynamic> json) {
    return CardBalance(
      uid: json['uid'] as String,
      balance: json['balance'] as int,
    );
  }
}

/// viser en udgave
class TransactionEntry {
  final String uid;
  final String item;
  final int price;
  final String timestamp;

  TransactionEntry({
    required this.uid,
    required this.item,
    required this.price,
    required this.timestamp,
  });

  factory TransactionEntry.fromJson(Map<String, dynamic> json) {
    return TransactionEntry(
      uid: json['uid'] as String,
      item: json['item'] as String,
      price: json['price'] as int,
      timestamp: json['timestamp'] as String,
    );
  }
}

/// Service-Layer der soerger for at http > nestjs backend
/// UI-Widgets kalder disse metoder
class ApiService {
  // raspberrys ip adresse
  static const String baseUrl = 'http://10.176.69.26:3000';

  Future<CardBalance> getBalance(String uid) async {
    final response = await http.get(Uri.parse('$baseUrl/cards/$uid'));
    if (response.statusCode == 200) {
      return CardBalance.fromJson(jsonDecode(response.body));
    }
    throw Exception('Kunne ikke hente saldo (${response.statusCode})');
  }

  Future<CardBalance> pay(String uid) async {
    final response = await http.post(Uri.parse('$baseUrl/cards/$uid/pay'));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return CardBalance.fromJson(jsonDecode(response.body));
    }
    throw Exception('Betaling fejlede (${response.statusCode})');
  }

  /// admin login der giver os jwt
  Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['access_token'] as String;
    }
    throw Exception('Login mislykkedes (${response.statusCode})');
  }

  Future<List<CardBalance>> getAdminCards(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/cards'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CardBalance.fromJson(e)).toList();
    }
    throw Exception('Kunne ikke hente kort (${response.statusCode})');
  }

  Future<List<TransactionEntry>> getAdminTransactions(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/transactions'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => TransactionEntry.fromJson(e)).toList();
    }
    throw Exception('Kunne ikke hente transaktioner (${response.statusCode})');
  }

  Future<CardBalance> setBalance(String uid, int balance, String token) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/cards/$uid'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'balance': balance}),
    );
    if (response.statusCode == 200) {
      return CardBalance.fromJson(jsonDecode(response.body));
    }
    throw Exception('Kunne ikke aendre saldo (${response.statusCode})');
  }
}
