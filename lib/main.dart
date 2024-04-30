import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './lorem.dart' as lorem;
import 'package:flutter/gestures.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

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

void main() {
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
  // pass data
  runApp(TableExampleApp(
    items: data,
  ));
}

/// A sample application that utilizes the TableView API.
class TableExampleApp extends StatelessWidget {
  final List<LogRow> items;

  /// Creates an instance of the TableView example app.
  const TableExampleApp({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logging Proof of Concept',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: TableExample(
        items: items,
      ),
    );
  }
}

/// The class containing the TableView for the sample application.
class TableExample extends StatefulWidget {
  final List<LogRow> items;

  /// Creates a screen that demonstrates the TableView widget.
  const TableExample({super.key, required this.items});

  @override
  State<TableExample> createState() => _TableExampleState();
}

// Here it is!
Size _textSize(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 0, maxWidth: double.infinity);
  return textPainter.size;
}

class _TableExampleState extends State<TableExample> {
  late final ScrollController _verticalController = ScrollController();
  late final ScrollController _horizontalController = ScrollController();
  double maxWidth = 0.0;
  //TODO: may need to rebuild the table at the current scroll position when we get sections that are longer?
  // We would need to min width to the current screen size
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 16,
        );
    widget.items.forEach(
      (element) {
        final size = _textSize(element.line, style!);
        maxWidth = max(maxWidth, size.width);
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logging Proof of Concept'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Filter',
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Search',
                    ),
                  ),
                )
              ],
            ),
            Expanded(
              child: Scrollbar(
                controller: _verticalController,
                child: Scrollbar(
                  controller: _horizontalController,
                  child: SelectionArea(
                    contextMenuBuilder: (context, selectableRegionState) {
                      final List<ContextMenuButtonItem> buttonItems =
                          selectableRegionState.contextMenuButtonItems;
                      buttonItems.insert(
                        0,
                        ContextMenuButtonItem(
                          label: 'Copy Logs',
                          onPressed: () {},
                        ),
                      );
                      buttonItems.insert(
                        0,
                        ContextMenuButtonItem(
                          label: 'Copy Logs with Metadata',
                          onPressed: () {},
                        ),
                      );
                      buttonItems.insert(
                        0,
                        ContextMenuButtonItem(
                          label: 'Copy Address',
                          onPressed: () {},
                        ),
                      );
                      buttonItems.insert(
                        0,
                        ContextMenuButtonItem(
                          label: 'Copy Date',
                          onPressed: () {},
                        ),
                      );

                      return AdaptiveTextSelectionToolbar.buttonItems(
                        anchors: selectableRegionState.contextMenuAnchors,
                        buttonItems: buttonItems,
                      );
                    },
                    child: TableView.builder(
                      verticalDetails: ScrollableDetails.vertical(
                          controller: _verticalController),
                      horizontalDetails: ScrollableDetails.horizontal(
                          controller: _horizontalController),
                      cellBuilder: _buildCell,
                      columnCount: 1,
                      columnBuilder: _buildColumnSpan,
                      rowCount: widget.items.length,
                      rowBuilder: _buildRowSpan,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      persistentFooterButtons: <Widget>[
        TextButton(
          onPressed: () {
            _verticalController.jumpTo(0);
          },
          child: const Text('Jump to Top'),
        ),
        TextButton(
          onPressed: () {
            _verticalController
                .jumpTo(_verticalController.position.maxScrollExtent);
          },
          child: const Text('Jump to Bottom'),
        ),
      ],
    );
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    var index = vicinity.row;
    var row = widget.items[index];
    Widget rowContents;
    if (row.showMetadata && row.isLastLine) {
      rowContents = ListTile(
        title: SelectionContainer.disabled(
          child: Row(
            children: [
              RichText(
                  text: TextSpan(
                text: 'Address: ${row.data.address}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              )),
              SizedBox(
                width: 20.0,
              ),
              RichText(
                  text: TextSpan(
                text: 'Date: ${row.data.date}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              )),
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
    return TableViewCell(
      child: rowContents,
    );
  }

  TableSpan _buildColumnSpan(int index) {
    const TableSpanDecoration decoration = TableSpanDecoration(
      border: TableSpanBorder(
        trailing: BorderSide(),
      ),
    );

    return TableSpan(
      foregroundDecoration: decoration,
      extent: FixedTableSpanExtent(maxWidth),
      onEnter: (_) => print('Entered column $index'),
      recognizerFactories: <Type, GestureRecognizerFactory>{
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (TapGestureRecognizer t) =>
              t.onTap = () => print('Tap column $index'),
        ),
      },
    );
  }

  TableSpan _buildRowSpan(int index) {
    final TableSpanDecoration decoration = TableSpanDecoration(
      color: widget.items[index].index.isEven ? Colors.purple[100] : null,
    );

    return TableSpan(
      backgroundDecoration: decoration,
      extent: const FixedTableSpanExtent(30),
      recognizerFactories: <Type, GestureRecognizerFactory>{
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (TapGestureRecognizer t) => t.onTap = () => print('Tap row $index'),
        ),
      },
    );
  }
}
