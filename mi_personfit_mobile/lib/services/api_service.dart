import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/dashboard_model.dart';
import '../models/debt_model.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/savings_model.dart';
import '../models/notification_model.dart';
import '../models/exchange_rate_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  UserModel? _currentUser;

  String? get token => _authToken;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // --- AUTH ---

  Future<UserModel> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      _authToken = data['data']['token'];
      _currentUser = UserModel.fromJson(data['data']['user']);
      return _currentUser!;
    } else {
      throw Exception(data['message'] ?? 'Error al registrar usuario');
    }
  }

  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      _authToken = data['data']['token'];
      _currentUser = UserModel.fromJson(data['data']['user']);
      return _currentUser!;
    } else {
      throw Exception(data['message'] ?? 'Credenciales inválidas');
    }
  }

  void logout() {
    _authToken = null;
    _currentUser = null;
  }

  // --- DASHBOARD ---

  Future<DashboardModel> getDashboard({String? month}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/dashboard${month != null ? '?month=$month' : ''}');
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return DashboardModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al cargar dashboard');
    }
  }

  // --- DEBTS ---

  Future<List<DebtModel>> getDebts({String? status}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/debts${status != null ? '?status=$status' : ''}');
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => DebtModel.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar deudas');
    }
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

  Future<Map<String, dynamic>> getDebtStrategies() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/debts/strategies'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Error al cargar estrategias');
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

  Future<Map<String, dynamic>> recordDebtPayment(int debtId, double amount, String date, String? notes) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/debts/$debtId/payments'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'payment_date': date,
        'notes': notes,
      }),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Error al registrar abono');
    }
  }

  // --- INCOMES ---

  Future<List<IncomeModel>> getIncomes({String? month}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/incomes${month != null ? '?month=$month' : ''}');
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

  // --- EXPENSES & CATEGORIES ---

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

  Future<List<ExpenseModel>> getExpenses({String? month, int? isPaid, String? type}) async {
    final queryParams = <String>[];
    if (month != null) queryParams.add('month=$month');
    if (isPaid != null) queryParams.add('is_paid=$isPaid');
    if (type != null) queryParams.add('type=$type');
    final queryStr = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/expenses$queryStr'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => ExpenseModel.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar gastos');
    }
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> expenseData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/expenses'),
      headers: _headers,
      body: jsonEncode(expenseData),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {
        'expense': ExpenseModel.fromJson(data['data']),
        'warning': data['budget_warning'],
      };
    } else {
      throw Exception(data['message'] ?? 'Error al registrar gasto');
    }
  }

  Future<ExpenseModel> markExpenseAsPaid(int expenseId) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/expenses/$expenseId/pay'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return ExpenseModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al marcar factura como pagada');
    }
  }

  // --- SAVINGS ---

  Future<List<SavingsGoalModel>> getSavingsGoals() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/savings'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => SavingsGoalModel.fromJson(e)).toList();
    } else {
      throw Exception(data['message'] ?? 'Error al cargar metas');
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
      throw Exception(data['message'] ?? 'Error al crear meta');
    }
  }

  Future<SavingsGoalModel> recordSavingsTransaction(int goalId, double amount, String date, String? notes) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/savings/$goalId/transactions'),
      headers: _headers,
      body: jsonEncode({'amount': amount, 'date': date, 'notes': notes}),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return SavingsGoalModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al registrar transacción');
    }
  }

  // --- NOTIFICATIONS ---

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
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/rates'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return ExchangeRatesSummaryModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al cargar tasas de cambio');
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
}
