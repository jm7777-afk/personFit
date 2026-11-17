class Supermarket {
  final int id;
  final String name;
  final String? branch;
  final String state;
  final String municipality;
  final String? address;
  final String? description;
  final String? phone;
  final String? openingHours;

  Supermarket({
    required this.id,
    required this.name,
    this.branch,
    this.state = 'Carabobo',
    this.municipality = 'Valencia',
    this.address,
    this.description,
    this.phone,
    this.openingHours,
  });

  factory Supermarket.fromJson(Map<String, dynamic> json) {
    return Supermarket(
      id: json['id'],
      name: json['name'],
      branch: json['branch'],
      state: json['state'] ?? 'Carabobo',
      municipality: json['municipality'] ?? 'Valencia',
      address: json['address'],
      description: json['description'],
      phone: json['phone'],
      openingHours: json['opening_hours'],
    );
  }
}

class MunicipalityLocation {
  final String name;
  final int supermarketsCount;

  MunicipalityLocation({
    required this.name,
    required this.supermarketsCount,
  });

  factory MunicipalityLocation.fromJson(Map<String, dynamic> json) {
    return MunicipalityLocation(
      name: json['name'] ?? '',
      supermarketsCount: json['supermarkets_count'] ?? 0,
    );
  }
}

class VenezuelaStateLocation {
  final String state;
  final int supermarketsCount;
  final List<MunicipalityLocation> municipalities;

  VenezuelaStateLocation({
    required this.state,
    required this.supermarketsCount,
    required this.municipalities,
  });

  factory VenezuelaStateLocation.fromJson(Map<String, dynamic> json) {
    return VenezuelaStateLocation(
      state: json['state'] ?? '',
      supermarketsCount: json['supermarkets_count'] ?? 0,
      municipalities: (json['municipalities'] as List? ?? [])
          .map((m) => MunicipalityLocation.fromJson(m))
          .toList(),
    );
  }
}

class LocationsData {
  final String currentState;
  final int totalSupermarketsCarabobo;
  final List<VenezuelaStateLocation> states;

  LocationsData({
    required this.currentState,
    required this.totalSupermarketsCarabobo,
    required this.states,
  });

  factory LocationsData.fromJson(Map<String, dynamic> json) {
    return LocationsData(
      currentState: json['current_state'] ?? 'Carabobo',
      totalSupermarketsCarabobo: json['total_supermarkets_carabobo'] ?? 0,
      states: (json['states'] as List? ?? [])
          .map((s) => VenezuelaStateLocation.fromJson(s))
          .toList(),
    );
  }
}

class GroceryProduct {
  final int id;
  final String name;
  final String category;
  final String unit;
  final double latestPriceUsd;
  final double latestPriceBs;
  final String? latestSupermarket;

  GroceryProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.latestPriceUsd,
    required this.latestPriceBs,
    this.latestSupermarket,
  });

  factory GroceryProduct.fromJson(Map<String, dynamic> json) {
    return GroceryProduct(
      id: json['id'],
      name: json['name'],
      category: json['category'] ?? 'Alimentos',
      unit: json['unit'] ?? 'unidad',
      latestPriceUsd: (json['latest_price_usd'] as num?)?.toDouble() ?? 0.0,
      latestPriceBs: (json['latest_price_bs'] as num?)?.toDouble() ?? 0.0,
      latestSupermarket: json['latest_supermarket'],
    );
  }
}

class SupermarketPriceComparison {
  final int supermarketId;
  final String supermarketName;
  final String? supermarketBranch;
  final String? municipality;
  final String? state;
  final double currentPriceUsd;
  final double currentPriceBs;
  final double? previousPriceUsd;
  final double? previousPriceBs;
  final double diffUsd;
  final double increasePercentUsd;
  final bool isCheapest;

  SupermarketPriceComparison({
    required this.supermarketId,
    required this.supermarketName,
    this.supermarketBranch,
    this.municipality,
    this.state,
    required this.currentPriceUsd,
    required this.currentPriceBs,
    this.previousPriceUsd,
    this.previousPriceBs,
    required this.diffUsd,
    required this.increasePercentUsd,
    required this.isCheapest,
  });

  factory SupermarketPriceComparison.fromJson(Map<String, dynamic> json) {
    return SupermarketPriceComparison(
      supermarketId: json['supermarket_id'],
      supermarketName: json['supermarket_name'] ?? 'Supermercado',
      supermarketBranch: json['supermarket_branch'],
      municipality: json['municipality'],
      state: json['state'],
      currentPriceUsd: (json['current_price_usd'] as num?)?.toDouble() ?? 0.0,
      currentPriceBs: (json['current_price_bs'] as num?)?.toDouble() ?? 0.0,
      previousPriceUsd: (json['previous_price_usd'] as num?)?.toDouble(),
      previousPriceBs: (json['previous_price_bs'] as num?)?.toDouble(),
      diffUsd: (json['diff_usd'] as num?)?.toDouble() ?? 0.0,
      increasePercentUsd: (json['increase_percent_usd'] as num?)?.toDouble() ?? 0.0,
      isCheapest: json['is_cheapest'] ?? false,
    );
  }
}

