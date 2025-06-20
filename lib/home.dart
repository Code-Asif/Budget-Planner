// // All methods available in this page are - _loadBalance, _checkUser, _logout, _saveBudget, _addTransaction, _showBudgetDialog, _showAddTransactionDialog,
// import 'package:budget_planner/profile.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   int _currentTabIndex = 0;
//   bool _isNewUser = true;
//   double _balance = 0.0;
//   final Map<String, double> _budget = {};
//   final List<String> _budgetCategories = [
//     'Income',
//     'Rent',
//     'Education',
//     'Transport',
//     'Medical',
//     'Food',
//     'Others'
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _checkUser();
//     _loadBalance();
//   }

//   void _loadBalance() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//       if (doc.exists) {
//         final data = doc.data() as Map<String, dynamic>;
//         setState(() {
//           _balance = (data['balance'] ?? 0.0).toDouble();
//         });
//       }
//     }
//   }

//   void _checkUser() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();

//       // Check if it's the first day of the month
//       final now = DateTime.now();
//       final lastBudgetUpdate = doc.exists
//           ? (doc.data()?['lastBudgetUpdate'] as Timestamp?)?.toDate()
//           : null;

//       setState(() {
//         _isNewUser = !doc.exists ||
//             lastBudgetUpdate == null ||
//             now.day == 1 &&
//                 (lastBudgetUpdate.month != now.month ||
//                     lastBudgetUpdate.year != now.year);
//       });
//     }
//   }

//   void _logout() async {
//     await FirebaseAuth.instance.signOut();
//     if (mounted) {
//       Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   void _saveBudget() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
//         'budget': _budget,
//         'lastBudgetUpdate': FieldValue.serverTimestamp(),
//         'balance': _budget['Income'] ?? 0.0,
//       });
//       setState(() {
//         _isNewUser = false;
//         _balance = _budget['Income'] ?? 0.0;
//       });
//     }
//   }

//   Future<void> _addTransaction(
//       String category, double amount, bool isExpense) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final newBalance = isExpense ? _balance - amount : _balance + amount;

//       await FirebaseFirestore.instance.collection('transactions').add({
//         'userId': user.uid,
//         'category': category,
//         'amount': amount,
//         'isExpense': isExpense,
//         'date': FieldValue.serverTimestamp(),
//       });

//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .update({'balance': newBalance});

//       setState(() {
//         _balance = newBalance;
//       });
//     }
//   }

//   void _showBudgetDialog() {
//     int currentIndex = 0;
//     String input = '';

