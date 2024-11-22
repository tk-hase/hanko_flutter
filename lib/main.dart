import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const HankoApp());
}

class HankoApp extends StatelessWidget {
  const HankoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ハンコApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'ハンコ'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _hankoColor = Color(0xffed514e);
  static const double _letterSize = 75.0;
  static const double _hankoPaddingTop = _letterSize * 0.15;
  static const double _circleBorderWidth = 6.0;

  String _nameString = "";

  void _updateName(String name) {
    setState(() {
      _nameString = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Expanded(
                child: _nameString.isEmpty ? _promptForInputName() : _hanko(_nameString),
              ),
              const SizedBox(height: 20.0),
              TextField(
                maxLength: 8,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20.0),
                decoration: const InputDecoration(hintText: "名前を入力..."),
                keyboardType: TextInputType.text,
                autofocus: true,
                onChanged: (value) => _updateName(value),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _promptForInputName() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "名前を下に入力してね！",
          style: TextStyle(fontSize: 24),
        ),
        Icon(
          Icons.keyboard_double_arrow_down,
          size: 60,
          color: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  // ハンコ表示部分のWidget
  Widget _hanko(String name) {
    if (name.isNotEmpty) {
      // 1文字の時はぎゅっとした表示になるので、少し余白を作る
      final double decorationCirclePadding;
      if (name.length <= 1) {
        decorationCirclePadding = 20.0;
      } else {
        decorationCirclePadding = 0;
      }

      return Center(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _hankoColor, width: _circleBorderWidth),
          ),
          constraints: BoxConstraints.tightFor(height: (_letterSize + decorationCirclePadding) * min(4, name.length) + _hankoPaddingTop * 1.5),
          alignment: Alignment.center,
          child: _nameVertical(name),
        ),
      );
    } else {
      return const Expanded(
        child: SizedBox(),
      );
    }
  }

  // 名前を縦書きに表示するWidget
  Widget _nameVertical(String name) {
    final firstLineName = name.substring(0, min(name.length, 4));
    final secondLineName = name.length <= 4 ? "" : name.substring(4);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // 全体的に下にずれているので調整
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (secondLineName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _lineNameVertical(secondLineName),
            ),
          _lineNameVertical(firstLineName),
        ],
      ),
    );
  }

  Widget _lineNameVertical(String oneLineName) {
    return Wrap(
      direction: Axis.vertical,
      children: [
        for (var ch in oneLineName.characters) _charactor(ch),
      ],
    );
  }

  // 1文字表示部分
  Widget _charactor(String char) {
    return Text(
      char,
      style: const TextStyle(
        color: _hankoColor,
        fontSize: _letterSize,
        fontFamily: "NotoSerifJP",
        height: 0.92,
      ),
    );
  }
}
