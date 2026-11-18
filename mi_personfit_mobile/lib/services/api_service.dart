import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/dashboard_model.dart';
import '../models/debt_model.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/savings_model.dart';
import '../models/notification_model.dart';
import '../models/exchange_rate_model.dart';
import '../models/payroll_model.dart';
import '../models/grocery_model.dart';
import '../models/share_model.dart';
import '../models/wallet_model.dart';
import '../models/installment_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  UserModel? _currentUser;
  bool showInBs = false; // Selector global de moneda: False = USD ($), True = Bolívares (Bs)
  double activeBcvRate = 914.02;
  double activeParaleloRate = 1045.50;
  double activeUsdtRate = 1052.00;
  double activeEurBcvRate = 1010.56;

  String? get token => _authToken;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // --- PERSISTENCIA, RECORDAR USUARIO & BIOMETRÍA ---

  Future<void> saveSession(String token, UserModel user, {bool remember = false, String? email, String? password}) async {
    _authToken = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    await prefs.setBool('remember_me', remember);
    if (remember && email != null) {
      await prefs.setString('saved_email', email);
      if (password != null) await prefs.setString('saved_password', password);
    }
  }

  Future<bool> loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userDataStr = prefs.getString('user_data');
      if (token != null && userDataStr != null) {
        _authToken = token;
        _currentUser = UserModel.fromJson(jsonDecode(userDataStr));
        showInBs = prefs.getBool('show_in_bs') ?? false;
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('saved_email'),
      'password': prefs.getString('saved_password'),
      'remember_me': (prefs.getBool('remember_me') ?? false) ? 'true' : 'false',
      'biometrics_enabled': (prefs.getBool('biometrics_enabled') ?? false) ? 'true' : 'false',
    };
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_enabled', enabled);
  }

  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometrics_enabled') ?? false;
  }

  Future<void> setCurrencyPreference(bool inBs) async {
    showInBs = inBs;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_in_bs', inBs);
  }

  Future<void> clearSession() async {
    _authToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  // --- AUTH ---

  Future<UserModel> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      final user = UserModel.fromJson(data['data']['user']);
      await saveSession(data['data']['token'], user, remember: true, email: email, password: password);
      return user;
    } else {
      throw Exception(data['message'] ?? 'Error al registrar usuario');
    }
  }

  Future<UserModel> login(String email, String password, {bool remember = true}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final user = UserModel.fromJson(data['data']['user']);
      await saveSession(data['data']['token'], user, remember: remember, email: email, password: password);
      return user;
    } else {
      throw Exception(data['message'] ?? 'Error al iniciar sesión');
    }
  }

  void logout() {
    clearSession();
  }

  // --- DASHBOARD ---

  Future<DashboardModel> getDashboard({String? month}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/dashboard').replace(
      queryParameters: month != null ? {'month': month} : null,
    );
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return DashboardModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al cargar el dashboard');
    }
  }

  // --- NÓMINA & CALENDARIO DE COBROS ---

  Future<PayrollSummary> getPayrollSummary() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payroll/summary'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return PayrollSummary.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al cargar resumen de nómina');
    }
  }

  Future<List<PayrollCalendarItem>> getPayrollCalendar({int count = 6}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payroll/calendar?count=$count'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['data'] as List)
          .map((e) => PayrollCalendarItem.fromJson(e))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar calendario de cobros');
    }
  }

  // --- DEUDAS & PRÉSTAMOS TOMADOS ---

  Future<List<DebtModel>> getDebts({String? status}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/debts').replace(
      queryParameters: status != null ? {'status': status} : null,
    );
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => DebtModel.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar deudas');
    }
  }

  Future<DebtModel> createDebt(Map<String, dynamic> debtData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/debts'),
      headers: _headers,
      body: jsonEncode(debtData),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return DebtModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al registrar deuda');
    }
  }

  // Registrar dinero prestado ("Pedí prestado")
  Future<DebtModel> createBorrowedMoney({
    required String creditor,
    required double amount,
    String currency = 'USD',
    required String dueDate,
    bool deductFromSalary = true,
    String? notes,
  }) async {
    final debtData = {
      'title': 'Préstamo de $creditor',
      'creditor': creditor,
      'total_amount': amount,
      'current_balance': amount,
      'monthly_payment': amount,
      'interest_rate': 0.0,
      'due_day': DateTime.tryParse(dueDate)?.day ?? 15,
      'next_due_date': dueDate,
      'status': 'activa',
      'currency': currency,
      'deduct_from_salary': deductFromSalary,
      'is_borrowed': 1,
      'notes': notes ?? 'Préstamo recibido que incrementa tus deudas activas.',
    };

    return createDebt(debtData);
  }

  Future<List<DebtModel>> getPaidDebtsHistory() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/debts/history/paid'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => DebtModel.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar historial de deudas');
    }
  }

  Future<void> recordDebtPayment(int debtId, double amount, String paymentDate, {String? notes}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/debts/$debtId/payments'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'payment_date': paymentDate,
        'notes': notes,
      }),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Error al registrar pago de deuda');
    }
  }

  Future<void> deleteDebt(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/debts/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error al eliminar deuda');
    }
  }

  Future<Map<String, dynamic>> getDebtStrategies() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/debts/strategies'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Error al cargar estrategias de liquidación');
    }
  }

  // --- INGRESOS ---

  Future<List<IncomeModel>> getIncomes({String? month}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/incomes').replace(
      queryParameters: month != null ? {'month': month} : null,
    );
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => IncomeModel.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar ingresos');
    }
  }

  Future<IncomeModel> createIncome(Map<String, dynamic> incomeData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/incomes'),
      headers: _headers,
      body: jsonEncode(incomeData),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return IncomeModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al registrar ingreso');
    }
  }

  // --- GASTOS ---

  Future<List<ExpenseModel>> getExpenses({String? month, int? isPaid, String? type, String? period}) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month;
    if (isPaid != null) queryParams['is_paid'] = isPaid.toString();
    if (type != null) queryParams['type'] = type;
    if (period != null && period.isNotEmpty) queryParams['period'] = period;

    final uri = Uri.parse('${ApiConfig.baseUrl}/expenses').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => ExpenseModel.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar gastos');
    }
  }

  Future<ExpenseModel> createExpense(Map<String, dynamic> expenseData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/expenses'),
      headers: _headers,
      body: jsonEncode(expenseData),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return ExpenseModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al registrar gasto');
    }
  }

  Future<void> markExpenseAsPaid(int id) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/expenses/$id'),
      headers: _headers,
      body: jsonEncode({'is_paid': 1}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error al actualizar gasto');
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/categories'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar categorías');
    }
  }

  // --- METAS DE AHORRO ---

  Future<List<SavingsGoalModel>> getSavingsGoals() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/savings'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => SavingsGoalModel.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar metas de ahorro');
    }
  }

  Future<SavingsGoalModel> createSavingsGoal(Map<String, dynamic> goalData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/savings'),
      headers: _headers,
      body: jsonEncode(goalData),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return SavingsGoalModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al registrar meta');
    }
  }

  Future<void> addSavingsTransaction(int goalId, double amount, String date, {String? notes}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/savings/$goalId/transactions'),
      headers: _headers,
      body: jsonEncode({'amount': amount, 'date': date, 'notes': notes}),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Error al registrar transacción');
    }
  }

  // --- NOTIFICACIONES ---

  Future<List<NotificationModel>> getNotifications() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/notifications'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['data']['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar notificaciones');
    }
  }

  // --- TASAS DE CAMBIO VENEZUELA & CALCULADORA ---

  Future<ExchangeRatesSummaryModel> getExchangeRates() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/rates'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final summary = ExchangeRatesSummaryModel.fromJson(data['data']);
        if (summary.usdBcv > 0) activeBcvRate = summary.usdBcv;
        if (summary.usdParalelo > 0) activeParaleloRate = summary.usdParalelo;
        if (summary.usdtBinance > 0) activeUsdtRate = summary.usdtBinance;
        if (summary.eurBcv > 0) activeEurBcvRate = summary.eurBcv;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('cached_bcv_rate', activeBcvRate);
        await prefs.setDouble('cached_paralelo_rate', activeParaleloRate);
        await prefs.setDouble('cached_usdt_rate', activeUsdtRate);
        await prefs.setDouble('cached_eur_bcv_rate', activeEurBcvRate);
        return summary;
      } else {
        throw Exception(data['message'] ?? 'Error al cargar tasas de cambio');
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      activeBcvRate = prefs.getDouble('cached_bcv_rate') ?? activeBcvRate;
      activeParaleloRate = prefs.getDouble('cached_paralelo_rate') ?? activeParaleloRate;
      activeUsdtRate = prefs.getDouble('cached_usdt_rate') ?? activeUsdtRate;
      activeEurBcvRate = prefs.getDouble('cached_eur_bcv_rate') ?? activeEurBcvRate;
      rethrow;
    }
  }

  Future<ConversionResultModel> convertCurrency({
    required double amount,
    required String from,
    required String to,
    String rateType = 'oficial',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/rates/convert'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'from': from,
        'to': to,
        'rate_type': rateType,
      }),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return ConversionResultModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al convertir moneda');
    }
  }

  // --- SUPERMERCADOS, PRODUCTOS & LISTAS DE COMPRAS ---

  Future<LocationsData> getSupermarketLocations() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/groceries/locations'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return LocationsData.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al cargar ubicaciones');
    }
  }

  Future<List<Supermarket>> getSupermarkets({String? state, String? municipality, String? search}) async {
    final params = <String, String>{};
    if (state != null && state.isNotEmpty) params['state'] = state;
    if (municipality != null && municipality.isNotEmpty && municipality != 'Todos') params['municipality'] = municipality;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('${ApiConfig.baseUrl}/groceries/supermarkets')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => Supermarket.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar supermercados');
    }
  }

  Future<List<GroceryProduct>> getGroceryProducts() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/groceries/products'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => GroceryProduct.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar productos');
    }
  }

  Future<List<ProductComparisonItem>> getCompareProducts({String? state, String? municipality}) async {
    final params = <String, String>{};
    if (state != null && state.isNotEmpty) params['state'] = state;
    if (municipality != null && municipality.isNotEmpty && municipality != 'Todos') params['municipality'] = municipality;

    final uri = Uri.parse('${ApiConfig.baseUrl}/groceries/compare-products')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => ProductComparisonItem.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al comparar productos');
    }
  }

  Future<Map<String, dynamic>> getCompareSupermarkets({String? state, String? municipality}) async {
    final params = <String, String>{};
    if (state != null && state.isNotEmpty) params['state'] = state;
    if (municipality != null && municipality.isNotEmpty && municipality != 'Todos') params['municipality'] = municipality;

    final uri = Uri.parse('${ApiConfig.baseUrl}/groceries/compare-supermarkets')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final rankings = (data['data']['rankings'] as List)
          .map((e) => SupermarketRanking.fromJson(e))
          .toList();
      final cheapest = data['data']['cheapest_supermarket'] != null
          ? SupermarketRanking.fromJson(data['data']['cheapest_supermarket'])
          : null;
      return {
        'rankings': rankings,
        'cheapest_supermarket': cheapest,
        'filter': data['data']['filter'],
      };
    } else {
      throw Exception(data['message'] ?? 'Error al comparar supermercados');
    }
  }

  Future<List<GroceryListModel>> getGroceryLists() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/groceries/lists'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => GroceryListModel.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar listas');
    }
  }

  Future<GroceryListModel> createGroceryList(String title, {int? supermarketId, String? notes}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/groceries/lists'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'supermarket_id': supermarketId,
        'notes': notes,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return GroceryListModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al crear lista');
    }
  }

  Future<GroceryListModel> getGroceryListDetails(int listId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/groceries/lists/$listId'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return GroceryListModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al cargar detalles de la lista');
    }
  }

  Future<GroceryListModel> addGroceryListItem(
    int listId, {
    int? productId,
    required String productName,
    double quantity = 1,
    String unit = 'unidad',
    double priceBs = 0,
    double priceUsd = 0,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/groceries/lists/$listId/items'),
      headers: _headers,
      body: jsonEncode({
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit': unit,
        'price_bs': priceBs,
        'price_usd': priceUsd,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return GroceryListModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al agregar ítem');
    }
  }

  Future<GroceryListModel> toggleGroceryListItem(int listId, int itemId, bool isChecked) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/groceries/lists/$listId/items/$itemId/toggle'),
      headers: _headers,
      body: jsonEncode({'is_checked': isChecked}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return GroceryListModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al actualizar ítem');
    }
  }

  Future<void> deleteGroceryListItem(int listId, int itemId) async {
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/groceries/lists/$listId/items/$itemId'),
      headers: _headers,
    );
  }

  Future<void> deleteGroceryList(int listId) async {
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/groceries/lists/$listId'),
      headers: _headers,
    );
  }

  // --- PERFILES FINANCIEROS COMPARTIDOS TEMPORALMENTE ---

  Future<SharedProfileToken> createShareToken(int durationMinutes) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/profile/share'),
      headers: _headers,
      body: jsonEncode({'duration_minutes': durationMinutes}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return SharedProfileToken.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al generar enlace temporal');
    }
  }

  Future<List<UserShareItem>> getUserShares() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/profile/shares'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => UserShareItem.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al consultar enlaces activos');
    }
  }

  Future<void> revokeShare(String token) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/profile/shares/$token/revoke'),
      headers: _headers,
    );
  }

  Future<SharedProfileData> getSharedProfile(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/profile/shared/$token'),
    );
    final data = jsonDecode(response.body);
    return SharedProfileData.fromJson(data['data'] ?? {'is_valid': false, 'message': data['message']});
  }

  // --- BILLETERAS VENEZOLANAS (BS, EFECTIVO $, BINANCE USDT, ZELLE, ZINLI, EURO) ---

  Future<WalletsSummaryModel> getWallets() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/wallets'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return WalletsSummaryModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al cargar billeteras');
    }
  }

  Future<WalletModel> createWallet(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/wallets'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return WalletModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al crear billetera');
    }
  }

  Future<WalletModel> updateWallet(int id, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/wallets/$id'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return WalletModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al actualizar billetera');
    }
  }

  Future<void> deleteWallet(int id) async {
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/wallets/$id'),
      headers: _headers,
    );
  }

  // --- CONTROL DE CUOTAS (CASHEA / KRECE / CRÉDITOS CADA 14 DÍAS) ---

  Future<InstallmentsSummaryModel> getInstallmentPlans() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/installments'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return InstallmentsSummaryModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al cargar planes de cuotas');
    }
  }

  Future<InstallmentPlanModel> createInstallmentPlan(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/installments'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return InstallmentPlanModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al registrar compra en cuotas');
    }
  }

  Future<InstallmentPlanModel> toggleInstallmentPayment(int paymentId) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/installments/payments/$paymentId/toggle'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return InstallmentPlanModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al actualizar cuota');
    }
  }

  Future<void> deleteInstallmentPlan(int planId) async {
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/installments/$planId'),
      headers: _headers,
    );
  }

  // --- MINIMARKETS / TIENDAS NO REGISTRADAS & PRECIOS COLABORATIVOS ---

  Future<Supermarket> createSupermarket(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/groceries/supermarkets'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return Supermarket.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al registrar comercio');
    }
  }

  Future<Map<String, dynamic>> recordGroceryPrice(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/groceries/prices'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'Error al reportar precio');
    }
  }

  // --- MODO OFFLINE PARA SUPERMERCADOS (CACHÉ LOCAL) ---

  Future<void> saveOfflineGroceryList(GroceryListModel list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_active_grocery_list', jsonEncode(list.toJson()));
  }

  Future<GroceryListModel?> loadOfflineGroceryList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('offline_active_grocery_list');
      if (str != null) {
        return GroceryListModel.fromJson(jsonDecode(str));
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveOfflineSupermarkets(List<Supermarket> supers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_supermarkets', jsonEncode(supers.map((s) => s.toJson()).toList()));
  }

  Future<List<Supermarket>> loadOfflineSupermarkets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('offline_supermarkets');
      if (str != null) {
        return (jsonDecode(str) as List).map((e) => Supermarket.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}
