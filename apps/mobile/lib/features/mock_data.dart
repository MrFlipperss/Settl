import 'package:flutter/material.dart';

/// Demo data ported from the SplitKaro design prototype.
///
/// The screens render from these constants; swap them for live repositories
/// later without touching any widget code.

class Person {
  const Person({
    required this.name,
    required this.amount,
    required this.upi,
    required this.initials,
    required this.color,
  });

  final String name;

  /// Positive: they owe you. Negative: you owe them.
  final int amount;
  final String upi;
  final String initials;
  final Color color;
}

const List<Person> people = [
  Person(
    name: 'Arjun',
    amount: -450,
    upi: 'arjun@oksbi',
    initials: 'AR',
    color: Color(0xFF9B7EBD),
  ),
  Person(
    name: 'Priya',
    amount: 1200,
    upi: 'priya@upi',
    initials: 'PR',
    color: Color(0xFF7C9BBF),
  ),
  Person(
    name: 'Rahul',
    amount: -800,
    upi: 'rahul@okaxis',
    initials: 'RK',
    color: Color(0xFF5BA8A0),
  ),
  Person(
    name: 'Sneha',
    amount: 350,
    upi: 'sneha@ybl',
    initials: 'SM',
    color: Color(0xFFB07DA0),
  ),
  Person(
    name: 'Dev',
    amount: -200,
    upi: 'dev@paytm',
    initials: 'DV',
    color: Color(0xFF6B9E8A),
  ),
  Person(
    name: 'Meera',
    amount: 650,
    upi: 'meera@upi',
    initials: 'MK',
    color: Color(0xFF8E7BB5),
  ),
];

class Category {
  const Category({
    required this.name,
    required this.spent,
    required this.budget,
    required this.color,
    required this.icon,
  });

  final String name;
  final int spent;
  final int budget;
  final Color color;
  final String icon;
}

const List<Category> categories = [
  Category(
    name: 'Food',
    spent: 3840,
    budget: 5000,
    color: Color(0xFFE08060),
    icon: 'food',
  ),
  Category(
    name: 'Travel',
    spent: 2100,
    budget: 3000,
    color: Color(0xFF60A8C8),
    icon: 'travel',
  ),
  Category(
    name: 'Grocery',
    spent: 4200,
    budget: 4000,
    color: Color(0xFF70B870),
    icon: 'grocery',
  ),
  Category(
    name: 'Bills',
    spent: 2800,
    budget: 3500,
    color: Color(0xFF9880CC),
    icon: 'bills',
  ),
  Category(
    name: 'Fun',
    spent: 1340,
    budget: 2000,
    color: Color(0xFFCC8080),
    icon: 'fun',
  ),
];

class Transaction {
  const Transaction({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    required this.icon,
  });

  final String merchant;
  final int amount;
  final String date;
  final String category;
  final String icon;
}

const List<Transaction> transactions = [
  Transaction(
    merchant: 'Swiggy',
    amount: -480,
    date: 'Today',
    category: 'Food',
    icon: 'food',
  ),
  Transaction(
    merchant: 'Ola Cabs',
    amount: -220,
    date: 'Today',
    category: 'Travel',
    icon: 'travel',
  ),
  Transaction(
    merchant: 'Salary',
    amount: 52000,
    date: 'Yesterday',
    category: 'Income',
    icon: 'income',
  ),
  Transaction(
    merchant: 'BigBasket',
    amount: -1340,
    date: 'Yesterday',
    category: 'Grocery',
    icon: 'grocery',
  ),
  Transaction(
    merchant: 'BookMyShow',
    amount: -660,
    date: 'Jul 22',
    category: 'Fun',
    icon: 'fun',
  ),
  Transaction(
    merchant: 'Zepto',
    amount: -195,
    date: 'Jul 20',
    category: 'Grocery',
    icon: 'grocery',
  ),
];

class Group {
  const Group({
    required this.name,
    required this.members,
    required this.balance,
    required this.icon,
  });

  final String name;
  final int members;
  final int balance;
  final String icon;
}

