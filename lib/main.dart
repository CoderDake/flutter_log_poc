import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './lorem.dart' as lorem;

class LogData {
  LogData._(this.about, this.address, this.date);

  factory LogData(Map<String, Object> json) {
    return LogData._(
      json['about'] as String,
      json['address'] as String,
      DateTime.parse(json['date'] as String),
    );
  }
  final String about;
  final String address;
  final DateTime date;
}

class LogRow {
  LogRow._({
    required this.data,
    required this.isFirstLine,
    required this.isLastLine,
    required this.showMetadata,
    required this.index,
    required this.line,
  });
  final bool isFirstLine;
  final bool isLastLine;
  final bool showMetadata;
  final LogData data;
  final int index;
  final String line;

  static List<LogRow> generateFrom(LogData data, bool showMetadata, int index) {
    final rows = <LogRow>[];
    final lines = data.about.split('\n');
    lines.removeLast();
    for (var i = 0; i < lines.length; i++) {
      rows.add(LogRow._(
        data: data,
        isFirstLine: i == 0,
        isLastLine: showMetadata ? false : i == lines.length - 1,
        showMetadata: showMetadata,
        index: index,
        line: lines[i],
      ));
    }
    if (showMetadata) {
      rows.add(LogRow._(
          data: data,
          isFirstLine: false,
          isLastLine: true,
          showMetadata: showMetadata,
          index: index,
          line: ''));
    }

    return rows;
  }
}

void main() async {
  var loremJson = lorem.data;

  bool showMetadata = true;
  final rows = <LogRow>[];
  for (var i = 0; i < loremJson.length; i++) {
    rows.addAll(LogRow.generateFrom(
      LogData(loremJson[i]),
      showMetadata,
      i,
    ));
  }
  var data = <LogRow>[];
  for (var d = 0; d < 20; d++) {
    data.addAll(rows);
  }
  runApp(
    MyApp(
      items: data,
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<LogRow> items;

  const MyApp({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    const title = 'Long List';

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(title),
        ),
        body: SelectionArea(
          child: ListView.builder(
            itemCount: items.length,
            prototypeItem: ListTile(
              title: Row(
                children: [
                  Text(''),
                ],
              ),
            ),
            itemBuilder: (context, index) {
              var row = items[index];
              Widget rowContents;
              if (row.showMetadata && row.isLastLine) {
                rowContents = ListTile(
                  title: SelectionContainer.disabled(
                    child: Row(
                      children: [
                        Text('Address: ${row.data.address}'),
                        SizedBox(
                          width: 20.0,
                        ),
                        Text('Date: ${row.data.date}'),
                      ],
                    ),
                  ),
                );
              } else {
                rowContents = Row(
                  children: [
                    Text(
                      row.line,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                );
              }
              return Container(
                color: row.index % 2 == 0 ? Colors.amber : Colors.green,
                child: rowContents,
              );
            },
          ),
        ),
      ),
    );
  }
}
