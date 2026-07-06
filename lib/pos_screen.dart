import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'receipt_printer.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final CollectionReference _productsRef =
      FirebaseFirestore.instance.collection('products');
  final CollectionReference _invoicesRef =
      FirebaseFirestore.instance.collection('invoices');
  final CollectionReference _customersRef =
      FirebaseFirestore.instance.collection('customers');

  final Map<String, int> _cart = {}; // docId -> qty
  String _selectedCat = 'All';
  String _search = '';
  String _selectedCustomerId = 'walkin';
  String _selectedCustomerName = 'Walk-in Customer';
  double _discount = 0;
  bool _processing = false;

  final List<String> _categories = [
    'All', 'Caps', 'Underwear', 'Bra', 'Socks', 'Tasbih', 'Garments', 'Other'
  ];

  QueryDocumentSnapshot? _findProduct(
      List<QueryDocumentSnapshot> products, String id) {
    for (final d in products) {
      if (d.id == id) return d;
    }
    return null;
  }

  void _addToCart(String docId) {
    setState(() {
      _cart[docId] = (_cart[docId] ?? 0) + 1;
    });
  }

  void _changeQty(String docId, int delta) {
    setState(() {
      _cart[docId] = (_cart[docId] ?? 0) + delta;
      if ((_cart[docId] ?? 0) <= 0) _cart.remove(docId);
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _discount = 0;
    });
  }

  String _catEmoji(String cat) {
    switch (cat) {
      case 'Caps':
        return '🧢';
      case 'Underwear':
        return '🩲';
      case 'Bra':
        return '👙';
      case 'Socks':
        return '🧦';
      case 'Tasbih':
        return '📿';
      case 'Garments':
        return '👕';
      default:
        return '📦';
    }
  }

  Future<void> _checkout(List<QueryDocumentSnapshot> allProducts) async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add items first!')),
      );
      return;
    }

    int subtotal = 0;
    List<Map<String, dynamic>> items = [];
    for (final entry in _cart.entries) {
      final doc = _findProduct(allProducts, entry.key);
      if (doc == null) continue;
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['sell'] ?? 0) as int;
      subtotal += price * entry.value;
      items.add({
        'productId': doc.id,
        'name': data['name'],
        'price': price,
        'qty': entry.value,
      });
    }
    final total = (subtotal * (1 - _discount / 100)).round();

    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: $_selectedCustomerName'),
            const SizedBox(height: 8),
            Text('Items: ${_cart.length}'),
            Text('Total: Rs $total'),
            const SizedBox(height: 16),
            const Text('Payment method:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PayBtn(
                    label: 'Cash',
                    color: const Color(0xFF1D9E75),
                    onTap: () => Navigator.pop(context, 'Cash'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PayBtn(
                    label: 'Credit',
                    color: const Color(0xFFEF4444),
                    onTap: () => Navigator.pop(context, 'Credit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PayBtn(
                    label: 'Online',
                    color: const Color(0xFF3B82F6),
                    onTap: () => Navigator.pop(context, 'Online'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (paymentMethod == null) return;

    setState(() => _processing = true);

    try {
      final invoiceDoc = await _invoicesRef.add({
        'customerId': _selectedCustomerId,
        'customerName': _selectedCustomerName,
        'items': items,
        'subtotal': subtotal,
        'discount': _discount,
        'total': total,
        'paymentMethod': paymentMethod,
        'status': paymentMethod == 'Credit' ? 'Credit' : 'Paid',
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (final entry in _cart.entries) {
        final doc = _findProduct(allProducts, entry.key);
        if (doc == null) continue;
        final data = doc.data() as Map<String, dynamic>;
        final currentStock = (data['stock'] ?? 0) as int;
        final newStock = (currentStock - entry.value).clamp(0, 999999);
        await _productsRef.doc(entry.key).update({'stock': newStock});
      }

      if (paymentMethod == 'Credit' && _selectedCustomerId != 'walkin') {
        await _customersRef.doc(_selectedCustomerId).update({
          'balance': FieldValue.increment(total),
          'totalPurchases': FieldValue.increment(total),
        });
      } else if (_selectedCustomerId != 'walkin') {
        await _customersRef.doc(_selectedCustomerId).update({
          'totalPurchases': FieldValue.increment(total),
        });
      }

      setState(() => _processing = false);


if (context.mounted) {
  await ReceiptPrinter.printReceipt(
    context: context,
    invoiceId: invoiceDoc.id,
    customerName: _selectedCustomerName,
    items: items,
    subtotal: subtotal,
    discount: _discount,
    total: total,
    paymentMethod: paymentMethod,
    dateTime: DateTime.now(),
  );
}

_clearCart();

if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
          'Sale recorded! Rs $total via $paymentMethod — Invoice #${invoiceDoc.id.substring(0, 6).toUpperCase()}'),
      backgroundColor: const Color(0xFF1D9E75),
      duration: const Duration(seconds: 3),
    ),
  );
}
    } catch (e) {
      setState(() => _processing = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('POS / Billing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productsRef.snapshots(),
        builder: (context, productSnapshot) {
          if (productSnapshot.hasError) {
            return Center(child: Text('Error: ${productSnapshot.error}'));
          }
          if (productSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allProducts = productSnapshot.data?.docs ?? [];

          final filteredProducts = allProducts.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final matchCat =
                _selectedCat == 'All' || data['cat'] == _selectedCat;
            final matchSearch = (data['name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_search.toLowerCase());
            return matchCat && matchSearch;
          }).toList();

          int subtotal = 0;
          for (final id in _cart.keys) {
            final doc = _findProduct(allProducts, id);
            if (doc != null) {
              final data = doc.data() as Map<String, dynamic>;
              subtotal += ((data['sell'] ?? 0) as int) * (_cart[id] ?? 0);
            }
          }
          final total = (subtotal * (1 - _discount / 100)).round();

          return Row(
            children: [
              
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Search product...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final selected = _selectedCat == cat;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCat = cat),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF1D9E75)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      selected ? Colors.white : Colors.grey,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? const Center(
                              child: Text(
                                  'No products found. Add products in Inventory first.',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          : GridView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.4,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (_, i) {
                                final doc = filteredProducts[i];
                                final p = doc.data() as Map<String, dynamic>;
                                final stock = p['stock'] ?? 0;
                                final inCart = _cart.containsKey(doc.id);
                                final outOfStock = stock <= 0;
                                return GestureDetector(
                                  onTap: outOfStock
                                      ? null
                                      : () => _addToCart(doc.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: outOfStock
                                          ? Colors.grey.shade200
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: inCart
                                            ? const Color(0xFF1D9E75)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _catEmoji(p['cat'] ?? ''),
                                          style:
                                              const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          p['name'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          outOfStock
                                              ? 'Out of stock'
                                              : 'Rs ${p['sell']} • Qty $stock',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: outOfStock
                                                  ? Colors.red
                                                  : const Color(0xFF1D9E75),
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              
              Container(
                width: 320,
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Color(0xFFEEEEEE))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Current Bill',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              TextButton(
                                onPressed: _clearCart,
                                child: const Text('Clear',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<QuerySnapshot>(
                            stream: _customersRef.snapshots(),
                            builder: (context, custSnap) {
                              final customers = custSnap.data?.docs ?? [];
                              return DropdownButtonFormField<String>(
                                value: _selectedCustomerId,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFEEEEEE)),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'walkin',
                                    child: Text('Walk-in Customer',
                                        style: TextStyle(fontSize: 13)),
                                  ),
                                  ...customers.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    return DropdownMenuItem(
                                      value: doc.id,
                                      child: Text(data['name'] ?? '',
                                          style:
                                              const TextStyle(fontSize: 13)),
                                    );
                                  }),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    _selectedCustomerId = v;
                                    if (v == 'walkin') {
                                      _selectedCustomerName =
                                          'Walk-in Customer';
                                    } else {
                                      QueryDocumentSnapshot? custDoc;
                                      for (final d in customers) {
                                        if (d.id == v) {
                                          custDoc = d;
                                          break;
                                        }
                                      }
                                      if (custDoc != null) {
                                        final data = custDoc.data()
                                            as Map<String, dynamic>;
                                        _selectedCustomerName =
                                            data['name'] ?? '';
                                      }
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _cart.isEmpty
                          ? const Center(
                              child: Text('No items added',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(12),
                              children: _cart.entries.map((e) {
                                final doc = _findProduct(allProducts, e.key);
                                if (doc == null) {
                                  return const SizedBox.shrink();
                                }
                                final p = doc.data() as Map<String, dynamic>;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(p['name'] ?? '',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            Text(
                                                'Rs ${p['sell']} × ${e.value}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          _QtyBtn(
                                              icon: Icons.remove,
                                              onTap: () =>
                                                  _changeQty(e.key, -1)),
                                          Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8),
                                            child: Text('${e.value}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                          _QtyBtn(
                                              icon: Icons.add,
                                              onTap: () =>
                                                  _changeQty(e.key, 1)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: Color(0xFFEEEEEE))),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal',
                                  style: TextStyle(color: Colors.grey)),
                              Text('Rs $subtotal'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Discount %',
                                  style: TextStyle(color: Colors.grey)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            vertical: 4),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onChanged: (v) => setState(() =>
                                      _discount = double.tryParse(v) ?? 0),
                                ),
                              ),
                              const Spacer(),
                              Text('- Rs ${subtotal - total}',
                                  style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              Text('Rs $total',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D9E75))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _processing
                                  ? null
                                  : () => _checkout(allProducts),
                              icon: _processing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.receipt_long),
                              label: Text(
                                  _processing ? 'Processing...' : 'Checkout',
                                  style: const TextStyle(fontSize: 15)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D9E75),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }
}

class _PayBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PayBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}