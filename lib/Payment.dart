import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

String outFile = 'out.txt';

class PaymentWidget extends StatefulWidget {
  const PaymentWidget({Key? key}) : super(key: key);

  @override
  State<PaymentWidget> createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends State<PaymentWidget> {
  Future<void> getOutStream() async {
    Process python = await Process.start('python', ['tasks/payment/run.py']);

    Process.run('javac', ['solutions/Payment.java'], runInShell: true);

    Process java =
        await Process.start('java', ['Payment'], workingDirectory: 'solutions');

    String pythonOut = "";
    String javaOut = "";

    File f = File(outFile);

    if (await f.exists()) {
      await f.delete();
    }

    python.stdout.listen((event) async {
      pythonOut += String.fromCharCodes(event);
      await f.writeAsString(pythonOut, mode: FileMode.append);
      java.stdin.write(pythonOut);
      pythonOut = "";
    }, onDone: () {
      setState(() {
        outReady = true;
      });
    });

    java.stdout.listen((event) async {
      javaOut += String.fromCharCodes(event);
      await f.writeAsString(javaOut, mode: FileMode.append);
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

  File file = File(outFile);

  bool outReady = false;
  bool startedLoading = false;

  int currentTime = -1;

  Map<String, List<String>> queue = {};
  List<String> ready = [];

  void startLoading() async {
    // int previousTime = -1;

    List<String> lines = file.readAsLinesSync();

    currentTime = int.parse(lines[0].split(" ")[0]);

    for (String line in lines) {
      final split = line.split(" ");

      if (split.length == 3) {
        final time = int.parse(split[0]);
        final id = split[1];

        while (currentTime < time) {
          await Future.delayed(const Duration(milliseconds: 1));

          if (mounted) {
            setState(() {
              currentTime += 1;
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
          print("REBOOT");
          if (mounted) {
            setState(() {
              queue.clear();
            });
          }
        }
      } else {
        print("GO 100");
        if (mounted) {
          setState(() {
            ready.clear();
            for (var id in split) {
              queue.remove(id);
              ready.add(id);
            }
          });
        }
      }
    }

    // file
    //     .openRead()
    //     .transform(utf8.decoder)
    //     .transform(const LineSplitter())
    //     .forEach((line) async {
    //   await Future.delayed(Duration(milliseconds: 1000));
    //   print("hello");

    // final split = line.split(" ");

    // if (split.length == 3) {
    //   final time = int.parse(split[0]);
    //   final id = split[1];
    //   final type = split[2];

    //   if (startTime == -1) {
    //     startTime = time;
    //   }

    //   setState(() {
    //     queue.add(line);
    //   });
    // }
    // });
  }

  @override
  Widget build(BuildContext context) {
    // if (!outReady) {
    //    getOutStream();
    // } else {
    outReady = true;
    if (!startedLoading) {
      startedLoading = true;
      startLoading();
    }
    // }

    return outReady
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(getTimeFromMillis(currentTime.toString())),
                    ),
                  ),
                  SizedBox(
                    height: 400,
                    child: Card(
                      elevation: 2.0,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                                  queue.length,
                                  (index) => QueueItemWidget(
                                      queue[queue.keys.elementAt(index)]!))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        : const Center(child: CircularProgressIndicator());
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

  return "${datetime.hour}:${datetime.minute}:${datetime.second}:${datetime.millisecond}";
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