class ProductComparisonItem {
  final GroceryProduct product;
  final List<SupermarketPriceComparison> comparisons;
  final SupermarketPriceComparison? cheapestSupermarket;

  ProductComparisonItem({
    required this.product,
    required this.comparisons,
    this.cheapestSupermarket,
  });

  factory ProductComparisonItem.fromJson(Map<String, dynamic> json) {
    return ProductComparisonItem(
      product: GroceryProduct.fromJson(json['product']),
      comparisons: (json['comparisons'] as List? ?? [])
          .map((c) => SupermarketPriceComparison.fromJson(c))
          .toList(),
      cheapestSupermarket: json['cheapest_supermarket'] != null
          ? SupermarketPriceComparison.fromJson(json['cheapest_supermarket'])
          : null,
    );
  }
}

class SupermarketRanking {
  final int supermarketId;
  final String supermarketName;
  final String? branch;
  final String? municipality;
  final String? state;
  final String? address;
  final String? description;
  final String? phone;
  final String? openingHours;
  final double totalBasketUsd;
  final double totalBasketBs;
  final int productsTracked;
  final double averageProductPriceUsd;
  final bool isCheapest;
  final double savingsVsMostExpensiveUsd;

  SupermarketRanking({
    required this.supermarketId,
    required this.supermarketName,
    this.branch,
    this.municipality,
    this.state,
    this.address,
    this.description,
    this.phone,
    this.openingHours,
    required this.totalBasketUsd,
    required this.totalBasketBs,
    required this.productsTracked,
    required this.averageProductPriceUsd,
    required this.isCheapest,
    required this.savingsVsMostExpensiveUsd,
  });

  factory SupermarketRanking.fromJson(Map<String, dynamic> json) {
    return SupermarketRanking(
      supermarketId: json['supermarket_id'],
      supermarketName: json['supermarket_name'],
      branch: json['branch'],
      municipality: json['municipality'],
      state: json['state'],
      address: json['address'],
      description: json['description'],
      phone: json['phone'],
      openingHours: json['opening_hours'],
      totalBasketUsd: (json['total_basket_usd'] as num?)?.toDouble() ?? 0.0,
      totalBasketBs: (json['total_basket_bs'] as num?)?.toDouble() ?? 0.0,
      productsTracked: json['products_tracked'] ?? 0,
      averageProductPriceUsd: (json['average_product_price_usd'] as num?)?.toDouble() ?? 0.0,
      isCheapest: json['is_cheapest'] ?? false,
      savingsVsMostExpensiveUsd: (json['savings_vs_most_expensive_usd'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GroceryListModel {
  final int id;
  final String title;
  final int? supermarketId;
  final String? supermarketName;
  final String status;
  final int totalItems;
  final int checkedItems;
  final double progressPercent;
  final double totalEstimatedUsd;
  final double totalEstimatedBs;
  final double totalCheckedUsd;
  final double totalCheckedBs;
  final List<GroceryListItemModel> items;

  GroceryListModel({
    required this.id,
    required this.title,
    this.supermarketId,
    this.supermarketName,
    required this.status,
    required this.totalItems,
    required this.checkedItems,
    required this.progressPercent,
    required this.totalEstimatedUsd,
    required this.totalEstimatedBs,
    required this.totalCheckedUsd,
    required this.totalCheckedBs,
    required this.items,
  });

  factory GroceryListModel.fromJson(Map<String, dynamic> json) {
    return GroceryListModel(
      id: json['id'],
      title: json['title'] ?? 'Lista',
      supermarketId: json['supermarket_id'],
      supermarketName: json['supermarket_name'],
      status: json['status'] ?? 'activa',
      totalItems: json['total_items'] ?? 0,
      checkedItems: json['checked_items'] ?? 0,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      totalEstimatedUsd: (json['total_estimated_usd'] as num?)?.toDouble() ?? 0.0,
      totalEstimatedBs: (json['total_estimated_bs'] as num?)?.toDouble() ?? 0.0,
      totalCheckedUsd: (json['total_checked_usd'] as num?)?.toDouble() ?? 0.0,
      totalCheckedBs: (json['total_checked_bs'] as num?)?.toDouble() ?? 0.0,
      items: (json['items'] as List? ?? [])
          .map((i) => GroceryListItemModel.fromJson(i))
          .toList(),
    );
  }
}

class GroceryListItemModel {
  final int id;
  final int listId;
  final int? productId;
  final String productName;
  final double quantity;
  final String unit;
  final double priceBs;
  final double priceUsd;
  final bool isChecked;

  GroceryListItemModel({
    required this.id,
    required this.listId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.priceBs,
    required this.priceUsd,
    required this.isChecked,
  });

  factory GroceryListItemModel.fromJson(Map<String, dynamic> json) {
    return GroceryListItemModel(
      id: json['id'],
      listId: json['list_id'],
      productId: json['product_id'],
      productName: json['product_name'] ?? 'Producto',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] ?? 'unidad',
      priceBs: (json['price_bs'] as num?)?.toDouble() ?? 0.0,
      priceUsd: (json['price_usd'] as num?)?.toDouble() ?? 0.0,
      isChecked: json['is_checked'] == 1 || json['is_checked'] == true,
    );
  }
}
