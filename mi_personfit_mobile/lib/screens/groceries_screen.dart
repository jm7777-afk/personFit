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

  // Filtros de Ubicación (Venezuela / Carabobo)
  String _selectedState = 'Carabobo';
  String _selectedMunicipality = 'Todos';
  LocationsData? _locationsData;

  // Búsqueda en directorio
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<GroceryListModel> _lists = [];
  GroceryListModel? _activeList;

  List<ProductComparisonItem> _productComparisons = [];
  Map<String, dynamic>? _supermarketComparisons;
  List<Supermarket> _supermarkets = [];
  List<GroceryProduct> _allProducts = [];

  final List<String> _caraboboQuickMunicipalities = [
    'Todos',
    'Valencia',
    'Naguanagua',
    'San Diego',
    'Guacara',
    'Los Guayos',
    'Puerto Cabello'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _showInBs = _apiService.showInBs;
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final locs = await _apiService.getSupermarketLocations();
      final supers = await _apiService.getSupermarkets(
        state: _selectedState,
        municipality: _selectedMunicipality,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      final prods = await _apiService.getGroceryProducts();
      final lists = await _apiService.getGroceryLists();
      final prodComps = await _apiService.getCompareProducts(
        state: _selectedState,
        municipality: _selectedMunicipality,
      );
      final superComps = await _apiService.getCompareSupermarkets(
        state: _selectedState,
        municipality: _selectedMunicipality,
      );

      GroceryListModel? active;
      if (lists.isNotEmpty) {
        if (_activeList != null && lists.any((l) => l.id == _activeList!.id)) {
          active = await _apiService.getGroceryListDetails(_activeList!.id);
        } else {
          active = await _apiService.getGroceryListDetails(lists.first.id);
        }
      }

      if (mounted) {
        setState(() {
          _locationsData = locs;
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

  void _showLocationSelectorDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        String tempState = _selectedState;
        String tempMun = _selectedMunicipality;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final caraboboLoc = _locationsData?.states.firstWhere(
              (s) => s.state.toLowerCase() == 'carabobo',
              orElse: () => VenezuelaStateLocation(state: 'Carabobo', supermarketsCount: 17, municipalities: []),
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.location_on, color: Color(0xFF6366F1), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Configurar Ubicación en Venezuela',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Filtra precios, comparativas y directorio por Estado y Municipio específico.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Selector de Estado
                    const Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_locationsData?.states ?? [
                        VenezuelaStateLocation(state: 'Carabobo', supermarketsCount: 17, municipalities: []),
                        VenezuelaStateLocation(state: 'Distrito Capital', supermarketsCount: 0, municipalities: []),
                        VenezuelaStateLocation(state: 'Miranda', supermarketsCount: 0, municipalities: []),
                        VenezuelaStateLocation(state: 'Aragua', supermarketsCount: 0, municipalities: []),
                        VenezuelaStateLocation(state: 'Zulia', supermarketsCount: 0, municipalities: []),
                        VenezuelaStateLocation(state: 'Lara', supermarketsCount: 0, municipalities: []),
                      ]).map((st) {
                        final isSel = tempState.toLowerCase() == st.state.toLowerCase();
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(st.state, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                              if (st.supermarketsCount > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSel ? Colors.white.withOpacity(0.3) : const Color(0xFF10B981).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${st.supermarketsCount}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? Colors.white : const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          selected: isSel,
                          selectedColor: const Color(0xFF6366F1),
                          labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF334155)),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                tempState = st.state;
                                tempMun = 'Todos';
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Selector de Municipios de Carabobo
                    if (tempState.toLowerCase() == 'carabobo') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Municipios de Carabobo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            '${caraboboLoc?.supermarketsCount ?? 17} supermercados',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Todos los Municipios'),
                            selected: tempMun == 'Todos',
                            selectedColor: const Color(0xFF10B981),
                            labelStyle: TextStyle(color: tempMun == 'Todos' ? Colors.white : const Color(0xFF334155)),
                            onSelected: (val) {
                              if (val) setModalState(() => tempMun = 'Todos');
                            },
                          ),
                          ...(caraboboLoc?.municipalities ?? []).map((m) {
                            final isSel = tempMun.toLowerCase() == m.name.toLowerCase();
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(m.name),
                                  if (m.supermarketsCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSel ? Colors.white.withOpacity(0.3) : const Color(0xFF6366F1).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${m.supermarketsCount}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSel ? Colors.white : const Color(0xFF6366F1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              selected: isSel,
                              selectedColor: const Color(0xFF6366F1),
                              labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF334155)),
                              onSelected: (val) {
                                if (val) setModalState(() => tempMun = m.name);
                              },
                            );
                          }),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedState = tempState;
                            _selectedMunicipality = tempMun;
                          });
                          _loadAllData();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Aplicar Ubicación', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
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
                        'Agregar Producto a la Lista',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selector rápido de productos predeterminados
                  if (_allProducts.isNotEmpty) ...[
                    const Text('Sugerencias populares:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allProducts.take(8).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final p = _allProducts[idx];
                          return ActionChip(
                            label: Text(p.name.split(' (').first),
                            onPressed: () {
                              setModalState(() {
                                selectedProduct = p;
                                nameController.text = p.name;
                                priceUsdController.text = p.latestPriceUsd.toStringAsFixed(2);
                                priceBsController.text = p.latestPriceBs.toStringAsFixed(2);
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del producto',
                      hintText: 'Ej: Arroz Primor 1kg',
                      prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
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
                        child: TextField(
                          controller: priceUsdController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Precio \$ USD',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) {
                            final usd = double.tryParse(val) ?? 0.0;
                            final rate = _apiService.activeBcvRate;
                            priceBsController.text = (usd * rate).toStringAsFixed(2);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: priceBsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Precio Bs (VES)',
                      prefixIcon: const Icon(Icons.currency_exchange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      final bs = double.tryParse(val) ?? 0.0;
                      final rate = _apiService.activeBcvRate;
                      if (rate > 0) {
                        priceUsdController.text = (bs / rate).toStringAsFixed(2);
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

  void _showCreateListDialog({int? preselectedSupermarketId}) {
    final titleController = TextEditingController(text: 'Compras Semanales');
    int? selectedSupermarketId = preselectedSupermarketId;

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
                      labelText: 'Supermercado de Compra',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    initialValue: selectedSupermarketId,
                    items: _supermarkets.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${s.name} (${s.municipality})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
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
                          _tabController.animateTo(0);
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
    final currencyFmt = NumberFormat("#,##0.00", "es_VE");

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Kryon • Supermercados',
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
            Tab(icon: Icon(Icons.leaderboard_outlined, size: 18), text: 'Más Económico'),
            Tab(icon: Icon(Icons.location_on, size: 18), text: 'Directorio Carabobo'),
          ],
        ),
      ),
      body: Column(
        children: [
          // BARRA SUPERIOR DE UBICACIÓN (VENEZUELA / CARABOBO)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: Color(0xFF6366F1), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _showLocationSelectorDialog,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$_selectedState • ${_selectedMunicipality == "Todos" ? "Todos los municipios" : _selectedMunicipality}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF6366F1)),
                          ],
                        ),
                        Text(
                          '${_supermarkets.length} supermercados registrados con precios reales',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showLocationSelectorDialog,
                  icon: const Icon(Icons.tune, size: 14),
                  label: const Text('Cambiar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),

          // CONTENIDO DE PESTAÑAS
          Expanded(
            child: _isLoading
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

                      // TAB 4: DIRECTORIO DE SUPERMERCADOS DE CARABOBO
                      _buildCaraboboDirectoryTab(currencyFmt),
                    ],
                  ),
          ),
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
                onPressed: () => _showCreateListDialog(),
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
                onPressed: () => _showCreateListDialog(),
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

    if (_productComparisons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(
                'Sin registros de precios en $_selectedMunicipality',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cambia la ubicación a "Todos los municipios" para ver la comparativa completa de Carabobo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

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
                                    Flexible(
                                      child: Text(
                                        comp.supermarketName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: comp.isCheapest ? const Color(0xFF059669) : const Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (comp.municipality != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Text(
                                          '(${comp.municipality})',
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                        ),
                                      ),
                                    if (comp.isCheapest)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Text('• Más Barato', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
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
                    '${cheapest.supermarketName} (${cheapest.branch ?? cheapest.municipality ?? ""})',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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

          Text(
            'Comparativa de Costo de Cesta (${_selectedMunicipality == "Todos" ? "Todo Carabobo" : _selectedMunicipality}):',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                              Flexible(
                                child: Text(
                                  '${r.supermarketName} ${r.branch != null ? "(${r.branch})" : ""}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isFirst)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.star, color: Color(0xFFFBBF24), size: 16),
                                ),
                            ],
                          ),
                          Text(
                            '${r.municipality ?? "Carabobo"} • ${r.productsTracked} productos evaluados',
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

  // --- TAB 4: DIRECTORIO DE SUPERMERCADOS DE CARABOBO ---

  Widget _buildCaraboboDirectoryTab(NumberFormat currencyFmt) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Campo de Búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, zona o descripción...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _loadAllData();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val);
              _loadAllData();
            },
          ),
          const SizedBox(height: 12),

          // Chips rápidos de municipios de Carabobo
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _caraboboQuickMunicipalities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final mun = _caraboboQuickMunicipalities[idx];
                final isSelected = _selectedMunicipality.toLowerCase() == mun.toLowerCase();
                return ChoiceChip(
                  label: Text(mun),
                  selected: isSelected,
                  selectedColor: const Color(0xFF6366F1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedMunicipality = mun);
                      _loadAllData();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Lista de Tarjetas de Supermercados
          if (_supermarkets.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(Icons.store_mall_directory_outlined, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text('No se encontraron supermercados con este filtro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 6),
                  Text('Intenta seleccionar otro municipio o limpiar el texto de búsqueda.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            )
          else
            ..._supermarkets.map((s) {
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
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
                      // Encabezado: Nombre, Sucursal y Badge de Municipio
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.storefront, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                ),
                                if (s.branch != null)
                                  Text(
                                    s.branch!,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFC7D2FE)),
                            ),
                            child: Text(
                              s.municipality,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Ubicación exacta
                      if (s.address != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.place, size: 16, color: Color(0xFFEF4444)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s.address!,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Descripción del mercado
                      if (s.description != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  s.description!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Horario y Teléfono
                      Row(
                        children: [
                          if (s.openingHours != null)
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      s.openingHours!,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (s.phone != null) ...[
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  s.phone!,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Botones de acción rápida
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showCreateListDialog(preselectedSupermarketId: s.id);
                              },
                              icon: const Icon(Icons.add_shopping_cart, size: 16),
                              label: const Text('Crear Lista Aquí', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6366F1),
                                side: const BorderSide(color: Color(0xFF6366F1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _tabController.animateTo(2);
                              },
                              icon: const Icon(Icons.leaderboard_outlined, size: 16),
                              label: const Text('Ver Precios', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
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
