import 'package:flutter/material.dart';
import 'dart:async';

import 'package:nfc_card_reader/model/card_data.dart';
import 'package:nfc_card_reader/nfc_card_reader.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _nfcCardReaderPlugin = NfcCardReader();
  CardData? _cardData;

  @override
  void initState() {
    super.initState();
    scanCard();
  }

  Future<void> scanCard() async {
    CardData? cardData;
    try {
      cardData = await _nfcCardReaderPlugin.scanCard();
    } catch (e) {
      debugPrint(e.toString());
    }

    if (!mounted) return;

    setState(() {
      _cardData = cardData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: _cardData != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Card Number : ${_cardData!.cardNumber}\n'),
                    Text('Card Expiry : ${_cardData!.cardExpiry}\n'),
                    Text('Card Holder Name : ${_cardData!.cardHolderName}\n')
                  ],
                ),
              )
            : const Center(
                child: Text('No card data available\n'),
              ),
      ),
    );
  }
}
