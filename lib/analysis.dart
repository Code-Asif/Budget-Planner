import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String? _selectedMonthYear;
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _budgetedCategories = [];
  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _selectedMonthYear = DateFormat('MMM, yyyy').format(DateTime.now());
    _fetchData();

    // Listening to Firestore changes for real-time updates
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('transactions')
        .snapshots()
        .listen((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _fetchExpenses(user.uid);
    await _fetchBudget(user.uid);
  }

  Future<void> _fetchExpenses(String userId) async {
    final startDate = DateTime.now().subtract(Duration(days: 30));
    final endDate = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categoryExpenses = {};

    List<Map<String, dynamic>> expenses = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final isExpense = data['isExpense'] ?? true;
      final amount = (data['amount'] ?? 0).toDouble();
      final category = data['category'] ?? 'Unknown';

      if (isExpense) {
        totalExpense += amount;
        categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;
      } else {
        totalIncome += amount;
      }

      expenses.add({'category': category, 'amount': amount});
    }

    setState(() {
      _totalIncome = totalIncome;
      _totalExpense = totalExpense;
      _expenses = categoryExpenses.entries
          .map((entry) => {'category': entry.key, 'amount': entry.value})
          .toList();
    });
  }

  Future<void> _fetchBudget(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(_selectedMonthYear)
        .get();

    if (snapshot.exists) {
      List<Map<String, dynamic>> budgetedCategories =
          List<Map<String, dynamic>>.from(snapshot.data()!['categories']);

      // Initialize spent amounts to 0
      Map<String, double> spentByCategory = {};
      for (var category in budgetedCategories) {
        spentByCategory[category['name']] = 0.0;
      }

      // Fetch expenses for the selected month
      final startDate = DateTime.now().subtract(Duration(days: 30));
      final endDate = DateTime.now();
      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      // Calculate spent amount for each category
      for (var doc in expenseSnapshot.docs) {
        final data = doc.data();
        final isExpense = data['isExpense'] ?? true;
        final amount = (data['amount'] ?? 0).toDouble();
        final category = data['category'] ?? 'Unknown';

        if (isExpense && spentByCategory.containsKey(category)) {
          spentByCategory[category] = spentByCategory[category]! + amount;
        }
      }

      // Update categories with spent values
      setState(() {
        _budgetedCategories = budgetedCategories.map((category) {
          return {
            'name': category['name'],
            'amount': category['amount'],
            'spent': spentByCategory[category['name']] ??
                0.0, // Correctly update spent
          };
        }).toList();
      });
    }
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansRegular();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch transactions from Firestore
    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();

    final transactions = transactionsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'date': (data['date'] as Timestamp).toDate(),
        'category': data['category'],
        'amount': data['amount'],
        'isExpense': data['isExpense']
      };
    }).toList();

    // Group transactions by date
    final Map<String, List<Map<String, dynamic>>> groupedTransactions = {};
    for (var transaction in transactions) {
      String dateKey = DateFormat('yyyy-MM-dd').format(transaction['date']);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Center(
                  child: pw.Text("Personal Expense Tracker with Data Analysis",
                      style: pw.TextStyle(
                          font: font,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),

                // Summary Section
                pw.Text("Summary",
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text("Total Income: ₹$_totalIncome",
                    style: pw.TextStyle(font: font)),
                pw.Text("Total Expense: ₹$_totalExpense",
                    style: pw.TextStyle(font: font)),
                pw.Text("Total Savings: ₹${_totalIncome - _totalExpense}",
                    style: pw.TextStyle(font: font)),
                pw.SizedBox(height: 20),

                // Category-wise Expenses Table
                pw.Text("Category-wise Expenses",
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Table.fromTextArray(
                  headers: ["Category", "Amount"],
                  data: _expenses
                      .map((e) => [e['category'], "₹${e['amount']}"])
                      .toList(),
                  headerStyle:
                      pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(font: font),
                  border: pw.TableBorder.all(),
                ),
                pw.SizedBox(height: 20),

                // Budget vs Expense Section
                pw.Text("Budget vs Expense",
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                for (var category in _budgetedCategories)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(category['name'],
                          style: pw.TextStyle(font: font)),
                      pw.Container(
                        height: 10,
                        width: double.infinity,
                        child: pw.LinearProgressIndicator(
                          value: (category['spent'] / category['amount'])
                              .clamp(0, 1),
                          backgroundColor: PdfColors.grey300,
                          valueColor: category['spent'] > category['amount']
                              ? PdfColors.red
                              : PdfColors.green,
                        ),
                      ),
                      pw.Text(
                          "Spent: ₹${category['spent']} / ₹${category['amount']}",
                          style: pw.TextStyle(font: font)),
                      pw.SizedBox(height: 10),
                    ],
                  ),
                pw.SizedBox(height: 20),

                // Transactions Section (Date-wise)
                pw.Text("All Transactions (Date-wise)",
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                for (var date in groupedTransactions.keys) ...[
                  pw.Text(
                    date,
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Table.fromTextArray(
                    headers: ["Category", "Amount", "Type"],
                    data: groupedTransactions[date]!.map((e) {
                      return [
                        e['category'],
                        "₹${e['amount']}",
                        e['isExpense'] ? "Expense" : "Income"
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                        font: font, fontWeight: pw.FontWeight.bold),
                    cellStyle: pw.TextStyle(font: font),
                    border: pw.TableBorder.all(),
                  ),
                  pw.SizedBox(height: 10),
                ],
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Analysis")),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton(
        onPressed: _generatePDF,
        child: Icon(Icons.picture_as_pdf),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Expense Breakdown",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: SfCircularChart(
                  legend: Legend(isVisible: true),
                  series: <PieSeries<Map<String, dynamic>, String>>[
                    PieSeries<Map<String, dynamic>, String>(
                      dataSource: _expenses,
                      xValueMapper: (data, _) => data['category'],
                      yValueMapper: (data, _) => data['amount'],
                      dataLabelMapper: (data, _) =>
                          "${data['category']}: ₹${data['amount']}",
                      dataLabelSettings: DataLabelSettings(isVisible: true),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Text("Budget vs Expense",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              for (var category in _budgetedCategories)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category['name']),
                    LinearProgressIndicator(
                      value:
                          (category['spent'] / category['amount']).clamp(0, 1),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                          category['spent'] > category['amount']
                              ? Colors.red
                              : Colors.green),
                    ),
                    Text(
                        "Spent: ₹${category['spent']} / ₹${category['amount']}"),
                    SizedBox(height: 10),
                  ],
                ),
              SizedBox(height: 40),
              Text("Total Savings: ₹${_totalIncome - _totalExpense}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
  }
}
