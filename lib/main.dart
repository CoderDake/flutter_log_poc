import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './lorem.dart' as lorem;
import 'package:flutter/gestures.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// A builder that includes an Offset to draw the context menu at.
typedef ContextMenuBuilder = Widget Function(
    BuildContext context, Offset offset);

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
  for (var d = 0; d < 200; d++) {
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
Size _textSize(String text, TextStyle style, {double width = double.infinity}) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 0, maxWidth: width);
  return textPainter.size;
}

class _TableExampleState extends State<TableExample> {
  late final ScrollController _verticalController = ScrollController();
  late final ScrollController _horizontalController = ScrollController();
  final Set<int> selections = <int>{};
  double maxWidth = 0.0;
  //TODO: may need to rebuild the table at the current scroll position when we get sections that are longer?
  // We would need to min width to the current screen size

  @override
  void initState() {
    super.initState();
    // On web, disable the browser's context menu since this example uses a custom
    // Flutter-rendered context menu.
    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      BrowserContextMenu.enableContextMenu();
    }
    super.dispose();
  }

  void _showDialog(BuildContext context) {
    Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (BuildContext context) =>
            const AlertDialog(title: Text('You clicked print!')),
      ),
    );
  }

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
              child: _ContextMenuRegion(
                contextMenuBuilder: (context, offset) {
                  // The custom context menu will look like the default context menu
                  // on the current platform with a single 'Print' button.
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: TextSelectionToolbarAnchors(
                      primaryAnchor: offset,
                    ),
                    buttonItems: <ContextMenuButtonItem>[
                      ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          _showDialog(context);
                        },
                        label: 'Copy Selected Rows',
                      ),
                      ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          _showDialog(context);
                        },
                        label: 'Copy Selected Rows with Metadata',
                      ),
                      ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          _showDialog(context);
                        },
                        label: 'Hide items with same Address',
                      ),
                      ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          _showDialog(context);
                        },
                        label: 'Show items with same Address',
                      ),
                    ],
                  );
                },
                child: Scrollbar(
                  controller: _verticalController,
                  child: Scrollbar(
                    controller: _horizontalController,
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
    var isSelected = selections.contains(index);
    var row = widget.items[index];

    Widget rowContents;
    if (row.showMetadata && row.isLastLine) {
      rowContents = ListTile(
        title: Row(
          children: [
            RichText(
                text: TextSpan(
              text: 'Address: ${row.data.address}',
              style: const TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.grey),
            )),
            SizedBox(
              width: 20.0,
            ),
            RichText(
                text: TextSpan(
              text: 'Date: ${row.data.date}',
              style: const TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.grey),
            )),
          ],
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
    final row = widget.items[index];
    Color? color = row.index.isEven ? Colors.purple[100] : null;
    if (selections.contains(index)) {
      color = Colors.blueGrey;
    }
    final TableSpanDecoration decoration = TableSpanDecoration(
      color: color,
    );

    return TableSpan(
      backgroundDecoration: decoration,
      extent: const FixedTableSpanExtent(30),
      recognizerFactories: <Type, GestureRecognizerFactory>{
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (TapGestureRecognizer t) => t.onTap = () {
            setState(() {
              selections.contains(index)
                  ? selections.remove(index)
                  : selections.add(index);
            });
          },
        ),
      },
    );
  }
}

/// Shows and hides the context menu based on user gestures.
///
/// By default, shows the menu on right clicks and long presses.
class _ContextMenuRegion extends StatefulWidget {
  /// Creates an instance of [_ContextMenuRegion].
  const _ContextMenuRegion({
    required this.child,
    required this.contextMenuBuilder,
  });

  /// Builds the context menu.
  final ContextMenuBuilder contextMenuBuilder;

  /// The child widget that will be listened to for gestures.
  final Widget child;

  @override
  State<_ContextMenuRegion> createState() => _ContextMenuRegionState();
}

class _ContextMenuRegionState extends State<_ContextMenuRegion> {
  Offset? _longPressOffset;

  final ContextMenuController _contextMenuController = ContextMenuController();

  static bool get _longPressEnabled {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  void _onSecondaryTapUp(TapUpDetails details) {
    _show(details.globalPosition);
  }

  void _onTap() {
    if (!_contextMenuController.isShown) {
      return;
    }
    _hide();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _longPressOffset = details.globalPosition;
  }

  void _onLongPress() {
    assert(_longPressOffset != null);
    _show(_longPressOffset!);
    _longPressOffset = null;
  }

  void _show(Offset position) {
    _contextMenuController.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return widget.contextMenuBuilder(context, position);
      },
    );
  }

  void _hide() {
    _contextMenuController.remove();
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: _onSecondaryTapUp,
      onTap: _onTap,
      onLongPress: _longPressEnabled ? _onLongPress : null,
      onLongPressStart: _longPressEnabled ? _onLongPressStart : null,
      child: widget.child,
    );
  }
}
