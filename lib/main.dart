// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './lorem.dart' as lorem;

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
  double? height;
  double? offset;
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
  final rows = <LogData>[];
  for (var i = 0; i < loremJson.length; i++) {
    rows.add(LogData(loremJson[i]));
  }
  var data = <LogData>[];
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
  final List<LogData> items;

  /// Creates an instance of the TableView example app.
  const TableExampleApp({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logging Proof of Concept',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: LayoutBuilder(builder: (context, constraints) {
        return TableExample(
          items: items,
          width: constraints.maxWidth - 100.0, // sub padding
        );
      }),
    );
  }
}

/// The class containing the TableView for the sample application.
class TableExample extends StatefulWidget {
  final List<LogData> items;
  final double width;

  /// Creates a screen that demonstrates the TableView widget.
  const TableExample({super.key, required this.items, required this.width});

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
  final Set<int> selections = <int>{};
  final Map<int, double> cachedOffets = {};
  final normalTextStyle = const TextStyle(color: Colors.black, fontSize: 12.0);
  List<LogData> filteredItems = [];
  List<int> searchResults = [];
  String lastSearch = '';
  final metadataTextStyle = const TextStyle(
    color: Colors.grey,
    fontStyle: FontStyle.italic,
    fontSize: 12.0,
  );
  double maxWidth = 0.0;
  //TODO: may need to rebuild the table at the current scroll position when we get sections that are longer?
  // We would need to min width to the current screen size

  @override
  void initState() {
    filteredItems = widget.items;
    unawaited(Future(() => _loadHeights()));
    _loadOffsets();
    // _loadOffsets();
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

  void _showDialog(BuildContext context, String message) {
    Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(title: Text(message)),
      ),
    );
  }

  void _loadHeights() {
    for (var i = 0; i < widget.items.length; i++) {
      _calculateRowHeight(widget.items[i], widget.width);
    }
    print('done loading heights');
  }

  void _loadOffsets() {
    _calculateOffsetForFilteredIndex(filteredItems.length - 1, widget.width);
  }

  @override
  Widget build(BuildContext context) {
    print('tablestatebuild');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logging Proof of Concept'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Filter',
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        filteredItems = widget.items
                            .where((e) => e.about.contains(value))
                            .toList();
                      });
                      cachedOffets.clear();
                      unawaited(Future(() => _loadOffsets()));
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Search',
                      ),
                      onSubmitted: (value) {
                        if (value == lastSearch) {
                          searchResults.add(searchResults.removeAt(0));
                        } else {
                          lastSearch = value;
                          searchResults.clear();
                          for (var i = 0; i < filteredItems.length; i++) {
                            var item = filteredItems[i];
                            if (item.about.contains(value)) {
                              searchResults.add(i);
                            }
                          }
                        }
                        if (searchResults.isNotEmpty) {
                          _jumpToIndex(searchResults[0]);
                        }
                      }),
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
                          _showDialog(context, 'You copied selected rows');
                        },
                        label: 'Copy Selected Rows',
                      ),
                      ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          _showDialog(context,
                              'You copied selected rows with metadata');
                        },
                        label: 'Copy Selected Rows with Metadata',
                      ),
                      ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          _showDialog(
                              context, 'Hiding items with the same address');
                        },
                        label: 'Hide items with same Address',
                      ),
                      ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          _showDialog(
                              context, 'Showing items with the same address');
                        },
                        label: 'Show items with same Address',
                      ),
                    ],
                  );
                },
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _verticalController,
                  child: CustomScrollView(
                    controller: _verticalController,
                    slivers: <Widget>[
                      SliverVariedExtentList.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: _buildRow,
                        itemExtentBuilder: (index, _) => _calculateRowHeight(
                          filteredItems.elementAt(index),
                          widget.width,
                        ),
                      )
                    ],
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

  void _jumpToIndex(int index) {
    var offset = _calculateOffsetForFilteredIndex(index, widget.width);

    _verticalController.animateTo(offset,
        duration: const Duration(milliseconds: 500), curve: Curves.bounceIn);
  }

  Widget? _buildRow(BuildContext contect, int index) {
    var isSelected = selections.contains(index);
    var row = filteredItems.elementAt(index);
    Color? color = index.isEven ? Colors.purple[100] : null;

    if (selections.contains(index)) {
      color = Colors.blueGrey;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selections.contains(index)) {
            selections.remove(index);
          } else {
            selections.add(index);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(color: color),
        child: Column(
          children: [
            Text(
              row.about,
              style: normalTextStyle,
            ),
            Row(
              children: [
                RichText(
                    text: TextSpan(
                  text: 'Address: ${row.address}',
                  style: metadataTextStyle,
                )),
                SizedBox(
                  width: 20.0,
                ),
                RichText(
                    text: TextSpan(
                  text: 'Date: ${row.date.toIso8601String()}',
                  style: metadataTextStyle,
                )),
              ],
            ),
            const Divider(
              height: 10.0,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  var rowCalc = 0;
  double? _calculateRowHeight(LogData data, double width) {
    rowCalc++;
    if (rowCalc % 1000 == 0) {
      print('RowcalcCount: $rowCalc');
    }
    final row = data;
    if (row.height != null) {
      return row.height;
    }

    final row1 = _textSize(row.about, normalTextStyle, width: width);
    final row2 = _textSize(
      'always a single line of text',
      metadataTextStyle,
      width: width,
    );
    final newHeight = row1.height + row2.height + 60.0;
    row.height = newHeight;
    return newHeight;
  }

  double _calculateOffsetForFilteredIndex(int index, double width) {
    if (cachedOffets.containsKey(index)) {
      return cachedOffets[index]!;
    }
    var offset = 0.0;
    for (int i = 0; i < index; i++) {
      var data = filteredItems.elementAt(i);
      offset += _calculateRowHeight(data, width)!;
      cachedOffets[i] = offset;
    }
    return offset;
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
