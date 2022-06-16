import 'dart:io';
import 'dart:typed_data';

import 'package:avdictionary/utilities/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:avdictionary/utilities/word.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:avdictionary/utilities/constaints.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share/share.dart';
import 'package:sqflite/sqflite.dart';
import 'components/custom_button.dart';
import 'components/shared_appbar.dart';

class DefinitionScreen extends StatefulWidget {
  final Word word;
  final Translate translateType;

  DefinitionScreen({required this.word, required this.translateType});

  @override
  _DefinitionScreenState createState() => _DefinitionScreenState();
}

class _DefinitionScreenState extends State<DefinitionScreen> {
  late Future<Html> _html;

  final FlutterTts flutterTts = FlutterTts();
  bool _isFavorite = false;

  //screenshot and share
  final _screenshotController = ScreenshotController();
  late Uint8List _imageFile;

  void _getFavoriteStatus() async {
    Database db = await DatabaseHelper.instance.database;
    String tableName;
    if (widget.translateType == Translate.av) {
      tableName = 'av';
    } else {
      tableName = 'va';
    }

    List<Map> result = await db.rawQuery('''SELECT favorite.id FROM favorite 
        WHERE favorite.id = ${widget.word.id} 
        AND favorite.tb = '$tableName' ''');

    setState(() {
      if (result.isNotEmpty) {
        _isFavorite = true;
      } else {
        _isFavorite = false;
      }
    });
  }

  Future _speak() async {
    if (widget.translateType == Translate.av) {
      await flutterTts.setLanguage('en-US');
    } else if (widget.translateType == Translate.va) {
      await flutterTts.setLanguage('vi-VN');
    }

    await flutterTts.setSpeechRate(0.8);
    await flutterTts.speak(widget.word.word);
  }

  Icon _getFavoriteIconType() {
    IconData iconData;
    Color iconColor;

    if (_isFavorite) {
      iconData = Icons.star_rounded;
    } else {
      iconData = Icons.star_border_rounded;
    }

    if (widget.translateType == Translate.av) {
      iconColor = kEnglishAppbarColor;
    } else {
      iconColor = kVietnameseAppbarColor;
    }

    return Icon(iconData, color: iconColor);
  }

  void _onPressedFavoriteButton() async {
    Database db = await DatabaseHelper.instance.database;
    String tableName;

    if (widget.translateType == Translate.av) {
      tableName = 'av';
    } else {
      tableName = 'va';
    }

    if (!_isFavorite) {
      db.rawQuery(
          '''INSERT INTO favorite (id, word, tb) VALUES (${widget.word.id}, '${widget.word.word}', '$tableName')''');
    } else {
      db.rawQuery(
          '''DELETE FROM favorite WHERE id = ${widget.word.id} AND tb = '$tableName' ''');
    }

    setState(() {
      if (_isFavorite == false) {
        _isFavorite = true;
      } else {
        _isFavorite = false;
      }
    });
  }

  Future<Html> _buildHtml() async {
    // if (widget.word.html.length > 100) {
    //   await Future.delayed(const Duration(milliseconds: 400));
    // }

    // To decrease delay, add color to html by hand instead of use style of Html widget
    String html = widget.word.html;
    StringBuffer temp = StringBuffer();

    for (int i = 0; i < html.length; ++i) {
      temp.write(html[i]);

      if (i >= 2 && i < html.length - 3) {
        if (html[i] == '1' && html[i - 1] == 'h' && html[i - 2] != '/') {
          temp.write('''><span style='color: green;'>''');
          ++i;
        } else if (html[i] == '2' && html[i - 1] == 'h' && html[i - 2] != '/') {
          temp.write('''><span style='color: #1565c0;'>''');
          ++i;
        } else if (html[i] == '3' && html[i - 1] == 'h' && html[i - 2] != '/') {
          temp.write('''><span style='color: red;'>''');
          ++i;
        } else if (html[i + 1] == '<' &&
            html[i + 2] == '/' &&
            html[i + 3] == 'h') {
          temp.write('''</span>''');
        }
      }
    }

    return Html(data: temp.toString());
  }

  @override
  void initState() {
    super.initState();
    _getFavoriteStatus();
    _html =  _buildHtml();
    print(_html);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(size.height * 0.1),
        child: SharedAppBar(
          size: size,
          title: widget.word.word,
          backgroundColor: widget.translateType == Translate.av
              ? kEnglishAppbarColor
              : kVietnameseAppbarColor,
          customButton: CustomButton(
            icon: _getFavoriteIconType(),
            onPressed: () {
              _onPressedFavoriteButton();
            },
          ),
        ),
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: kBackgroundCardColor,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                // Because Html Widget causes lagging when navigate from
                // search screen with long html input
                // So I used FutureBuilder and _buildHtml with some delay to make
                // animation smoother
                child: FutureBuilder(
                  future: _html,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      print('Has data');
                     //  Widget html = Html(data: htmls.toString());
                     return Html(data: widget.word.html);
                    }

                    if (snapshot.hasError) {
                      print(snapshot.error);
                    }

                    return Container(
                      height: size.height * 0.8,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 10,
              child: RawMaterialButton(
                onPressed: () {
                  _speak();
                },
                elevation: 1,
                fillColor: widget.translateType == Translate.av
                    ? kEnglishAppbarColor
                    : kVietnameseAppbarColor,
                child: const Icon(
                  Icons.volume_up,
                  size: 20,
                  color: Colors.white,
                ),
                shape: CircleBorder(),
              ),
            ),
            Positioned(
              top: 80,
              right: 10,
              child: RawMaterialButton(
                onPressed: _takeScreenShot,
                elevation: 1,
                fillColor: widget.translateType == Translate.av
                    ? kEnglishAppbarColor
                    : kVietnameseAppbarColor,
                child: const Icon(
                  Icons.share,
                  size: 20,
                  color: Colors.white,
                ),
                shape: CircleBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _takeScreenShot() async {
    await _screenshotController.capture(delay: const Duration(milliseconds: 10)).then((_imageFile) async {
      if (_imageFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/image.png').create();
        await imagePath.writeAsBytes(_imageFile);

        /// Share Plugin
        await Share.shareFiles([imagePath.path]);
      }
    });


  }
}
