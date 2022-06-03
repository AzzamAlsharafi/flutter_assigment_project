import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

Future<String> getOut(testcase) async {
  Process python = await Process.start('python', ['tasks/histogram/run.py']);

  python.stdin.writeln(testcase);

  return python.stdout.transform(utf8.decoder).first;
}

Future<String> getPath(String from, String to, String out) async {
  // Process.run('javac', ['solutions\\Navigation.java'], runInShell: true);

  Process java = await Process.start('java', ['solutions\\Navigation.java']);

  List<String> split = out.split("\r\n");
  java.stdin.writeln(split.getRange(0, split.length - 3).join("\r\n"));
  java.stdin.writeln(1);
  java.stdin.writeln("$from -> $to");

  java.stderr.transform(utf8.decoder).forEach(print);

  return java.stdout.transform(utf8.decoder).first;
}