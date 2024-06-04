import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:nfc_card_reader/model/card_data.dart';

class NfcCardReader {
  static const MethodChannel _channel = MethodChannel('com.vgts/nfc_card_reader');
  static const EventChannel _stream = EventChannel('cardDetailsStream');
  late StreamSubscription _streamSubscription;
  CardData? cardData;

  final StreamController<CardData?> _cardDataStreamController = StreamController<CardData?>.broadcast();
  Stream<CardData?> get cardDataStream => _cardDataStreamController.stream;

  Future<void> scanCard() async {
    _streamSubscription = _stream.receiveBroadcastStream().listen(_listenStream);
    try {
      await _channel.invokeMethod('scanCard');
    } on PlatformException {
      throw "Platform Exception";
    }
  }

  void _listenStream(result) {
    debugPrint("Received From Native:  $result\n");
    cardData = CardData(
        result["cardNumber"], result["cardExpiry"], result["cardHolder"]);
    _cardDataStreamController.add(cardData);
  }


  Future<void> stopScanning() async {
    try {
      await _channel.invokeMethod('stopScanCard');
      _streamSubscription.cancel();
    } on PlatformException {
      throw "Platform Exception";
    }
  }
}
