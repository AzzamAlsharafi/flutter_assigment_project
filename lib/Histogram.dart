import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

Future<String> getOutAndAnswer(testcase) async {
  Process python = await Process.start('python', ['tasks/histogram/run.py']);

  // python.stdin.writeln(testcase);

  final String out = await python.stdout.transform(utf8.decoder).first;

  Process java = await Process.start('java', ['solutions\\Histogram.java']);

  java.stdin.writeln(out);

  final String answer = await java.stdout.transform(utf8.decoder).first;

  return "$out SEPERATOR $answer";
}

class HistogramWidget extends StatefulWidget {
  const HistogramWidget({Key? key}) : super(key: key);

  @override
  State<HistogramWidget> createState() => _HistogramWidgetState();
}

class _HistogramWidgetState extends State<HistogramWidget> {
  List<Histogram> histograms = [];
  int selectedHistogram = 0;

  @override
  Widget build(BuildContext context) {
    if (histograms.length < 10) {
      getOutAndAnswer(histograms.length).then(
        (value) => setState(() {
          print(value);
          histograms.add(Histogram(value));
        }),
      );
    }

    return Container(
      child:
          Text(histograms.isEmpty ? "" : histograms[selectedHistogram].answer),
    );
  }
}

class Histogram {
  Histogram(this.outAndAnswer);

  final String outAndAnswer;

  String get out => outAndAnswer.split("SEPERATOR")[0];
  String get answer => outAndAnswer.split("SEPERATOR")[1];
}
