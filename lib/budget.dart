import 'package:budget_planner/home2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  String? _selectedMonthYear;
  List<Map<String, dynamic>> _budgetedCategories = [];
  final List<Map<String, dynamic>> _notBudgetedCategories = [
    {"name": "Food", "icon": Icons.food_bank},
    {"name": "Transport", "icon": Icons.car_crash},
    {"name": "Lifestyle", "icon": Icons.receipt},
    {"name": "Rent", "icon": Icons.house},
    {"name": "Education", "icon": Icons.read_more},
    {"name": "Others", "icon": Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonthYear = DateFormat('MMM, yyyy').format(DateTime.now());
    _fetchBudgetedCategories();
  }

  Future<void> _fetchBudgetedCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc(_selectedMonthYear)
        .get();

    if (snapshot.exists) {
      setState(() {
        _budgetedCategories =
            List<Map<String, dynamic>>.from(snapshot.data()!['categories']);
      });
      setState(() {
        _notBudgetedCategories.removeWhere((category) => _budgetedCategories
            .any((budgeted) => budgeted['name'] == category['name']));
      });

      await _fetchExpenses(user.uid);
    }
  }

  Future<void> _fetchExpenses(String userId) async {
    final startDate = DateTime.now().subtract(Duration(days: 30));
    final endDate = DateTime.now();

    final expenseSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    // Initialize spent amounts for each category
    Map<String, double> spentByCategory = {};
    for (var category in _budgetedCategories) {
      spentByCategory[category['name']] = 0.0; // Initialize to 0
    }

    // Calculate total spent by category
    for (var doc in expenseSnapshot.docs) {
      final data = doc.data();
      final isExpense = data['isExpense'] ?? true;
      final amount = (data['amount'] ?? 0).toDouble();
      final category = data['category'] ?? 'Unknown';

      if (isExpense && spentByCategory.containsKey(category)) {
        spentByCategory[category] = spentByCategory[category]! + amount;
      }
    }

    // Update the budgeted categories with spent amounts
    setState(() {
      for (var category in _budgetedCategories) {
        category['spent'] = spentByCategory[category['name']] ?? 0.0;
      }
    });
  }

  void _setBudget(String category) async {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Set Budget for $category"),
          content: TextField(
            controller: amountController,
            decoration: InputDecoration(
                labelText: 'Amount', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                double amount = double.parse(amountController.text);
                await _saveBudget(category, amount);
                Navigator.pop(context);
              },
              child: const Text("Set Budget"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveBudget(String category, double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Save budget to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc(_selectedMonthYear)
        .set({
      'categories': FieldValue.arrayUnion([
        {
          'name': category,
          'amount': amount,
          'spent': 0.0, // default spent to 0
        }
      ])
    }, SetOptions(merge: true));

    // Remove the category from not budgeted categories
    setState(() {
      _notBudgetedCategories.removeWhere((cat) => cat['name'] == category);
    });

    // Refresh budgeted categories
    _fetchBudgetedCategories();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              Home2()), // Replace with your home screen widget
    );
  }

  Future<void> _editBudget(Map<String, dynamic> category) async {
    final TextEditingController amountController =
        TextEditingController(text: category['amount'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Budget for ${category['name']}"),
          content: TextField(
            controller: amountController,
            decoration: InputDecoration(
                labelText: 'Amount', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                double amount = double.parse(amountController.text);
                await _updateBudget(category['name'], amount);
                Navigator.pop(context);
              },
              child: const Text("Update Budget"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateBudget(String categoryName, double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final budgetRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc(_selectedMonthYear);

    final snapshot = await budgetRef.get();
    if (!snapshot.exists) return;

    List<Map<String, dynamic>> categories =
        List<Map<String, dynamic>>.from(snapshot.data()?['categories'] ?? []);

    for (var category in categories) {
      if (category['name'] == categoryName) {
        category['amount'] = amount; // Update the existing category
        break;
      }
    }

    await budgetRef.update({'categories': categories});

    setState(() {
      _budgetedCategories = categories;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              Home2()), // Replace with your home screen widget
    );
  }

  Future<void> _deleteBudget(Map<String, dynamic> category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final budgetRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(_selectedMonthYear);

      final snapshot = await budgetRef.get();
      if (!snapshot.exists) return;

      List<dynamic> categories = snapshot.data()?['categories'] ?? [];

      // Remove the category manually
      categories =
          categories.where((cat) => cat['name'] != category['name']).toList();

      // Update Firestore with new list
      await budgetRef.update({'categories': categories});

      setState(() {
        _budgetedCategories
            .removeWhere((cat) => cat['name'] == category['name']);

        if (!_notBudgetedCategories
            .any((cat) => cat['name'] == category['name'])) {
          _notBudgetedCategories.add({
            "name": category['name'],
            "icon": Icons.category, // Placeholder icon
          });
        }
      });

      // Refresh categories
      await _fetchBudgetedCategories();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                Home2()), // Replace with your home screen widget
      );
    } catch (e) {
      print("Error deleting budget: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Budgeted Categories: $_selectedMonthYear",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          if (_budgetedCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text("Currently, no budget is applied for this month.\n"),
            )
          else
            ..._budgetedCategories.map((category) {
              bool isOverspent = category['spent'] > category['amount'];
              return GestureDetector(
                onLongPress: () {
                  _showBudgetOptions(category);
                },
                child: Card(
                  color: isOverspent ? Colors.red[100] : null,
                  child: ListTile(
                    leading: Icon(Icons.money), // Placeholder for category icon
                    title: Text(category['name']),
                    subtitle: Text(
                        "Limit: ₹${category['amount']}, Spent: ₹${category['spent']}"),
                  ),
                ),
              );
            }),
          const SizedBox(height: 30),
          Text(
            "Not budgeted this month",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: _notBudgetedCategories.map((category) {
                return Card(
                  child: ListTile(
                    leading: Icon(category['icon']),
                    title: Text(category['name']),
                    trailing: ElevatedButton(
                      onPressed: () => _setBudget(category['name']),
                      child: const Text("SET BUDGET"),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetOptions(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Options for ${category['name']}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _editBudget(category);
              },
              child: const Text("Edit Budget"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteBudget(category);
              },
              child: const Text("Delete Budget"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}
