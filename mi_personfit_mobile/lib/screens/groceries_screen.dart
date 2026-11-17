import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/grocery_model.dart';
import '../services/api_service.dart';
import '../widgets/standard_calculator_dialog.dart';

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _showInBs = false;

  List<GroceryListModel> _lists = [];
  GroceryListModel? _activeList;

  List<ProductComparisonItem> _productComparisons = [];
  Map<String, dynamic>? _supermarketComparisons;
  List<Supermarket> _supermarkets = [];
  List<GroceryProduct> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _showInBs = _apiService.showInBs;
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final supers = await _apiService.getSupermarkets();
      final prods = await _apiService.getGroceryProducts();
      final lists = await _apiService.getGroceryLists();
      final prodComps = await _apiService.getCompareProducts();
      final superComps = await _apiService.getCompareSupermarkets();

      GroceryListModel? active;
      if (lists.isNotEmpty) {
        active = await _apiService.getGroceryListDetails(lists.first.id);
      }

      if (mounted) {
        setState(() {
          _supermarkets = supers;
          _allProducts = prods;
          _lists = lists;
          _activeList = active;
          _productComparisons = prodComps;
          _supermarketComparisons = superComps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos de supermercado: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectList(int listId) async {
    try {
      final details = await _apiService.getGroceryListDetails(listId);
      if (mounted) {
        setState(() => _activeList = details);
      }
    } catch (_) {}
  }

  Future<void> _toggleItem(int itemId, bool currentChecked) async {
    if (_activeList == null) return;
    try {
      final updated = await _apiService.toggleGroceryListItem(_activeList!.id, itemId, !currentChecked);
      if (mounted) {
        setState(() => _activeList = updated);
      }
    } catch (_) {}
  }

  Future<void> _deleteItem(int itemId) async {
    if (_activeList == null) return;
    try {
      await _apiService.deleteGroceryListItem(_activeList!.id, itemId);
      final updated = await _apiService.getGroceryListDetails(_activeList!.id);
      if (mounted) {
        setState(() => _activeList = updated);
      }
    } catch (_) {}
  }

  void _showAddProductDialog() {
    if (_activeList == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero crea una lista de compras')),
      );
      return;
    }

    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceUsdController = TextEditingController();
    final priceBsController = TextEditingController();
    GroceryProduct? selectedProduct;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Agregar Producto a Lista',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selector rápido de producto conocido
                  if (_allProducts.isNotEmpty) ...[
                    const Text('Sugeridos de la Cesta:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final p = _allProducts[index];
                          final isSel = selectedProduct?.id == p.id;
                          return ChoiceChip(
                            label: Text(p.name, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : Colors.black87)),
                            selected: isSel,
                            selectedColor: const Color(0xFF6366F1),
                            onSelected: (sel) {
                              setModalState(() {
                                selectedProduct = sel ? p : null;
                                if (sel) {
                                  nameController.text = p.name;
                                  priceUsdController.text = p.latestPriceUsd.toStringAsFixed(2);
                                  priceBsController.text = p.latestPriceBs.toStringAsFixed(2);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Campo Nombre del producto
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del producto',
                      prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cantidad y Precio en $
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Cantidad',
                            prefixIcon: const Icon(Icons.numbers),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: priceUsdController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Precio (\$ USD)',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) {
                            final usd = double.tryParse(val) ?? 0.0;
                            priceBsController.text = (usd * _apiService.activeBcvRate).toStringAsFixed(2);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Precio en Bs
                  TextField(
                    controller: priceBsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Precio en Bolívares (Bs.)',
                      prefixIcon: const Icon(Icons.currency_exchange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      final bs = double.tryParse(val) ?? 0.0;
                      if (_apiService.activeBcvRate > 0) {
                        priceUsdController.text = (bs / _apiService.activeBcvRate).toStringAsFixed(2);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        final qty = double.tryParse(qtyController.text) ?? 1.0;
                        final priceUsd = double.tryParse(priceUsdController.text) ?? 0.0;
                        final priceBs = double.tryParse(priceBsController.text) ?? (priceUsd * _apiService.activeBcvRate);

                        Navigator.pop(ctx);
                        try {
                          final updated = await _apiService.addGroceryListItem(
                            _activeList!.id,
                            productId: selectedProduct?.id,
                            productName: name,
                            quantity: qty,
                            priceUsd: priceUsd,
                            priceBs: priceBs,
                          );
                          if (mounted) setState(() => _activeList = updated);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Agregar a Lista', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateListDialog() {
    final titleController = TextEditingController(text: 'Compras de la Semana');
    int? selectedSupermarketId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Nueva Lista de Compras', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la lista',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Supermercado (Opcional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: selectedSupermarketId,
                    items: _supermarkets.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.name));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedSupermarketId = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final newList = await _apiService.createGroceryList(title, supermarketId: selectedSupermarketId);
                      final allLists = await _apiService.getGroceryLists();
                      if (mounted) {
                        setState(() {
                          _lists = allLists;
                          _activeList = newList;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Crear Lista'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0.00', 'es_VE');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Supermercados & Compras',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Conmutador Global Bs. / $ USD
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _showInBs = !_showInBs;
                });
                _apiService.setCurrencyPreference(_showInBs);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _showInBs ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      _showInBs ? 'Bs. VES' : '\$ USD',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.sync_alt, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
          // Botón Calculadora
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Calculadora de Precios',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const StandardCalculatorDialog(),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.checklist, size: 18), text: 'Lista Activa'),
            Tab(icon: Icon(Icons.trending_up, size: 18), text: '¿Cuánto Subió?'),
            Tab(icon: Icon(Icons.storefront, size: 18), text: 'Comparar Súpers'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: LISTA ACTIVA ("QUÉ LLEVO, CUÁNTO LLEVO")
                _buildActiveListTab(currencyFmt),

                // TAB 2: COMPARADOR DE PRECIOS Y VARIACIÓN ("CUÁNTO SUBIÓ")
                _buildPriceComparisonTab(currencyFmt),

                // TAB 3: COMPARADOR DE SUPERMERCADOS ("CUÁL ES MÁS ECONÓMICO")
                _buildSupermarketRankingTab(currencyFmt),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddProductDialog,
              backgroundColor: const Color(0xFF6366F1),
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: const Text('Agregar Ítem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // --- TAB 1: LISTA ACTIVA ("QUÉ LLEVO, CUÁNTO LLEVO") ---

  Widget _buildActiveListTab(NumberFormat currencyFmt) {
    if (_lists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_basket_outlined, size: 64, color: Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              const Text(
                'No tienes listas de compras activas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea una lista para marcar en tiempo real los productos que echas al carrito y saber exactamente cuánto llevas gastado en Bs y \$.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showCreateListDialog,
                icon: const Icon(Icons.add),
                label: const Text('Crear Primera Lista'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final list = _activeList ?? _lists.first;
    final symbol = _showInBs ? 'Bs.' : '\$';
    final totalChecked = _showInBs ? list.totalCheckedBs : list.totalCheckedUsd;
    final totalEstimated = _showInBs ? list.totalEstimatedBs : list.totalEstimatedUsd;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Selector de Lista y Botón Nueva Lista
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButton<int>(
                    value: list.id,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _lists.map((l) {
                      return DropdownMenuItem(
                        value: l.id,
                        child: Text('${l.title} (${l.checkedItems}/${l.totalItems})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) _selectList(id);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showCreateListDialog,
                icon: const Icon(Icons.add_circle, color: Color(0xFF6366F1), size: 32),
                tooltip: 'Nueva Lista',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // BANNER PRINCIPAL: "QUÉ LLEVO, CUÁNTO LLEVO"
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LLEVAS EN CARRITO',
                      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    Text(
                      '${list.checkedItems} de ${list.totalItems} ítems',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$symbol ${currencyFmt.format(totalChecked)}',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'de $symbol ${currencyFmt.format(totalEstimated)} est.',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: list.totalItems > 0 ? (list.checkedItems / list.totalItems) : 0,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de Productos en el Carrito / Pendientes
          if (list.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text(
                'Tu lista está vacía. Toca "+ Agregar Ítem" para añadir productos.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else ...[
            const Text(
              'Toca el círculo para marcar lo que vas echando al carrito:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            ...list.items.map((item) {
              final isChecked = item.isChecked;
              final itemPrice = _showInBs ? item.priceBs : item.priceUsd;
              final itemTotal = itemPrice * item.quantity;

              return Dismissible(
                key: Key('item_${item.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteItem(item.id),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isChecked ? const Color(0xFF10B981).withOpacity(0.5) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  color: isChecked ? const Color(0xFFF0FDF4) : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: InkWell(
                      onTap: () => _toggleItem(item.id, isChecked),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isChecked ? const Color(0xFF10B981) : Colors.transparent,
                          border: Border.all(
                            color: isChecked ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            width: 2,
                          ),
                        ),
                        child: isChecked
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                    title: Text(
                      item.productName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} ${item.unit} × $symbol ${currencyFmt.format(itemPrice)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    trailing: Text(
                      '$symbol ${currencyFmt.format(itemTotal)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isChecked ? const Color(0xFF059669) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // --- TAB 2: COMPARADOR DE PRECIOS Y VARIACIÓN ("CUÁNTO SUBIÓ") ---

  Widget _buildPriceComparisonTab(NumberFormat currencyFmt) {
    final symbol = _showInBs ? 'Bs.' : '\$';

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _productComparisons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _productComparisons[index];
          final product = item.product;

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de Producto y Categoría
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Categoría: ${product.category} • Unidad: ${product.unit}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      if (item.cheapestSupermarket != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.thumb_up, color: Color(0xFF059669), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                item.cheapestSupermarket!.supermarketName.split(' ').first,
                                style: const TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),

                  // Precios por Supermercado y "Cuánto Subió"
                  ...item.comparisons.map((comp) {
                    final currentPrice = _showInBs ? comp.currentPriceBs : comp.currentPriceUsd;
                    final prevPrice = comp.previousPriceUsd != null
                        ? (_showInBs ? comp.previousPriceBs : comp.previousPriceUsd)
                        : null;
                    final hasIncrease = comp.increasePercentUsd > 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: comp.isCheapest ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: comp.isCheapest ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comp.supermarketName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: comp.isCheapest ? const Color(0xFF059669) : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    if (comp.isCheapest)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Text('• Más Económico', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                // Indicador de cuánto subió
                                if (comp.increasePercentUsd != 0 && prevPrice != null)
                                  Row(
                                    children: [
                                      Icon(
                                        hasIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 12,
                                        color: hasIncrease ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        hasIncrease
                                            ? 'Subió +${comp.increasePercentUsd}% (vs $symbol ${currencyFmt.format(prevPrice)})'
                                            : 'Bajó ${comp.increasePercentUsd}% (vs $symbol ${currencyFmt.format(prevPrice)})',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: hasIncrease ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const Text('Precio estable', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          Text(
                            '$symbol ${currencyFmt.format(currentPrice)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: comp.isCheapest ? const Color(0xFF059669) : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- TAB 3: COMPARADOR DE SUPERMERCADOS ("CUÁL ES MÁS ECONÓMICO") ---

  Widget _buildSupermarketRankingTab(NumberFormat currencyFmt) {
    if (_supermarketComparisons == null) {
      return const Center(child: Text('Sin datos comparativos de supermercados'));
    }

    final rankings = _supermarketComparisons!['rankings'] as List<SupermarketRanking>;
    final cheapest = _supermarketComparisons!['cheapest_supermarket'] as SupermarketRanking?;
    final symbol = _showInBs ? 'Bs.' : '\$';

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner de Supermercado Ganador (Más Económico)
          if (cheapest != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF047857).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.emoji_events, color: Color(0xFFFBBF24), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'SUPERMERCADO MÁS ECONÓMICO',
                        style: TextStyle(color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cheapest.supermarketName,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cesta completa estimada en: $symbol ${currencyFmt.format(_showInBs ? cheapest.totalBasketBs : cheapest.totalBasketUsd)}',
                    style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 14),
                  ),
                  if (cheapest.savingsVsMostExpensiveUsd > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Te ahorras \$ ${cheapest.savingsVsMostExpensiveUsd.toStringAsFixed(2)} comprando aquí en vez del más caro',
                        style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),

          const Text(
            'Comparativa de Costo de Cesta por Supermercado:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          ...rankings.asMap().entries.map((entry) {
            final index = entry.key;
            final r = entry.value;
            final isFirst = index == 0;
            final basketCost = _showInBs ? r.totalBasketBs : r.totalBasketUsd;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isFirst ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  width: isFirst ? 2 : 1,
                ),
              ),
              color: isFirst ? const Color(0xFFF0FDF4) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isFirst ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: isFirst ? Colors.white : const Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                r.supermarketName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                              ),
                              if (isFirst)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.star, color: Color(0xFFFBBF24), size: 16),
                                ),
                            ],
                          ),
                          Text(
                            '${r.productsTracked} productos evaluados • Promedio: \$ ${r.averageProductPriceUsd.toStringAsFixed(2)} / prod',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$symbol ${currencyFmt.format(basketCost)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isFirst ? const Color(0xFF059669) : const Color(0xFF0F172A),
                          ),
                        ),
                        if (r.savingsVsMostExpensiveUsd > 0 && !isFirst)
                          Text(
                            'Ahorro: \$ ${r.savingsVsMostExpensiveUsd.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
