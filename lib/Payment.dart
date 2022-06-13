import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class PaymentWidget extends StatefulWidget {
  const PaymentWidget({Key? key}) : super(key: key);

  @override
  State<PaymentWidget> createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends State<PaymentWidget> {
  Future<void> startRunning() async {
    print("STARTING");
    final startTime = DateTime.now();

    Process python = await Process.start('python', ['tasks/payment/run.py']);

    Process.run('javac', ['solutions/Payment.java'], runInShell: true);

    Process java =
        await Process.start('java', ['Payment'], workingDirectory: 'solutions');

    String pythonOut = "";
    String javaOut = "";

    python.stdout.listen((event) async {
      pythonOut += String.fromCharCodes(event);
      await processPythonOut(pythonOut);
      java.stdin.write(pythonOut);
      pythonOut = "";
    }, onDone: () {
      print("DONE @ ${DateTime.now().difference(startTime).inMilliseconds}ms");
    });

    java.stdout.listen((event) async {
      javaOut += String.fromCharCodes(event);
      processJavaOut(javaOut);
      python.stdin.write(javaOut);
      javaOut = "";
    });

    // print error streams
    python.stderr.listen((event) {
      print(String.fromCharCodes(event));
    });

    java.stderr.listen((event) {
      print(String.fromCharCodes(event));
    });
  }

  Future<void> processPythonOut(String pythonOut) async {
    if (readyBuffer.isNotEmpty) {
      ready.clear();
      setState(() {
        ready.addAll(readyBuffer);
      });
      readyBuffer.clear();
    }

    for (var line in const LineSplitter().convert(pythonOut)) {
      final split = line.split(" ");

      if (split.length == 3) {
        final time = int.parse(split[0]);
        final id = split[1];

        if (currentTime == -1) {
          currentTime = time - 1;
        }

        while (currentTime < time) {
          await Future.delayed(Duration(microseconds: timeDelay));

          if (mounted) {
            setState(() {
              currentTime += timeIncrease;
            });
          }
        }

        if (mounted) {
          setState(() {
            queue[id] = split;
          });
        }
      } else if (split.length == 1) {
        if (line.contains("EXIT")) {
          return;
        } else if (line.contains("REBOOT")) {
          if (mounted) {
            setState(() {
              error = true;
              queue.clear();
              ready.clear();
            });
            await Future.delayed(Duration(milliseconds: 500));
            setState(() {
              error = false;
            });
          }
        }
      } else {
        print("THIS SHOULDN'T HAPPEN");
      }
    }
  }

  void processJavaOut(String javaOut) {
    for (var id in javaOut.split(" ")) {
      if (id.length == 32) {
        readyBuffer.add(id);
      }
    }
  }

  bool startedRunning = false;

  int currentTime = -1;
  int timeDelay = pow(10, 3).toInt(); // delay in microseconds before each timer update
  int timeIncrease =
      0; // amount of time to add to the timer each time it updates, in milliseconds
  int timeIncreaseMemory =
      1; // to store time increase when pausing timer and timeIncrease = 0

  Map<String, List<String>> queue = {};
  List<String> readyBuffer = [];
  List<String> ready = [];

  bool error = false;

  @override
  Widget build(BuildContext context) {
    if (!startedRunning) {
      startedRunning = true;
      startRunning();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClockWidget(currentTime, error, () {
              if (timeIncrease == 0) {
                timeIncrease = timeIncreaseMemory;
              } else {
                timeIncrease = 0;
              }
            }, (value) {
              timeDelay = pow(10, value).toInt();
            }),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 350,
              width: 600,
              child: Card(
                elevation: 2.0,
                child: SingleChildScrollView(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: List.generate(
                            queue.length,
                            (index) => QueueItemWidget(
                                queue[queue.keys.elementAt(index)]!)).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ReadyIdsWidget(ready)
          ],
        ),
      ],
    );
  }
}

class QueueItemWidget extends StatelessWidget {
  const QueueItemWidget(this.splitData, {Key? key}) : super(key: key);

  final List<String> splitData;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 100,
            height: 40,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(20),
                ),
                color: Colors.blueGrey,
              ),
              child: Center(
                child: Text(
                  getTimeFromMillis(
                    splitData[0],
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 300,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(
                  splitData[1],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 100,
            height: 40,
            child: Card(
                color: getColor(splitData[2]),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      splitData[2],
                      style: TextStyle(
                        color: getTextColor(splitData[2]),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )),
          ),
        ),
      ],
    );
  }
}

String getTimeFromMillis(String milli) {
  final datetime = DateTime.fromMillisecondsSinceEpoch(int.parse(milli));

  return "${datetime.hour.toString().padLeft(2, "0")}:${datetime.minute.toString().padLeft(2, "0")}:${datetime.second.toString().padLeft(2, "0")}:${datetime.millisecond.toString().padLeft(3, "0")}";
}

Color getColor(String rank) {
  switch (rank) {
    case "BRONZE":
      return Colors.brown;
    case "SILVER":
      return Colors.grey;
    case "GOLD":
      return Colors.orange;
    case "PLATINUM":
      return Colors.blue;
    default:
      return Colors.white;
  }
}

Color getTextColor(String rank) {
  switch (rank) {
    case "BRONZE":
      return Colors.white;
    case "SILVER":
      return Colors.black;
    case "GOLD":
      return Colors.white;
    case "PLATINUM":
      return Colors.white;
    default:
      return Colors.black;
  }
}

class ReadyIdsWidget extends StatelessWidget {
  const ReadyIdsWidget(this.ready, {Key? key}) : super(key: key);

  final List<String> ready;

  @override
  Widget build(BuildContext context) {
    // build a 10x10 grid of the ready ids.

    return SizedBox(
      width: 800,
      height: 260,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(
            (ready.length / 5).ceil(),
            (index) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                min(5, ready.length - (index * 5)),
                (innerIndex) => Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox(
                    width: 150,
                    height: 10,
                    child: Center(
                      child: Text(
                        ready[index * 5 + innerIndex],
                        style: const TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClockWidget extends StatefulWidget {
  const ClockWidget(this.time, this.error, this.onPress, this.onSlide, {Key? key})
      : super(key: key);

  final int time;
  final bool error;
  final void Function() onPress;
  final void Function(double) onSlide;

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  bool paused = true;
  double sliderValue = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SizedBox(
              width: 30,
              height: 30,
              child: FloatingActionButton(
                onPressed: () {
                  widget.onPress();

                  setState(() {
                    paused = !paused;
                  });
                },
                child: paused
                    ? const Icon(Icons.play_arrow)
                    : const Icon(Icons.pause),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(getTimeFromMillis(widget.time.toString())),
            ),
          ),
          Slider(
              value: sliderValue,
              onChanged: (value) {
                widget.onSlide(value);

                setState(() {
                  sliderValue = value;
                });
              },
              min: 0,
              max: 6),
             Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.error, color: widget.error ? Colors.red : Colors.white),
              )
        ],
      ),
    );
  }
}
