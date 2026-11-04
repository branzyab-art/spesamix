import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SpesaMixApp());
}

enum FoodCategory { bibite, salato, dolce }

extension FoodCategoryX on FoodCategory {
  String get label {
    switch (this) {
      case FoodCategory.bibite:
        return 'Bibite';
      case FoodCategory.salato:
        return 'Cibo salato';
      case FoodCategory.dolce:
        return 'Cibo dolce';
    }
  }

  IconData get icon {
    switch (this) {
      case FoodCategory.bibite:
        return Icons.local_drink_outlined;
      case FoodCategory.salato:
        return Icons.lunch_dining_outlined;
      case FoodCategory.dolce:
        return Icons.cookie_outlined;
    }
  }
}

class PurchaseItem {
  final String id;
  final String name;
  final FoodCategory category;
  final double quantity;
  final String unit;
  final DateTime createdAt;

  const PurchaseItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'quantity': quantity,
        'unit': unit,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: FoodCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => FoodCategory.salato,
      ),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'pz',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class SpesaMixApp extends StatelessWidget {
  const SpesaMixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpesaMix',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _storageKey = 'spesamix_items';
  final List<PurchaseItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(data.map((e) => PurchaseItem.fromJson(Map<String, dynamic>.from(e))));
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  void _addItem(PurchaseItem item) {
    setState(() => _items.insert(0, item));
    _saveItems();
  }

  void _deleteItem(String id) {
    setState(() => _items.removeWhere((e) => e.id == id));
    _saveItems();
  }

  void _clearAll() {
    setState(() => _items.clear());
    _saveItems();
  }

  Map<FoodCategory, double> get _totals {
    final result = {
      FoodCategory.bibite: 0.0,
      FoodCategory.salato: 0.0,
      FoodCategory.dolce: 0.0,
    };
    for (final item in _items) {
      result[item.category] = result[item.category]! + item.quantity;
    }
    return result;
  }

  double get _grandTotal => _totals.values.fold(0, (a, b) => a + b);

  double _percentage(FoodCategory category) {
    if (_grandTotal <= 0) return 0;
    return (_totals[category]! / _grandTotal) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpesaMix'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Azzera tutto',
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _SummaryCard(
                    totals: _totals,
                    grandTotal: _grandTotal,
                    percentage: _percentage,
                  ),
                  const SizedBox(height: 20),
                  Text('I tuoi acquisti', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    const _EmptyState()
                  else
                    ..._items.map(
                      (item) => Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(item.category.icon)),
                          title: Text(item.name),
                          subtitle: Text('${item.category.label} • ${_formatNumber(item.quantity)} ${item.unit}'),
                          trailing: IconButton(
                            tooltip: 'Elimina',
                            onPressed: () => _deleteItem(item.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final result = await showModalBottomSheet<PurchaseItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AddPurchaseSheet(),
    );
    if (result != null) _addItem(result);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Azzera tutti gli acquisti?'),
        content: const Text('Questa operazione elimina tutto lo storico salvato sul telefono.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Azzera')),
        ],
      ),
    );
    if (ok == true) _clearAll();
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<FoodCategory, double> totals;
  final double grandTotal;
  final double Function(FoodCategory) percentage;

  const _SummaryCard({
    required this.totals,
    required this.grandTotal,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = {
      FoodCategory.bibite: Colors.blue,
      FoodCategory.salato: Colors.orange,
      FoodCategory.dolce: Colors.pink,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riepilogo', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Quantità totale: ${_formatNumber(grandTotal)}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: grandTotal <= 0
                  ? const Center(child: Text('Aggiungi un acquisto per vedere il grafico'))
                  : PieChart(
                      PieChartData(
                        centerSpaceRadius: 45,
                        sectionsSpace: 2,
                        sections: FoodCategory.values.map((cat) {
                          final pct = percentage(cat);
                          return PieChartSectionData(
                            value: totals[cat],
                            title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                            color: colors[cat],
                            radius: 62,
                            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            ...FoodCategory.values.map((cat) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[cat], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(cat.label)),
                    Text('${percentage(cat).toStringAsFixed(1)}%  •  ${_formatNumber(totals[cat]!)}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.shopping_basket_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text('Nessun acquisto inserito', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Tocca “Aggiungi” per inserire il primo prodotto.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class AddPurchaseSheet extends StatefulWidget {
  const AddPurchaseSheet({super.key});

  @override
  State<AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends State<AddPurchaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  FoodCategory _category = FoodCategory.salato;
  String _unit = 'pz';

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Aggiungi acquisto', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome prodotto', hintText: 'Es. Coca-Cola, patatine, biscotti'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Inserisci il nome del prodotto' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FoodCategory>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: FoodCategory.values
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.label)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? FoodCategory.salato),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantità'),
                    validator: (v) {
                      final normalized = (v ?? '').replaceAll(',', '.');
                      final n = double.tryParse(normalized);
                      if (n == null || n <= 0) return 'Quantità non valida';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: 'Unità'),
                    items: const [
                      DropdownMenuItem(value: 'pz', child: Text('pz')),
                      DropdownMenuItem(value: 'g', child: Text('g')),
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'ml', child: Text('ml')),
                      DropdownMenuItem(value: 'l', child: Text('l')),
                    ],
                    onChanged: (v) => setState(() => _unit = v ?? 'pz'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Salva acquisto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.parse(_qtyController.text.replaceAll(',', '.'));
    final item = PurchaseItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      category: _category,
      quantity: quantity,
      unit: _unit,
      createdAt: DateTime.now(),
    );
    Navigator.pop(context, item);
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}
