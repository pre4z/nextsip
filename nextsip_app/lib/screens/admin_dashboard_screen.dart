import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Bliver brugt til at sætte vores Admin Dashboard med en StatefulWidget
class AdminDashboardScreen extends StatefulWidget {
  final String token;

  const AdminDashboardScreen({super.key, required this.token});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _api = ApiService();

  List<CardBalance> _cards = [];
  List<TransactionEntry> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  // Load data 
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cards = await _api.getAdminCards(widget.token);
      final transactions = await _api.getAdminTransactions(widget.token);
      setState(() {
        _cards = cards;
        _transactions = transactions;
      });
    } catch (_) {
      setState(() => _error = 'Kunne ikke hente data fra serveren.');
    } finally {
      setState(() => _loading = false);
    }
  }
  // edit balance paa en kort
  Future<void> _editBalance(CardBalance card) async {
    final controller = TextEditingController(text: card.balance.toString());

    final newBalance = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Saldo for ${card.uid}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nyt saldo (kr)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuller'),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                Navigator.pop(context, value);
              },
              child: const Text('Gem'),
            ),
          ],
        );
      },
    );

    if (newBalance == null) return;

    try {
      await _api.setBalance(card.uid, newBalance, widget.token);
      await _loadData();
    } catch (_) {
      setState(() => _error = 'Kunne ikke aendre saldo.');
    }
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month} $h:$m';
    } catch (_) {
      return iso;
    }
  }
  // Design admin panel
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin panel'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const Text(
                    'Aabne saldoer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_cards.isEmpty) const Text('Ingen kort endnu.'),
                  for (final card in _cards)
                    Card(
                      child: ListTile(
                        title: Text(card.uid),
                        subtitle: Text('${card.balance} kr'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editBalance(card),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Seneste bestillinger',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    const Text('Ingen bestillinger endnu.'),
                  for (final tx in _transactions)
                    ListTile(
                      title: Text('${tx.item} - ${tx.price} kr'),
                      subtitle: Text('Kort: ${tx.uid}'),
                      trailing: Text(_formatTimestamp(tx.timestamp)),
                    ),
                ],
              ),
            ),
    );
  }
}
