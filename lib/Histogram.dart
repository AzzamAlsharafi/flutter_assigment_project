import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

Future<void> getOutAndAnswer(testcase, _HistogramWidgetState state) async {
  Process python = await Process.start('python', ['tasks/histogram/run.py']);

  Process java = await Process.start('java', ['solutions/Histogram.java']);

  String result = "";

  String out = "";
  String answer = "";

  python.stdout.listen(
    (event) {
      out = String.fromCharCodes(event);

      java.stdin.write(out);

      result += out;
    },
    onDone: () {
      state.setState(() {
        state.widget.histograms.addAll(Histogram.getHistos(result));
      });
    },
  );

  java.stdout.listen((event) {
    answer = String.fromCharCodes(event);

    python.stdin.write(answer);
    result += " SEPERATOR $answer BIGSEPERATING ";
  });

  // print python error
  python.stderr.listen((event) {
    print("python error");
    print(String.fromCharCodes(event));
  });

  // print java error
  java.stderr.listen((event) {
    print("java error");
    print(String.fromCharCodes(event));
  });

  // final String out = await python.stdout.transform(utf8.decoder).first;

  // java.stdin.writeln(out);

  // final String answer = await java.stdout.transform(utf8.decoder).first;

  // python.stdin.writeln(answer);

  // result += "$out SEPERATOR $answer";
  // if(i < testcase - 2){
  //   result += " MEGASEPERATING ";
  // }
}

class HistogramWidget extends StatefulWidget {
  HistogramWidget({Key? key}) : super(key: key);

  final List<Histogram> histograms = [];

  @override
  State<HistogramWidget> createState() => _HistogramWidgetState();
}

class _HistogramWidgetState extends State<HistogramWidget> {
  int selectedHistogram = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.histograms.isEmpty) {
      getOutAndAnswer(10, this);
    }

    return Stack(
      children: [
        InteractiveViewer(
          minScale: 0.5,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(1000),
          child: Chart(
            widget.histograms.isEmpty
                ? Histogram("")
                : widget.histograms[selectedHistogram],
            key: ValueKey(widget.histograms.isEmpty
                ? ""
                : widget.histograms[selectedHistogram].outAndAnswer),
          ),
        ),
        SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: (widget.histograms.isEmpty
                    ? <Widget>[]
                    : <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: FloatingActionButton.extended(
                            onPressed: () {},
                            label: const Text("Test cases"),
                            backgroundColor: Colors.blueGrey,
                          ),
                        )
                      ]) +
                [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: List.generate(
                        2,
                        (outerIndex) => Column(
                              children: List<Widget>.generate(
                                widget.histograms.length ~/ 2,
                                (index) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 10.0),
                                  child: FloatingActionButton(
                                    mini: true,
                                    backgroundColor: selectedHistogram ==
                                            index + (index + outerIndex)
                                        ? Colors.green
                                        : Colors.blue,
                                    onPressed: () {
                                      setState(() {
                                        selectedHistogram =
                                            index + (index + outerIndex);
                                      });
                                    },
                                    child: Text(
                                        (index + (index + outerIndex) + 1)
                                            .toString()),
                                  ),
                                ),
                              ),
                            )),
                  )
                ] +
                (widget.histograms.isEmpty
                    ? []
                    : [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 20.0),
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: SingleChildScrollView(
                                      child: SelectableText(
                                        widget.histograms.isEmpty
                                            ? ""
                                            : widget
                                                .histograms[selectedHistogram]
                                                .outWithoutExtra,
                                        style: const TextStyle(fontFamily: ''),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            label: const Text("Input"),
                            backgroundColor: Colors.blueGrey,
                          ),
                        )
                      ]),
          ),
        ),
      ],
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

    Offset corner = Offset(100, 500);

    Offset yAxis = Offset(0, -400);
    Offset xAxis = Offset(1000, 0);

    Offset yTickSize = Offset(-10, 0);
    Offset yTickDistance = Offset(0, -40);
    Offset yTextOffset = Offset(-40, -10);

    double greatest = max(bars.reduce(max), 1000);
    greatest = ((greatest ~/ 1000) + (greatest % 1000 > 0 ? 1 : 0)) * 1000.0;

    List<double> yTicks = List.generate(11, (index) => index * (greatest / 10));

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

      canvas.save();

      Offset textStart;
      if (barWidth.dx < 50) {
        textStart = Offset(corner.dy, -corner.dx) +
            Offset(30, - (20 - barWidth.dx) -(firstBarOffset + (barWidth * (i + 1).toDouble())).dx);
        canvas.rotate(90 * pi / 180);
      } else {
        textStart = start;
      }
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
        ..paint(
            canvas,
            textStart +
                xTextYOffset +
                xTextXOffsetPerLetter *
                    cutoffs[i].toString().length.toDouble());

      canvas.restore();
    }

    // draw last cutoff tick

    Offset start = corner + Offset(10, 0) + (barWidth * bars.length.toDouble());
    canvas.drawLine(start, start + xTickSize, paint..color = Colors.black);

    Offset textStart;

    canvas.save();

    if (barWidth.dx < 50) {
      textStart = Offset(corner.dy, -corner.dx) +
          Offset(30,  - (20 - barWidth.dx) 
              -(firstBarOffset + (barWidth * (bars.length + 1).toDouble())).dx);
      canvas.rotate(90 * pi / 180);
    } else {
      textStart = corner + Offset(10, 0) + (barWidth * bars.length.toDouble());
    }

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
      ..paint(
          canvas,
          textStart +
              xTextYOffset +
              xTextXOffsetPerLetter *
                  cutoffs.last.toString().length.toDouble());

    canvas.restore();
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
  String get outWithoutExtra =>
      out.split("\r\n").getRange(1, out.split("\r\n").length - 1).join("\r\n");
  String get answer => outAndAnswer.split(" SEPERATOR ").last;

  static List<Histogram> getHistos(String data) {
    final split = data.split(" BIGSEPERATING ");
    return List.generate(split.length - 1, (index) => Histogram(split[index]));
  }
}
