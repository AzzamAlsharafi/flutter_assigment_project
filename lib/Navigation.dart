import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

Future<String> getOut(testcase) async {
  Process python = await Process.start('python', ['tasks/navigation/run.py']);

  python.stdin.writeln(testcase);

  return python.stdout.transform(utf8.decoder).first;
}

Future<String> getPath(String from, String to, String out) async {
  // Process.run('javac', ['solutions\\Navigation.java'], runInShell: true);

  Process java = await Process.start('java', ['solutions/Navigation.java']);

  List<String> split = out.split("\r\n");
  java.stdin.writeln(split.getRange(0, split.length - 3).join("\r\n"));
  java.stdin.writeln(1);
  java.stdin.writeln("$from -> $to");

  // java.stderr.transform(utf8.decoder).forEach(print);

  return java.stdout.transform(utf8.decoder).first;
}

class NavigationWidget extends StatefulWidget {
  NavigationWidget({Key? key}) : super(key: key);

  final List<Graph> graphs = [];

  @override
  State<NavigationWidget> createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends State<NavigationWidget> {
  int selectedGraph = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.graphs.length < 5) {
      getOut(widget.graphs.length).then(
        (value) => setState(
          () {
            widget.graphs.add(Graph(value));
          },
        ),
      );
    }