//     void nextQuestion() {
//       if (currentIndex < _budgetCategories.length) {
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) {
//             return AlertDialog(
//               title: Text('Set budget for ${_budgetCategories[currentIndex]}:'),
//               content: TextField(
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(
//                   hintText: 'Enter amount',
//                   prefixText: '₹',
//                 ),
//                 onChanged: (value) => input = value,
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     if (input.isNotEmpty) {
//                       setState(() {
//                         _budget[_budgetCategories[currentIndex]] =
//                             double.tryParse(input) ?? 0.0;
//                         currentIndex++;
//                         input = '';
//                       });
//                       Navigator.pop(context);
//                       if (currentIndex < _budgetCategories.length) {
//                         nextQuestion();
//                       } else {
//                         _saveBudget();
//                       }
//                     }
//                   },
//                   child: const Text('Next'),
//                 ),
//               ],
//             );
//           },
//         );
//       }
//     }

//     nextQuestion();
//   }

//   void _showAddTransactionDialog() {
//     String selectedCategory =
//         _budgetCategories[1]; // Default to first expense category
//     String amount = '';
//     bool isExpense = true;

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: const Text('Add Income/Expense'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     children: [
//                       const Text('Select :     '),
//                       DropdownButton<String>(
//                         value: selectedCategory,
//                         items: _budgetCategories.map((category) {
//                           return DropdownMenuItem(
//                             value: category,
//                             child: Text(category),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             selectedCategory = value!;
//                             isExpense = value != 'Income';
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                   TextField(
//                     keyboardType: TextInputType.number,
//                     decoration: const InputDecoration(
//                       hintText: 'Enter amount',
//                       prefixText: '₹',
//                     ),
//                     onChanged: (value) => amount = value,
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     if (amount.isNotEmpty) {
//                       _addTransaction(
//                         selectedCategory,
//                         double.parse(amount),
//                         isExpense,
//                       );
//                       Navigator.pop(context);
//                     }
//                   },
//                   child: const Text('Add'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isNewUser) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _showBudgetDialog();
//       });
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('H O M E'),
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
//                     'Expense Tracker',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                     ),
//                   ),
//                   const Icon(Icons.currency_rupee, size: 100, color: Colors.white),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text('Profile'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const ProfilePage()),
//                 );
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

//       //  Body start from here
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   DateFormat('dd MMM yyyy').format(DateTime.now()),
//                   style: const TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 Text(
//                   'Balance: ₹${_balance.toStringAsFixed(2)}',
//                   style: const TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildTab('Daily', 0),
//               _buildTab('Monthly', 1),
//               _buildTab('Yearly', 2),
//             ],
//           ),
//           Expanded(
//             child: _buildTransactionsList(),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showAddTransactionDialog,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   Widget _buildTransactionsList() {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return const SizedBox();

//     Query transactionsQuery = FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('transactions');

//     // Apply different queries based on the selected tab
//     switch (_currentTabIndex) {
//       case 0: // Daily
//         final today = DateTime.now();
//         final startOfDay = DateTime(today.year, today.month, today.day);
//         final endOfDay =
//             DateTime(today.year, today.month, today.day, 23, 59, 59);

//         transactionsQuery = transactionsQuery
//             .where('date',
//                 isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
//             .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
//         break;

//       case 1: // Monthly
//         final now = DateTime.now();
//         final startOfMonth = DateTime(now.year, now.month, 1);
//         final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

//         transactionsQuery = transactionsQuery
//             .where('date',
//                 isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
//             .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth));
//         break;

//       case 2: // Yearly
//         final now = DateTime.now();
//         final startOfYear = DateTime(now.year, 1, 1);
//         final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

//         transactionsQuery = transactionsQuery
//             .where('date',
//                 isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
//             .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear));
//         break;
//     }

//     // Add ordering after the date filtering
//     transactionsQuery = transactionsQuery.orderBy('date', descending: true);

//     return StreamBuilder<QuerySnapshot>(
//       stream: transactionsQuery.snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final transactions = snapshot.data?.docs ?? [];

//         if (transactions.isEmpty) {
//           return const Center(
//             child: Text(
//               'No transactions for this period',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey,
//               ),
//             ),
//           );
//         }

//         return ListView.builder(
//           itemCount: transactions.length,
//           itemBuilder: (context, index) {
//             final transaction =
//                 transactions[index].data() as Map<String, dynamic>;
//             final isExpense = transaction['type'] == 'Expense';
//             final amount = transaction['amount'] as double;
//             final date = (transaction['date'] as Timestamp).toDate();

//             return Card(
//               margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: isExpense ? Colors.red : Colors.green,
//                   child: Icon(
//                     isExpense ? Icons.remove : Icons.add,
//                     color: Colors.white,
//                   ),
//                 ),
//                 title: Text(
//                   transaction['description'] ?? '',
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(
//                   '${transaction['category']} • ${DateFormat('dd MMM yyyy, HH:mm').format(date)}',
//                 ),
//                 trailing: Text(
//                   '${isExpense ? '-' : '+'}₹${amount.toStringAsFixed(2)}',
//                   style: TextStyle(
//                     color: isExpense ? Colors.red : Colors.green,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildTab(String title, int index) {
//     return GestureDetector(
//       onTap: () => setState(() => _currentTabIndex = index),
//       child: Column(
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: _currentTabIndex == index ? const Color.fromARGB(255, 244, 30, 15) : Colors.grey,
//             ),
//           ),
//           if (_currentTabIndex == index)
//             Container(
//               height: 2,
//               width: 60,
//               color: Colors.blue,
//               margin: const EdgeInsets.only(top: 4),
//             ),
//         ],
//       ),
//     );
//   }
// }

//  ------------------------------------------------------------------------

import 'package:budget_planner/profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'daily_tab.dart';
import 'monthly_tab.dart';
import 'yearly_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTabIndex = 0;
  bool _isNewUser = true;
  double _balance = 0.0;
  final Map<String, double> _budget = {};
  final List<String> _budgetCategories = [
    'Income',
    'Rent',
    'Education',
    'Transport',
    'Medical',
    'Food',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    _checkUser();
    _loadBalance();
  }

  void _loadBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _balance = (data['balance'] ?? 0.0).toDouble();
        });
      }
    }
  }

  void _checkUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final now = DateTime.now();
      final lastBudgetUpdate = doc.exists
          ? (doc.data()?['lastBudgetUpdate'] as Timestamp?)?.toDate()
          : null;

      final hasBudget = doc.exists && doc.data()?['budget'] != null;

      setState(() {
        _isNewUser = !hasBudget ||
            (now.day == 1 &&
                (lastBudgetUpdate?.month != now.month ||
                    lastBudgetUpdate?.year != now.year));
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _saveBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'budget': _budget,
        'lastBudgetUpdate': FieldValue.serverTimestamp(),
        'balance': _budget['Income'] ?? 0.0,
      }, SetOptions(merge: true)); // Merge instead of overwrite

      setState(() {
        _isNewUser = false;
        _balance = _budget['Income'] ?? 0.0;
      });
    }
  }

  Future<void> _addTransaction(
      String category, double amount, bool isExpense) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final newBalance = isExpense ? _balance - amount : _balance + amount;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add({
        'category': category,
        'amount': amount,
        'isExpense': isExpense,
        'date': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'balance': newBalance});

      setState(() {
        _balance = newBalance;
      });
    }
  }

  void _showBudgetDialog() {
    if (_isNewUser) {
      int currentIndex = 0;
      String input = '';

      void nextQuestion() {
        if (currentIndex < _budgetCategories.length) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title:
                    Text('Set budget for ${_budgetCategories[currentIndex]}:'),
                content: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter amount',
                    prefixText: '₹',
                  ),
                  onChanged: (value) => input = value,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (input.isNotEmpty) {
                        setState(() {
                          _budget[_budgetCategories[currentIndex]] =
                              double.tryParse(input) ?? 0.0;
                          currentIndex++;
                          input = '';
                        });
                        Navigator.pop(context);
                        if (currentIndex < _budgetCategories.length) {
                          nextQuestion();
                        } else {
                          _saveBudget();
                        }
                      }
                    },
                    child: const Text('Next'),
                  ),
                ],
              );
            },
          );
        }
      }

      nextQuestion();
    }
  }

  void _showAddTransactionDialog() {
    String selectedCategory =
        _budgetCategories[1]; // Default to first expense category
    String amount = '';
    bool isExpense = true;

    // Fetch the budget amount for the selected category
    double fetchedAmount = _budget[selectedCategory] ?? 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Income/Expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Select :     '),
                      DropdownButton<String>(
                        value: selectedCategory,
                        items: _budgetCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                            isExpense = value != 'Income';
                            // Update fetched amount when category changes
                            fetchedAmount = _budget[selectedCategory] ?? 0.0;
                            amount = fetchedAmount.toString();
                          });
                        },
                      ),
                    ],
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      prefixText: '₹',
                    ),
                    controller: TextEditingController(text: amount),
                    onChanged: (value) => amount = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (amount.isNotEmpty) {
                      _addTransaction(
                        selectedCategory,
                        double.parse(amount),
                        isExpense,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
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
    if (_isNewUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBudgetDialog();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('H O M E'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                children: [
                  const Text(
                    'Expense Tracker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const Icon(Icons.currency_rupee,
                      size: 100, color: Colors.white),
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
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),

      // Body start from here
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.now()),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Balance: ₹${_balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTab('Daily', 0),
              _buildTab('Monthly', 1),
              _buildTab('Yearly', 2),
            ],
          ),
          Expanded(
            child: _currentTabIndex == 0
                ? DailyTab() // Use the DailyTab widget
                : _currentTabIndex == 1
                    ? MonthlyTab() // Use the MonthlyTab widget
                    : YearlyTab(), // Use the YearlyTab widget
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _currentTabIndex == index
                  ? const Color.fromARGB(255, 244, 30, 15)
                  : Colors.grey,
            ),
          ),
          if (_currentTabIndex == index)
            Container(
              height: 2,
              width: 60,
              color: Colors.blue,
              margin: const EdgeInsets.only(top: 4),
            ),
        ],
      ),
    );
  }
}