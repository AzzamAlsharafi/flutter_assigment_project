import 'package:flutter/material.dart';
import 'package:flutter_assigment_project/Histogram.dart';
import 'package:flutter_assigment_project/Navigation.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  final NavigationWidget navigation = NavigationWidget();
  final HistogramWidget histogram = HistogramWidget();

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedPage = 2;

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      Container(),
      widget.navigation,
      widget.histogram,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: pages[selectedPage],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Payment"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Navigation"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Histogram"),
        ],
        currentIndex: selectedPage,
        onTap: (selected) {
          setState(() {
            selectedPage = selected;
          });
        },
      ),
    );
  }
}
