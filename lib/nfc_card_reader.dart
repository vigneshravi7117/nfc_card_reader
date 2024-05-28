import 'package:flutter/services.dart';
import 'package:nfc_card_reader/model/card_data.dart';

class NfcCardReader {
  static const MethodChannel _channel =
      MethodChannel('com.vgts/nfc_card_reader');

  Future<CardData?> scanCard() async {
    CardData? cardData;
    try {
      final Map result = await _channel.invokeMethod('scanCard');
      cardData = CardData(
          result["cardNumber"], result["cardExpiry"], result["cardHolder"]);
    } on PlatformException {
      throw "Platform Exception";
    }
    return cardData;
  }


  Future<void> stopScanning() async {
    try {
      await _channel.invokeMethod('stopScanCard');
    } on PlatformException {
      throw "Platform Exception";
    }
  }
}
