// import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:intl/intl.dart';

// class Home3 extends StatefulWidget {
//   const Home3({super.key});

//   @override
//   State<Home3> createState() => _Home3State();
// }

// class _Home3State extends State<Home3> {

//   void _logout() async {
//     await FirebaseAuth.instance.signOut();
//     if (mounted) {
//       Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Expense Tracker'),
//       ),
//       drawer: Drawer(
//         child: ListView(
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Theme.of(context).primaryColor,
//               ),
//               child: Column(
//                 children: [
//                   const Text(
//                     'H O M E',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                     ),
//                   ),
//                   const Icon(Icons.currency_rupee,
//                       size: 100, color: Colors.white),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text('Profile'),
//               onTap: () {
//                 const SnackBar(content: Text('Profile'));
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text('Logout'),
//               onTap: _logout,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ------------------------------------------------

import 'package:budget_planner/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Home2 extends StatefulWidget {
  const Home2({super.key});

  @override
  State<Home2> createState() => _Home2State();
}

class _Home2State extends State<Home2> {
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _transactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  final List<String> _expenseCategories = [
    "Rent",
    "Bills",
    "Education",
    "Others"
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .get();

    double income = 0, expense = 0;
    List<Map<String, dynamic>> transactions = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final isExpense = data['isExpense'] ?? true;
      final amount = (data['amount'] ?? 0).toDouble();
      final date = (data['date'] as Timestamp).toDate();

      if (isExpense) {
        expense += amount;
      } else {
        income += amount;
      }

      transactions.add({
        'category': data['category'] ?? 'Unknown',
        'amount': amount,
        'isExpense': isExpense,
        'date': date,
      });
    }

    setState(() {
      _transactions = transactions;
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + increment, 1);
    });
    _fetchTransactions();
  }

  Widget _buildTransactionList() {
    Map<String, List<Map<String, dynamic>>> groupedTransactions = {};

    for (var transaction in _transactions) {
      String formattedDate =
          DateFormat('MMM d, EEEE').format(transaction['date']);
      groupedTransactions.putIfAbsent(formattedDate, () => []).add(transaction);
    }

    return ListView(
      children: groupedTransactions.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(entry.key,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Column(
              children: entry.value.map((transaction) {
                return ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(transaction['category']),
                  subtitle: const Text("Cash"), // Add payment mode if needed
                  trailing: Text(
                    "${transaction['isExpense'] ? '-' : '+'} ₹${transaction['amount'].toStringAsFixed(2)}",
                    style: TextStyle(
                      color:
                          transaction['isExpense'] ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showAddTransactionDialog() {
    bool isExpense = true;
    String selectedCategory = _expenseCategories[0]; // Default expense category
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add Transaction"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text("Income"),
                      Switch(
                        value: isExpense,
                        onChanged: (value) {
                          setState(() {
                            isExpense = value;
                            if (!isExpense) {
                              selectedCategory =
                                  "Salary"; // Auto-set category for income
                            }
                          });
                        },
                      ),
                      const Text("Expense"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  isExpense
                      ? DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(),
                          ),
                          items: _expenseCategories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                            });
                          },
                        )
                      : TextField(
                          decoration: const InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: "Salary"),
                          enabled: false, // Income category is fixed
                        ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    controller: amountController,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isNotEmpty) {
                      await _addTransaction(
                        selectedCategory,
                        double.parse(amountController.text),
                        isExpense,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addTransaction(
      String category, double amount, bool isExpense) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final transaction = {
      'category': category,
      'amount': amount,
      'isExpense': isExpense,
      'date': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .add(transaction);

    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("H O M E"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Column(
                children: [
                  Text('Expense Tracker',
                      style: TextStyle(color: Colors.white, fontSize: 24)),
                  Icon(Icons.currency_rupee, size: 50, color: Colors.white),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month Navigation & Summary
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat('MMMM, yyyy').format(_selectedMonth),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // Expense Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryTile("EXPENSE", _totalExpense, Colors.red),
                _buildSummaryTile("INCOME", _totalIncome, Colors.green),
                _buildSummaryTile(
                    "TOTAL", _totalIncome - _totalExpense, Colors.blue),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text("No transactions found"))
                : _buildTransactionList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Records"),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart), label: "Analysis"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance), label: "Budgets"),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String title, double amount, Color color) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text("₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
