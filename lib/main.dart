import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker App',
      theme: ThemeData(
        primarySwatch: Colors.green, // Ganti warna primer menjadi merah
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController walletBalanceController = TextEditingController();
  TextEditingController categoryController =
      TextEditingController(); // Controller untuk kategori pengeluaran

  double walletBalance = 0.0;
  double totalExpenses = 0.0;
  Map<String, double> dailyExpenses =
      {}; // Menyimpan total pengeluaran per hari
  List<ExpenseEntry> expenseList = [];

  DateTime? startDate; // Tanggal awal filter
  DateTime? endDate; // Tanggal akhir filter

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    walletBalance = prefs.getDouble('walletBalance') ?? 0.0;
    totalExpenses = prefs.getDouble('totalExpenses') ?? 0.0;
    walletBalanceController.text = walletBalance.toStringAsFixed(2);

    final jsonStrings = prefs.getStringList('expenseList') ?? [];
    setState(() {
      expenseList = jsonStrings
          .map((e) => ExpenseEntry.fromJson(json.decode(e)))
          .toList();
      _calculateDailyExpenses();
    });
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('walletBalance', walletBalance);
    await prefs.setDouble('totalExpenses', totalExpenses);

    // Simpan daftar pengeluaran ke SharedPreferences
    final jsonData = expenseList.map((e) => e.toJson()).toList();
    final jsonStrings = jsonData.map((e) => json.encode(e)).toList();
    await prefs.setStringList('expenseList', jsonStrings);
  }

  void _addExpense() {
    final amount = double.tryParse(amountController.text) ?? 0.0;
    final date = dateController.text;
    final category =
        categoryController.text; // Menggunakan nilai dari TextField

    if (amount > 0 && date.isNotEmpty && category.isNotEmpty) {
      setState(() {
        walletBalance -= amount;
        totalExpenses += amount;
        expenseList.add(ExpenseEntry(category, amount, date));
        _calculateDailyExpenses();
      });
      _saveData();
      amountController.clear();
      dateController.clear();
      categoryController.clear();
    }
  }

  void _calculateDailyExpenses() {
    // Menghitung total pengeluaran per hari
    dailyExpenses.clear();
    for (final expense in expenseList) {
      final date = expense.date;
      final amount = expense.amount;
      dailyExpenses.update(date, (value) => (value ?? 0.0) + amount,
          ifAbsent: () => amount);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked;
        _applyFilter(); // Tambahkan pemanggilan filter di sini
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedEndDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        selectedEndDate = picked;
        _applyFilter(); // Tambahkan pemanggilan filter di sini
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<ExpenseEntry> filteredExpenseList = expenseList;

    // Filter daftar pengeluaran berdasarkan tanggal
    if (startDate != null && endDate != null) {
      filteredExpenseList = expenseList.where((expense) {
        final expenseDate = DateTime.parse(expense.date);
        return expenseDate.isAfter(startDate!) &&
            expenseDate.isBefore(endDate!.add(Duration(days: 1)));
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Catat.in',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24, // Ukuran teks yang lebih besar
                fontWeight: FontWeight.bold, // Teks lebih tebal
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _editBalance();
                  },
                ),
                Text(
                  'Rp. ${NumberFormat.decimalPattern().format(walletBalance)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20, // Ukuran teks yang sedikit lebih kecil
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Pengeluaran:',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rp. ${NumberFormat.decimalPattern().format(totalExpenses)}',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: dailyExpenses.length,
                itemBuilder: (context, index) {
                  String date = dailyExpenses.keys.elementAt(index);
                  double totalExpenseOnDate = dailyExpenses[date] ??
                      0.0; // Total pengeluaran pada tanggal ini
                  return Card(
                    elevation: 2.0,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rp. ${NumberFormat.decimalPattern().format(totalExpenseOnDate)}',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...filteredExpenseList
                            .where((e) => e.date == date)
                            .map((e) {
                          return ListTile(
                            title: Text(e.description),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                    'Rp. ${NumberFormat.decimalPattern().format(e.amount)}',
                                    style: TextStyle(
                                      color: e.amount < 0
                                          ? Colors.red
                                          : Colors.green,
                                    )),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    _removeExpense(e);
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: 20.0,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Tambah Pengeluaran'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: categoryController,
                            decoration: InputDecoration(
                              labelText: 'Kategori Pengeluaran',
                              suffixIcon: PopupMenuButton<String>(
                                itemBuilder: (context) {
                                  return <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'Makanan',
                                      child: Text('Makanan'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'Minuman',
                                      child: Text('Minuman'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'Transportasi',
                                      child: Text('Transportasi'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'Lainnya',
                                      child: Text('Lainnya'),
                                    ),
                                  ];
                                },
                                onSelected: (value) {
                                  setState(() {
                                    categoryController.text = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          TextField(
                            controller: dateController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: InputDecoration(
                              labelText: 'Tanggal',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Jumlah Pengeluaran (Rp.)',
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          _addExpense();
                          Navigator.of(context).pop();
                        },
                        child: Text('Simpan'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Batal'),
                      ),
                    ],
                  );
                },
              );
            },
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            child: Icon(Icons.add),
          ),
          SizedBox(height: 16), // Jarak antara FAB tambah dan FAB filter
          FloatingActionButton(
            onPressed: () {
              _showFilterDialog();
            },
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            child: Icon(Icons.filter_list),
          ),
        ],
      ),
    );
  }

  void _removeExpense(ExpenseEntry entry) {
    setState(() {
      walletBalance += entry.amount;
      print("aaaaaaaaaaaaaaaaaaaaaaaa " + walletBalance.toString());
      totalExpenses -= entry.amount;
      expenseList.remove(entry);
      _calculateDailyExpenses();
    });
    _saveData(); // Simpan perubahan data, termasuk saldo yang diperbarui
  }

  void _editBalance() {
    // Check jika walletBalance adalah 0, jika ya, set default value menjadi 0
    if (walletBalance == 0) {
      walletBalanceController.text = "";
    } else {
      walletBalanceController.text = walletBalance.toStringAsFixed(0);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Saldo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: walletBalanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Saldo (Rp.)',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _updateBalance();
                Navigator.of(context).pop();
              },
              child: Text('Simpan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void _updateBalance() {
    double newBalance = double.tryParse(walletBalanceController.text) ?? 0;

    setState(() {
      walletBalance = newBalance;
    });
    _saveData();

    // Simpan saldo yang baru ke SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble('walletBalance', walletBalance);
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Filter Pengeluaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pilih Tanggal Awal:'),
              ElevatedButton(
                onPressed: () {
                  _selectStartDate(context);
                },
                child: Text('Tanggal Awal'),
              ),
              Text('Pilih Tanggal Akhir:'),
              ElevatedButton(
                onPressed: () {
                  _selectEndDate(context);
                },
                child: Text('Tanggal Akhir'),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                // Reset filter di sini
                setState(() {
                  startDate = null;
                  endDate = null;
                });
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.refresh), // Icon reset filter
            ),
            ElevatedButton(
              onPressed: () {
                // Terapkan filter di sini
                Navigator.of(context).pop();
              },
              child: Text('Terapkan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void _applyFilter() {
    if (selectedStartDate != null && selectedEndDate != null) {
      setState(() {
        startDate = selectedStartDate;
        endDate = selectedEndDate;
      });
    }
  }
}

class ExpenseEntry {
  final String description;
  final double amount;
  final String date;

  ExpenseEntry(this.description, this.amount, this.date);

  ExpenseEntry.fromJson(Map<String, dynamic> json)
      : description = json['description'],
        amount = json['amount'],
        date = json['date'];

  Map<String, dynamic> toJson() => {
        'description': description,
        'amount': amount,
        'date': date,
      };
}
