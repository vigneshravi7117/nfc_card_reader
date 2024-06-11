import Flutter
import UIKit
import CoreNFC
import Foundation

func prettyPrintCardNumber(_ cardNumber: String) -> String {
    return cardNumber
}

public class NfcCardReaderPlugin: NSObject, FlutterPlugin{

    private var eventSink: FlutterEventSink?

    var cardMap: [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let cardExpiryString = dateFormatter.string(from: Date())

        return [
            "cardNumber": prettyPrintCardNumber("1234567890123456"),
            "cardExpiry": cardExpiryString,
            "cardHolder": "Doe"
        ]
    }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.vgts/nfc_card_reader", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "cardDetailsStream", binaryMessenger: registrar.messenger())
    let instance = NfcCardReaderPlugin()
    eventChannel.setStreamHandler(instance)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
        case "scanCard":
            print("Card Scanning Started!!!!")
            startNFCSession()

        case "stopScanCard":
            print("Card Scanning Stopped!!!!")
            stopNFCSession()

        default:
          result(FlutterMethodNotImplemented)
    }
  }

  private func startNFCSession() {
      if #available(iOS 13.0, *) {
          var nfcSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
          nfcSession?.begin()
      } else {
          print("NFC Tag Reader is not supported on this version of iOS.")
      }
  }

  private func stopNFCSession() {
      print("Card Scanning Stopped!!!!")
  }
}

  extension NfcCardReaderPlugin: FlutterStreamHandler {

      public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
          print("onListen......")
          self.eventSink = eventSink
          return nil
      }

      public func onCancel(withArguments arguments: Any?) -> FlutterError? {
          eventSink = nil
          return nil
      }
  }

@available(iOS 13.0, *)
extension NfcCardReaderPlugin: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_: NFCTagReaderSession) {}

    public func tagReaderSession(_: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError {
            NSLog("Got NFCError when reading NFC: %@", nfcError.localizedDescription)
            switch nfcError.errorCode {
            case NFCReaderError.Code.readerSessionInvalidationErrorUserCanceled.rawValue:
                NSLog("SessionCanceled", error.localizedDescription)
            case NFCReaderError.Code.readerSessionInvalidationErrorSessionTimeout.rawValue:
                NSLog("SessionTimeOut", error.localizedDescription)
            default:
                NSLog("Generic NFC Error", error.localizedDescription)
            }
        } else {
            NSLog("Got unknown when reading NFC: %@", error.localizedDescription)
        }
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        let firstTag = tags.first!
        print("My Tag is \(firstTag).")
        DispatchQueue.main.async {
           if let eventSink = self.eventSink {
               eventSink(self.cardMap)
           }
        }

        session.invalidate()
    }
}