const List<Group> groups = [
  Group(name: 'Goa Trip 2024', members: 5, balance: 1200, icon: 'beach'),
  Group(name: 'Flat Expenses', members: 3, balance: -340, icon: 'home'),
  Group(name: 'Office Lunch', members: 8, balance: 560, icon: 'food'),
  Group(name: 'Wedding Pool', members: 12, balance: 0, icon: 'people'),
];

class Receipt {
  const Receipt({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
  });

  final String merchant;
  final int amount;
  final String date;
  final String category;
}

const List<Receipt> receipts = [
  Receipt(merchant: 'Swiggy', amount: 480, date: 'Jul 30', category: 'Food'),
  Receipt(merchant: 'Ola Cabs', amount: 220, date: 'Jul 28', category: 'Travel'),
  Receipt(
    merchant: 'BigBasket',
    amount: 1340,
    date: 'Jul 26',
    category: 'Groceries',
  ),
  Receipt(
    merchant: 'BookMyShow',
    amount: 660,
    date: 'Jul 22',
    category: 'Entertainment',
  ),
  Receipt(
    merchant: 'Zepto',
    amount: 195,
    date: 'Jul 20',
    category: 'Groceries',
  ),
];

class Ticket {
  const Ticket({
    required this.event,
    required this.date,
    required this.venue,
    required this.status,
  });

  final String event;
  final String date;
  final String venue;
  final String status;
}

const List<Ticket> tickets = [
  Ticket(
    event: 'Coldplay Mumbai',
    date: 'Jan 18, 2025',
    venue: 'DY Patil Stadium',
    status: 'confirmed',
  ),
  Ticket(
    event: 'IPL Final',
    date: 'May 25, 2025',
    venue: 'Narendra Modi Stadium',
    status: 'pending',
  ),
  Ticket(
    event: 'Lollapalooza India',
    date: 'Mar 8, 2025',
    venue: 'Mahalaxmi Racecourse',
    status: 'confirmed',
  ),
];

/// 21x21 matrix rendered as the UPI request QR code.
const List<List<int>> qrCells = [
  [1,1,1,1,1,1,1,0,1,0,1,1,0,0,1,1,1,1,1,1,1],[1,0,0,0,0,0,1,0,0,1,0,0,1,0,1,0,0,0,0,0,1],
  [1,0,1,1,1,0,1,0,1,0,0,1,0,0,1,0,1,1,1,0,1],[1,0,1,1,1,0,1,0,0,1,1,0,0,0,1,0,1,1,1,0,1],
  [1,0,1,1,1,0,1,0,1,1,0,0,1,0,1,0,1,1,1,0,1],[1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1],
  [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],[0,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0,0,0],
  [1,0,1,1,0,1,1,1,0,1,1,0,1,1,0,1,0,1,1,0,1],[0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,1,0,0,1,0],
  [1,0,0,1,0,1,0,1,0,1,1,0,1,0,0,1,0,0,1,0,1],[0,1,1,0,0,0,1,0,1,1,0,0,1,0,1,1,0,1,0,0,0],
  [1,1,0,0,1,1,0,0,0,1,0,1,0,0,0,0,1,0,0,1,1],[0,0,0,0,0,0,0,0,1,0,1,1,0,0,1,0,0,1,0,0,0],
  [1,1,1,1,1,1,1,0,0,1,1,0,0,0,1,0,1,0,1,1,0],[1,0,0,0,0,0,1,0,1,0,0,1,0,0,0,1,0,0,1,0,1],
  [1,0,1,1,1,0,1,0,0,1,1,0,1,0,1,0,1,0,0,1,0],[1,0,1,1,1,0,1,0,1,0,0,1,0,1,0,1,0,1,1,0,0],
  [1,0,1,1,1,0,1,0,0,1,1,0,1,0,1,0,0,0,1,0,1],[1,0,0,0,0,0,1,0,1,1,0,1,0,0,0,1,0,1,0,0,0],
  [1,1,1,1,1,1,1,0,0,0,1,0,1,0,1,0,1,0,1,1,1],
];
