import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as Math;

void main() {
  runApp(MyMoneyTrackerApp());
}

class MyMoneyTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Money Tracker',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: MoneyTrackerHomePage(),
    );
  }
}

class MoneyTrackerHomePage extends StatefulWidget {
  @override
  _MoneyTrackerHomePageState createState() => _MoneyTrackerHomePageState();
}

class _MoneyTrackerHomePageState extends State<MoneyTrackerHomePage> {
  List<Expense> expenses = [];
  List<MoneyOwed> moneyOwedBy = [];
  List<MoneyOwed> moneyOwedTo = [];
  TextEditingController _titleController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  String _selectedCategory = 'Grocery'; // Default category
  DateTime _selectedDate = DateTime.now(); // Default date
  late SharedPreferences _prefs; // Change to non-nullable
  final List<String> _categories = [
    'Grocery',
    'Rent',
    'Travel',
    'Fees',
    'Dine Out',
    'College Expenses',
    'Recharge',
    'Miscellaneous',
  ];

  @override
  void initState() {
    super.initState();
    _initSharedPreferences(); // Initialize SharedPreferences
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadExpenses(); // Load expenses after SharedPreferences is initialized
    _loadMoneyOwed(); // Load money owed after SharedPreferences is initialized
  }

  Future<void> _loadExpenses() async {
    List<String>? expenseStrings = _prefs.getStringList('expenses');
    if (expenseStrings != null) {
      setState(() {
        expenses = expenseStrings.map((e) => Expense.fromString(e)).toList();
      });
    }
  }

  Future<void> _loadMoneyOwed() async {
    List<String>? moneyOwedByStrings = _prefs.getStringList('moneyOwedBy');
    List<String>? moneyOwedToStrings = _prefs.getStringList('moneyOwedTo');
    if (moneyOwedByStrings != null && moneyOwedToStrings != null) {
      setState(() {
        moneyOwedBy = moneyOwedByStrings.map((e) => MoneyOwed.fromString(e)).toList();
        moneyOwedTo = moneyOwedToStrings.map((e) => MoneyOwed.fromString(e)).toList();
      });
    }
  }

  Future<void> _saveExpenses() async {
    List<String> expenseStrings = expenses.map((e) => e.toString()).toList();
    await _prefs.setStringList('expenses', expenseStrings);
  }

