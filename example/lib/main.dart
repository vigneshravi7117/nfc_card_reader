import 'package:flutter/material.dart';
import 'package:nfc_card_reader/exception/scan_exception.dart';
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
  CardData? _cardData;
  String buttonText = "Start Scanning";
  NfcCardReader? _nfcCardReaderPlugin;
  StreamSubscription? _cardDataSubscription;

  @override
  void initState() {
    super.initState();
  }

  Future<void> scanCard() async {
    setState(() {
      buttonText = "Stop Scanning";
    });

    _nfcCardReaderPlugin ??= NfcCardReader();

    _cardDataSubscription = _nfcCardReaderPlugin!.cardDataStream.listen((cardData) async{
      if (mounted) {
        setState(() {
          _cardData = cardData;
          buttonText = "Start Scanning";
        });
        await _nfcCardReaderPlugin!.stopScanning();
        _cardDataSubscription?.cancel();
      }
    });
    try
    {
      await _nfcCardReaderPlugin!.scanCard();
    }
    on ScanException catch (exception){
      debugPrint(exception.errorMsg);
      await _nfcCardReaderPlugin!.stopScanning();
      _cardDataSubscription?.cancel();
      setState(() {
        buttonText = "Start Scanning";
      });
    }

  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            ElevatedButton(onPressed: (){
              scanCard();
            }, child: Text(buttonText)),
            _cardData != null
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
          ],
        ),
      ),
    );
  }
}
