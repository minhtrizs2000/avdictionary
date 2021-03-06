import 'package:flutter/material.dart';
import 'package:avdictionary/utilities/constaints.dart';

class WordCard extends StatelessWidget {
  const WordCard({
    required this.items,
    required this.index,
    required this.onPressed,
    required this.table,
  });

  final List items;
  final int index;
  final Function()? onPressed;
  final String table;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: table == 'av'
                ? [Colors.cyan, Colors.white]
                : [Colors.red, Colors.white],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: table == 'av'
                  ? Colors.blue.withOpacity(0.4)
                  : Colors.red.withOpacity(0.4),
              blurRadius: 5,
              spreadRadius: 1,
              offset: Offset(2, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Image.asset(
              table == 'av' ? kEnglishFlagDir : kVietNamFlagDir,
              width: 25,
              height: 25,
            ),
            const SizedBox(
              width: 20.0,
            ),
            Text(
              '${items[index].word}',
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
