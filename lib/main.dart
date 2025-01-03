import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';

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
  static const double _letterSize = 76.0;
  static const double _hankoPaddingTop = _letterSize * 0.15;
  static const double _circleBorderWidth = 6.0;
  static const int _maxCharactersLength = 8;
  static const int _splitedNameLength = 4;
  static const int _lineSpacing = 8;
  static final DateFormat _saveFileDateFormat = DateFormat("yyyyMMddHHmmssSSS");

  final _hankoGlobalKey = GlobalKey();

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
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 60),
          child: Column(
            children: [
              Expanded(
                child: _nameString.isEmpty ? _promptForInputName() : _hanko(_nameString),
              ),
              const SizedBox(height: 20.0),
              TextField(
                maxLength: _maxCharactersLength,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20.0),
                decoration: const InputDecoration(hintText: "名前を入力..."),
                keyboardType: TextInputType.text,
                autofocus: true,
                onChanged: (value) => _updateName(value),
              ),
              FilledButton.icon(
                onPressed: _isValidName(_nameString) ? _saveHankoImage : null,
                icon: const Icon(Icons.download),
                label: const Text(
                  "画像を保存",
                  style: TextStyle(fontSize: 18),
                ),
                style: FilledButton.styleFrom(fixedSize: const Size.fromHeight(50)),
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
      final splitedName = _splitName(name);
      final nameLineLength = max(splitedName[0].length, splitedName[1].length);

      // 1文字の時はぎゅっとした表示になるので、少し余白を作る
      final double decorationCirclePadding;
      if (name.length == 1 || nameLineLength <= 2 && splitedName[1].isNotEmpty) {
        decorationCirclePadding = 20.0;
      } else if (nameLineLength <= _splitedNameLength && splitedName[1].isEmpty) {
        decorationCirclePadding = 0;
      } else {
        decorationCirclePadding = 5;
      }

      return Center(
        child: RepaintBoundary(
          key: _hankoGlobalKey,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _hankoColor, width: _circleBorderWidth),
            ),
            constraints: BoxConstraints.tightFor(height: (_letterSize + decorationCirclePadding) * min(_splitedNameLength, nameLineLength) + _hankoPaddingTop * 1.5),
            alignment: Alignment.center,
            child: _nameVertical(name),
          ),
        ),
      );
    } else {
      return const Expanded(child: SizedBox());
    }
  }

  // 名前を縦書きに表示するWidget
  Widget _nameVertical(String name) {
    final splitedName = _splitName(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // 全体的に下にずれているので調整
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (splitedName[1].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: _lineSpacing / 2),
              child: _lineNameVertical(splitedName[1]),
            ),
          Padding(
            padding: EdgeInsets.only(left: splitedName[1].isEmpty ? 0 : _lineSpacing / 2),
            child: _lineNameVertical(splitedName[0]),
          ),
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

  List<String> _splitName(String name) {
    final String firstName;
    final String secondName;
    if (name.contains(" ") || name.contains("　")) {
      final splitedName = name.contains(" ") ? name.split(" ") : name.split("　");
      firstName = splitedName[0];
      secondName = splitedName[1].substring(0, min(_splitedNameLength, splitedName[1].length));
    } else {
      firstName = name.substring(0, min(name.length, _splitedNameLength));
      secondName = name.length <= _splitedNameLength ? "" : name.substring(_splitedNameLength, min(name.length, _maxCharactersLength));
    }

    return [firstName, secondName];
  }

  Future<void> _saveHankoImage() async {
    // ハンコ部分のRenderObjectを取得
    final RenderRepaintBoundary? repaintBoundary = _hankoGlobalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (repaintBoundary == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("閉じる")),
          ],
          content: const Text("画像生成に失敗しました。"),
        ),
      );
      return;
    }

    // ハンコ部分のWidget→png画像へ変換
    final hankoImage = await repaintBoundary.toImage(pixelRatio: 3);
    final pngHankoData = await hankoImage.toByteData(format: ImageByteFormat.png);
    if (pngHankoData == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("閉じる")),
            ],
            content: const Text("PNGへの変換に失敗しました。"),
          ),
        ),
      );

      return;
    }

    // 写真への権限のチェック
    final isGranted = await Gal.requestAccess();
    if (!isGranted) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
            content: const Text("写真へのアクセスが拒否されているため、保存できませんでした。写真へのアクセス権限を許可してからもう一度「画像を保存」をタップしてください。"),
          ),
        ),
      );
      return;
    }

    // 各OSのアルバム内に保存する
    await Gal.putImageBytes(
      pngHankoData.buffer.asUint8List(),
      name: "hanko_img_${_saveFileDateFormat.format(DateTime.now())}",
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("アルバムに画像を保存しました"),
        duration: Duration(seconds: 3),
      )),
    );
  }

  bool _isValidName(String name) {
    return name.isNotEmpty && name.characters.where((s) => s != ' ' && s != '　').length <= _maxCharactersLength;
  }
}
