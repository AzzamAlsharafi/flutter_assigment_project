import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

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
          histograms.add(Histogram(value));
        }),
      );
    }

    return Stack(
      children: [InteractiveViewer(
        minScale: 0.5,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(1000),
        child: Chart(
            histograms.isEmpty ? Histogram("") : histograms[selectedHistogram]),
      ),
      SizedBox.expand(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: 
              (histograms.isEmpty ? <Widget>[] : <Widget>[
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: FloatingActionButton.extended(onPressed: () {}, label: const Text("Test cases"), backgroundColor: Colors.blueGrey
                  ,),
                )
              ]) +
              List<Widget>.generate(
                histograms.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40.0),
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor:
                        selectedHistogram == index ? Colors.green : Colors.blue,
                    onPressed: () {
                      setState(() {
                        selectedHistogram = index;
                      });
                    },
                    child: Text((index + 1).toString()),
                  ),
                ),
              ) + (histograms.isEmpty ? [] : [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                  child: FloatingActionButton.extended(onPressed: () {
                    showDialog(context: context, builder: 
                      (BuildContext context){
                        return AlertDialog(
                          content: SingleChildScrollView(child: SelectableText(
                            histograms.isEmpty ? "" : histograms[selectedHistogram].out,
                            style: const TextStyle(fontFamily: ''),
                          ),),
                        );
                      }
                    );
                  }, label: const Text("Input"), backgroundColor: Colors.blueGrey
                  ,),
                )
              ]),
            ),
        ),],
      
    );
  }
}

class Chart extends StatelessWidget {
  const Chart(this.histogram, {Key? key}) : super(key: key);

  final Histogram histogram;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
          size: const Size(double.maxFinite, double.maxFinite),
          painter: Painter(histogram.answer)),
    );
  }
}

class Painter extends CustomPainter {
  const Painter(this.answer);

  final String answer;

  @override
  void paint(Canvas canvas, Size size) {
    if (answer.isEmpty) {
      return;
    }

    final split = answer.split("\r\n");
    final cutoffs = split[0].split(" ").map((e) => int.parse(e)).toList();
    final bars = split[1].split(" ").map((e) => double.parse(e)).toList();

    Offset corner = Offset(500, 500);

    Offset yAxis = Offset(0, -400);
    Offset xAxis = Offset(500, 0);

    Offset yTickSize = Offset(-10, 0);
    Offset yTickDistance = Offset(0, -40);
    Offset yTextOffset = Offset(-40, -10);
    List<double> yTicks = List.generate(11, (index) => index * 100);

    Offset firstBarOffset = Offset(10, 0);
    Offset barWidth = (xAxis - (firstBarOffset * 2.0)) / bars.length.toDouble();

    double borderWidth = 1;
    Offset borderOffset = Offset(borderWidth, -borderWidth);
    Offset xTickSize = Offset(0, 10);
    Offset xTextYOffset = Offset(0, 10);
    Offset xTextXOffsetPerLetter = Offset(-3, 0);

    Paint paint = Paint();

    canvas.drawLine(corner, corner + yAxis, paint);
    canvas.drawLine(corner, corner + xAxis, paint);

    // draw y ticks
    for (int i = 0; i < yTicks.length; i++) {
      Offset tick = corner + yTickSize + (yTickDistance * i.toDouble());
      canvas.drawLine(tick, tick - yTickSize, paint);

      TextPainter(
        text: TextSpan(
          text: yTicks[i].toString(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: 0, maxWidth: size.width)
        ..paint(canvas, tick + yTextOffset);
    }

    // draw histogram bars
    for (int i = 0; i < bars.length; i++) {
      double height = bars[i] / yTicks[1];
      Offset start = corner + firstBarOffset + (barWidth * i.toDouble());
      Offset end = start + barWidth + (yTickDistance * height);

      Rect borderRect = Rect.fromPoints(start, end);
      Rect innerRect =
          Rect.fromPoints(start + borderOffset, end - borderOffset);

      canvas.drawRect(borderRect, paint..color = Colors.black);

      canvas.drawLine(start, start + xTickSize, paint);

      canvas.drawRect(innerRect, paint..color = Colors.red);

      TextPainter(
        text: TextSpan(
          text: cutoffs[i].toString(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: 0, maxWidth: size.width)
        ..paint(canvas, start + xTextYOffset + xTextXOffsetPerLetter * cutoffs[i].toString().length.toDouble());
    }

    // draw last cutoff tick
    Offset start = corner + Offset(10, 0) + (barWidth * bars.length.toDouble());
    canvas.drawLine(start, start + xTickSize, paint..color = Colors.black);
    TextPainter(
        text: TextSpan(
          text: cutoffs.last.toString(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: 0, maxWidth: size.width)
        ..paint(canvas, start + xTextYOffset + xTextXOffsetPerLetter * cutoffs.last.toString().length.toDouble());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class Histogram {
  Histogram(this.outAndAnswer);

  final String outAndAnswer;

  String get out => outAndAnswer.split(" SEPERATOR ").first;
  String get answer => outAndAnswer.split(" SEPERATOR ").last;
}
