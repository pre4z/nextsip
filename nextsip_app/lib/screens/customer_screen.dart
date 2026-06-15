import 'package:flutter/material.dart';
import '../services/api_service.dart';

// styrer customer pagen
class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final TextEditingController _uidController = TextEditingController();
  final ApiService _api = ApiService();

  CardBalance? _card;
  bool _loading = false;
  String? _error;
  String? _message;

  Future<void> _lookupBalance() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _message = null;
      _card = null;
    });

    try {
      final card = await _api.getBalance(uid);
      setState(() => _card = card);
    } catch (_) {
      setState(() => _error = 'Kunne ikke finde kortet. Tjek kort-ID.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pay() async {
    if (_card == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final updated = await _api.pay(_card!.uid);
      setState(() {
        _card = updated;
        _message = 'Betaling gennemfoert. Saldo er nulstillet.';
      });
    } catch (_) {
      setState(() => _error = 'Betaling fejlede. Proev igen.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;

    return Scaffold(
      appBar: AppBar(title: const Text('Betal din regning')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _uidController,
              decoration: const InputDecoration(
                labelText: 'Kort-ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _lookupBalance,
              child: const Text('Vis saldo'),
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_message != null)
              Text(_message!, style: const TextStyle(color: Colors.green)),
            if (card != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Kort: ${card.uid}'),
                      const SizedBox(height: 8),
                      Text(
                        'Saldo: ${card.balance} kr',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (card.balance > 0) ...[
                const Text('Vaelg betalingsmetode:'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _pay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('MobilePay'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _pay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Kort'),
                      ),
                    ),
                  ],
                ),
              ] else
                const Text('Intet at betale - tak!'),
            ],
          ],
        ),
      ),
    );
  }
}
