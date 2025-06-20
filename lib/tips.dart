import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  _TipsScreenState createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final String apiKey = 'OTJZTK2X8QOC4C99'; // Replace with your API key
  Map<String, double?> prices = {
    'Gold': null,
    'Nifty 50': null,
    'Sensex': null,
  };

  @override
  void initState() {
    super.initState();
    fetchPrices();
    // Timer.periodic(Duration(seconds: 5000), (timer) {
    //   fetchPrices();
    // });
  }

  Future<void> fetchPrices() async {
    final goldPrice = await fetchGoldPrice();
    final niftyPrice = await fetchStockPrice('^NSEI'); // Nifty 50
    final sensexPrice = await fetchStockPrice('^BSESN'); // Sensex

    setState(() {
      prices = {
        'Gold': goldPrice,
        'Nifty 50': niftyPrice,
        'Sensex': sensexPrice,
      };
    });
  }

  Future<double?> fetchGoldPrice() async {
    final url = Uri.parse(
        'https://www.alphavantage.co/query?function=COMMODITY_EXCHANGE_RATE&from_currency=XAU&to_currency=USD&apikey=$apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return double.tryParse(data['5. Exchange Rate']);
    }
    return null;
  }

  Future<double?> fetchStockPrice(String symbol) async {
    final url = Uri.parse(
        'https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=$symbol&interval=5min&apikey=$apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final timeSeries = data['Time Series (5min)'];
      if (timeSeries != null) {
        final latestTime = timeSeries.keys.first;
        return double.tryParse(timeSeries[latestTime]['1. open']);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Investment Tips')),
      body: prices.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: prices.entries.map((entry) {
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    title: Text(
                      entry.key,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      entry.value != null ? '₹${entry.value!.toStringAsFixed(2)}' : 'Loading...',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    leading: Icon(Icons.trending_up, color: Colors.green),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