  Future<void> _saveMoneyOwed() async {
    List<String> moneyOwedByStrings = moneyOwedBy.map((e) => e.toString()).toList();
    List<String> moneyOwedToStrings = moneyOwedTo.map((e) => e.toString()).toList();
    await _prefs.setStringList('moneyOwedBy', moneyOwedByStrings);
    await _prefs.setStringList('moneyOwedTo', moneyOwedToStrings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Money Tracker'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MoneyOwedPage(
                      title: 'Owed By',
                      moneyOwed: moneyOwedBy,
                      onAddMoneyOwed: _addMoneyOwedBy,
                    ),
                  ),
                );
              },
              child: Text('Owed By'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MoneyOwedPage(
                      title: 'Owed To',
                      moneyOwed: moneyOwedTo,
                      onAddMoneyOwed: _addMoneyOwedTo,
                    ),
                  ),
                );
              },
              child: Text('Owed To'),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expenses',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '₹${_calculateTotalExpenses().toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 24, color: Colors.green),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.pie_chart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PieChartPage(expenses: expenses),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Expenses List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      title: Text(expenses[index].title),
                      subtitle: Text(
                          '₹${expenses[index].amount.toStringAsFixed(2)} | ${expenses[index].category} | ${_formatDate(expenses[index].date)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editExpense(index);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _removeExpense(index);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showAddExpenseDialog(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 5),
                  Text('Add Expense'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalExpenses() {
    double total = 0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  double _calculateTotalOwedBy() {
    double total = 0;
    for (var moneyOwed in moneyOwedBy) {
      total += moneyOwed.amount;
    }
    return total;
  }

  double _calculateTotalOwedTo() {
    double total = 0;
    for (var moneyOwed in moneyOwedTo) {
      total += moneyOwed.amount;
    }
    return total;
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Expense Title'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount (₹)'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Category'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text('Select Date: ${_formatDate(_selectedDate)}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addExpense();
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _addExpense() {
    String title = _titleController.text.trim();
    double amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (title.isNotEmpty && amount > 0) {
      setState(() {
        expenses.add(Expense(
          title: title,
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
        ));
        _titleController.clear();
        _amountController.clear();
        _selectedCategory = 'Grocery'; // Reset selected category to default
        _selectedDate = DateTime.now(); // Reset selected date to today
      });
      _saveExpenses();
    } else {
      _showErrorDialog(context, 'Invalid Input', 'Please enter a valid title and amount.');
    }
  }

  void _removeExpense(int index) {
    setState(() {
      expenses.removeAt(index);
      _saveExpenses();
    });
  }

  void _editExpense(int index) {
    setState(() {
      Expense expense = expenses[index];
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toString();
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
    });
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Expense Title'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount (₹)'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Category'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text('Select Date: ${_formatDate(_selectedDate)}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateExpense(index);
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _updateExpense(int index) {
    String title = _titleController.text.trim();
    double amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (title.isNotEmpty && amount > 0) {
      setState(() {
        expenses[index] = Expense(
          title: title,
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
        );
        _titleController.clear();
        _amountController.clear();
        _selectedCategory = 'Grocery'; // Reset selected category to default
        _selectedDate = DateTime.now(); // Reset selected date to today
      });
      _saveExpenses();
    } else {
      _showErrorDialog(context, 'Invalid Input', 'Please enter a valid title and amount.');
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addMoneyOwedBy(String name, double amount, DateTime date) {
    setState(() {
      moneyOwedBy.add(MoneyOwed(name: name, amount: amount, date: date));
      _saveMoneyOwed();
    });
  }

  void _addMoneyOwedTo(String name, double amount, DateTime date) {
    setState(() {
      moneyOwedTo.add(MoneyOwed(name: name, amount: amount, date: date));
      _saveMoneyOwed();
    });
  }
}

class Expense {
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  factory Expense.fromString(String expenseString) {
    List<String> parts = expenseString.split('|');
    return Expense(
      title: parts[0],
      amount: double.parse(parts[1]),
      category: parts[2],
      date: DateTime.parse(parts[3]),
    );
  }

  @override
  String toString() {
    return '$title|${amount.toString()}|$category|${date.toString()}';
  }
}

class MoneyOwed {
  final String name;
  final double amount;
  final DateTime date;

  MoneyOwed({
    required this.name,
    required this.amount,
    required this.date,
  });

  factory MoneyOwed.fromString(String moneyOwedString) {
    List<String> parts = moneyOwedString.split('|');
    return MoneyOwed(
      name: parts[0],
      amount: double.parse(parts[1]),
      date: DateTime.parse(parts[2]),
    );
  }

  @override
  String toString() {
    return '$name|${amount.toString()}|${date.toString()}';
  }
}

class MoneyOwedPage extends StatefulWidget {
  final String title;
  final List<MoneyOwed> moneyOwed;
  final Function(String, double, DateTime) onAddMoneyOwed;

  const MoneyOwedPage({
    Key? key,
    required this.title,
    required this.moneyOwed,
    required this.onAddMoneyOwed,
  }) : super(key: key);

  @override
  _MoneyOwedPageState createState() => _MoneyOwedPageState();
}

class _MoneyOwedPageState extends State<MoneyOwedPage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () => _selectDate(context),
              child: Text('Select Date: ${_formatDate(_selectedDate)}'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _addMoneyOwed();
              },
              child: Text('Add Money Owed'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: widget.moneyOwed.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      title: Text(widget.moneyOwed[index].name),
                      subtitle: Text(
                          '₹${widget.moneyOwed[index].amount.toStringAsFixed(2)} | ${_formatDate(widget.moneyOwed[index].date)}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _removeMoneyOwed(index);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _addMoneyOwed() {
    String name = _nameController.text.trim();
    double amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (name.isNotEmpty && amount > 0) {
      widget.onAddMoneyOwed(name, amount, _selectedDate);
      _nameController.clear();
      _amountController.clear();
      setState(() {
        _selectedDate = DateTime.now(); // Reset selected date to today
      });
    } else {
      _showErrorDialog(context, 'Invalid Input', 'Please enter a valid name and amount.');
    }
  }

  void _removeMoneyOwed(int index) {
    setState(() {
      widget.moneyOwed.removeAt(index);
      _saveMoneyOwed();
    });
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _saveMoneyOwed() {
    List<String> moneyOwedStrings = widget.moneyOwed.map((e) => e.toString()).toList();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('moneyOwedBy', moneyOwedStrings);
      prefs.setStringList('moneyOwedTo', moneyOwedStrings);
    });
  }
}



class PieChartPage extends StatelessWidget {
  final List<Expense> expenses;

  const PieChartPage({Key? key, required this.expenses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Categories'),
        centerTitle: true,
      ),
      body: Center(
        child: PieChart(
          PieChartData(
            sections: _generatePieChartSections(expenses),
            borderData: FlBorderData(show: false),
            sectionsSpace: 0,
            centerSpaceRadius: 80,
            centerSpaceColor: Colors.white,
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(List<Expense> expenses) {
    List<String> categories = [];
    Map<String, double> categoryAmounts = {};

    expenses.forEach((expense) {
      if (!categories.contains(expense.category)) {
        categories.add(expense.category);
        categoryAmounts[expense.category] = expense.amount;
      } else {
        categoryAmounts[expense.category] = (categoryAmounts[expense.category] ?? 0) + expense.amount;
      }
    });

    List<PieChartSectionData> sections = [];

    // Generate colors
    List<Color> colors = _generateColors(categories.length);

    categoryAmounts.forEach((category, amount) {
      final double radius = 70;
      final double totalAmount = _calculateTotalAmount(categoryAmounts.values.toList());
      final double percentage = (amount / totalAmount) * 100;
      sections.add(
        PieChartSectionData(
          color: colors.removeAt(0),
          value: amount,
          title: '$category\n${percentage.toStringAsFixed(2)}%',
          radius: radius,
          titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    });

    return sections;
  }

  // Function to generate colors with better selection
  List<Color> _generateColors(int count) {
    List<Color> colors = [];
    for (int i = 0; i < count; i++) {
      colors.add(_randomColor());
    }
    return colors;
  }

  // Function to calculate total amount
  double _calculateTotalAmount(List<double> amounts) {
    double total = 0;
    amounts.forEach((amount) {
      total += amount;
    });
    return total;
  }

  // Function to generate random color
  Color _randomColor() {
    return Color((Math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }
}