    return Stack(
      children: [
        widget.graphs.isEmpty ? const Center(child: CircularProgressIndicator()) : InteractiveViewer(
          minScale: 0.5,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(1000),
          child: Scene(
            widget.graphs[selectedGraph], key: ValueKey(widget.graphs.isEmpty? "" : widget.graphs[selectedGraph].out),
          ),
        ),
        SizedBox.expand(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: 
              (widget.graphs.isEmpty ? <Widget>[] : <Widget>[
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: FloatingActionButton.extended(onPressed: () {}, label: const Text("Test cases"), backgroundColor: Colors.blueGrey
                  ,),
                )
              ]) +
              List<Widget>.generate(
                widget.graphs.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
                  child: FloatingActionButton(
                    backgroundColor:
                        selectedGraph == index ? Colors.green : Colors.blue,
                    onPressed: () {
                      setState(() {
                        selectedGraph = index;
                      });
                    },
                    child: Text((index + 1).toString()),
                  ),
                ),
              ) + (widget.graphs.isEmpty ? [] : [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                  child: FloatingActionButton.extended(onPressed: () {
                    showDialog(context: context, builder: 
                      (BuildContext context){
                        return AlertDialog(
                          content: SingleChildScrollView(child: SelectableText(
                            widget.graphs.isEmpty ? "" : widget.graphs[selectedGraph].getOutWithoutExtra(),
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
        ),
      ],
    );
  }
}

class Scene extends StatefulWidget {
  const Scene(this.graph, {Key? key}) : super(key: key);

  final Graph graph;

  @override
  State<Scene> createState() => _SceneState();
}

class _SceneState extends State<Scene> {
  _SceneState();

  String selected = "";
  String secondSelected = "";

  String path = "";
  String previousPathNodes = "";

  @override
  Widget build(BuildContext context) {
    final Map<String, List<double>> positions =
        widget.graph.getPositions(context);

    if (selected.isNotEmpty & secondSelected.isNotEmpty) {
      drawPath();
    } else {
      path = "";
      previousPathNodes = "";
    }

    return Stack(
      children: <Widget>[
        CustomPaint(
          size: const Size(double.maxFinite, double.maxFinite),
          painter: Painter(context, widget.graph, path),
        ),
        ...widget.graph
            .getGraph()
            .keys
            .map((e) => Node(
                e,
                positions[e]!,
                e == selected || e == secondSelected
                    ? 0
                    : (path.contains(" $e ") ? 2 : 1),
                this))
            .toList()
      ],
    );
  }

  void drawPath() async {
    if (previousPathNodes == selected + secondSelected) {
      return;
    }

    String path = await getPath(selected, secondSelected, widget.graph.out);

    previousPathNodes = selected + secondSelected;

    setState(() {
      if (path.contains("Path doesn't exist")) {
        path = "";
        secondSelected = "";
      } else {
        this.path = path;
      }
    });
  }
}

class Painter extends CustomPainter {
  const Painter(this.context, this.graph, this.path);

  final BuildContext context;
  final Graph graph;
  final String path;

  @override
  void paint(Canvas canvas, Size size) {
    graph.getGraph().forEach((key, value) {
      final from = graph.getPositions(context)[key]!;
      value.forEach((e) {
        final to = graph.getPositions(context)[e]!;

        Paint paint = Paint();

        Offset start = Offset(from[0] + 25, from[1] + 25);
        Offset end = Offset(to[0] + 25, to[1] + 25);

        if (path.contains("$key -> $e")) {
          paint.color = Colors.red;
          paint.strokeWidth = 3;
          canvas.drawLine(start, end, paint);
          canvas.drawCircle(
              start - Offset.fromDirection((start - end).direction, 25),
              4,
              paint..color = Colors.blue.shade900);
        } else {
          paint.color = Colors.black;
          paint.strokeWidth = 0.5;
          canvas.drawLine(start, end, paint);
        }
      });
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class Node extends StatelessWidget {
  const Node(this.data, this.position, this.mode, this.state, {Key? key})
      : super(key: key);

  static const size = 50.0;

  final String data;
  final List<double> position;

  // modes: 0 - selected, 1 - normal, 2 - part of path
  final int mode;

  final _SceneState state;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Choose random location on the screen.
      left: position[0],
      top: position[1],
      child: GestureDetector(
        onTap: () {
          state.setState(() {
            if (state.selected == data) {
              state.selected = "";
            } else if (state.secondSelected == data) {
              state.secondSelected = "";
            } else if (state.selected == "") {
              if(state.secondSelected != ""){
                state.selected = state.secondSelected;
                state.secondSelected = data;
              } else {
                state.selected = data;
              }
            } else {
              state.secondSelected = data;
            }
          });
        },
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: [
              Colors.lightGreen.shade300,
              Colors.blueGrey,
              Colors.lightBlue.shade400
            ][mode],
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: [Colors.green, Colors.black, Colors.blue.shade900][mode],
              width: [5.0, 1.0, 2.0][mode],
            ),
          ),
          child: FittedBox(
              child: Text(
            data,
            style: TextStyle(
                color: [
              Colors.grey.shade900,
              Colors.white,
              Colors.white
            ][mode]),
          )),
        ),
      ),
    );
  }
}

class Graph {
  Graph(this.out);

  final String out;

  final Map<String, List<String>> _graph = {};
  final Map<String, List<double>> _positions = {};

  String getOutWithoutExtra(){
    final split = out.split("\r\n");
    return split.getRange(1, split.length - 3).join("\r\n");
  }

  Map<String, List<String>> getGraph() {
    if (_graph.isEmpty) {
      final entries = out.split("\r\n");
      for (final String entry in entries) {
        if (!entry.contains(" => ")) {
          continue;
        }

        final parts = entry.split(" => ");
        final from = parts[0];
        final to = parts[1];

        if (!_graph.containsKey(from)) {
          _graph[from] = [to];
        } else {
          _graph[from]!.add(to);
        }

        if (!_graph.containsKey(to)) {
          _graph[to] = [from];
        } else {
          _graph[to]!.add(from);
        }
      }

      return _graph;
    } else {
      return _graph;
    }
  }

  Map<String, List<double>> getPositions(BuildContext context) {
    if (_positions.isEmpty) {
      final List<double> position = [0, 0];

      final entries = getGraph().keys.toList();

      final rowCount = sqrt(entries.length).toInt();

      for (final entry in entries) {
        // some noise to position
        _positions[entry] = List<double>.from(position);
        _positions[entry]![0] += Random().nextDouble() * 30;
        _positions[entry]![1] += Random().nextDouble() * 30;

        position[0] += 80;

        if (position[0] > rowCount * 80) {
          position[0] = 0;
          position[1] += 80;
        }
      }

      return _positions;
    } else {
      return _positions;
    }
  }
}
