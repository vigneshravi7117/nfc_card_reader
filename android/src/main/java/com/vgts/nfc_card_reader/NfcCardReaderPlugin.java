package com.vgts.nfc_card_reader;

import android.app.Activity;
import android.nfc.NfcAdapter;
import android.nfc.Tag;
import android.nfc.tech.IsoDep;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.util.Log;

import androidx.annotation.NonNull;

import java.util.Objects;

import com.github.devnied.emvnfccard.enums.EmvCardScheme;
import com.github.devnied.emvnfccard.model.Application;
import com.github.devnied.emvnfccard.model.EmvCard;
import com.github.devnied.emvnfccard.parser.EmvTemplate;

import java.io.IOException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

import java.util.HashMap;
import java.util.Map;
import android.content.Context;

/** NfcCardReaderPlugin */
public class NfcCardReaderPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, NfcAdapter.ReaderCallback {
  private MethodChannel channel;
  private NfcAdapter mNfcAdapter;
  private Result flutterResult;
  private Activity activity;
  public static final String STREAM = "cardDetailsStream";
  private EventChannel.EventSink attachEvent;
  final String TAG_NAME = "From_Native";
  Context applicationContext; 

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "com.vgts/nfc_card_reader");
    channel.setMethodCallHandler(this);
    applicationContext = flutterPluginBinding.getApplicationContext();
    new EventChannel(flutterPluginBinding.getBinaryMessenger(), STREAM).setStreamHandler(
            new EventChannel.StreamHandler() {
              @Override
              public void onListen(Object args, EventChannel.EventSink events) {
                attachEvent = events;
              }

              @Override
              public void onCancel(Object args) {
                attachEvent = null;
              }
            }
    );
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("scanCard")) {
      flutterResult = result;
      startNfcReader();
    }
    else if(call.method.equals("stopScanCard")) {
      stopNfcReader();
      result.success(true);
    }
    else {
      result.notImplemented();
    }
  }

  private void startNfcReader() {
    if (activity != null) {
      mNfcAdapter = NfcAdapter.getDefaultAdapter(activity);
      if (mNfcAdapter != null) {
        Bundle options = new Bundle();
        options.putInt(NfcAdapter.EXTRA_READER_PRESENCE_CHECK_DELAY, 250);
        mNfcAdapter.enableReaderMode(activity,
            this,
            NfcAdapter.FLAG_READER_NFC_A |
                NfcAdapter.FLAG_READER_NFC_B |
                NfcAdapter.FLAG_READER_NFC_F |
                NfcAdapter.FLAG_READER_NFC_V |
                NfcAdapter.FLAG_READER_NFC_BARCODE |
                NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS,
            options);
        mNfcAdapter.disableForegroundDispatch(activity);
      } else {
        if (flutterResult != null) {
          flutterResult.error("NFC_NOT_SUPPORTED", "NFC is not supported on this device", null);
        }
      }
    } else {
      if (flutterResult != null) {
        flutterResult.error("ACTIVITY_NOT_AVAILABLE", "Activity is not available", null);
      }
    }
  }

  private void stopNfcReader() {
      if(mNfcAdapter!=null){
        mNfcAdapter.disableReaderMode(activity);
      }
      if (attachEvent != null) {
        attachEvent.endOfStream();
      }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

   @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }

  @Override
  public void onTagDiscovered(Tag tag) {
    IsoDep isoDep = IsoDep.get(tag);
    if (isoDep != null) {
      try {
        isoDep.connect();

        PcscProvider provider = new PcscProvider();
        provider.setmTagCom(isoDep);

        EmvTemplate.Config config = EmvTemplate.Config()
            .setContactLess(true)
            .setReadAllAids(true)
            .setReadTransactions(true)
            .setRemoveDefaultParsers(false)
            .setReadAt(true);

        EmvTemplate parser = EmvTemplate.Builder()
            .setProvider(provider)
            .setConfig(config)
            .build();

        EmvCard card = parser.readEmvCard();
        String cardNumber = card.getCardNumber();
        Date expireDate = card.getExpireDate();
        LocalDate date = expireDate != null
            ? expireDate.toInstant().atZone(ZoneId.systemDefault()).toLocalDate()
            : null;

        Map<String, Object> cardMap = new HashMap<>();
        cardMap.put("cardNumber", prettyPrintCardNumber(cardNumber));
        cardMap.put("cardExpiry", date != null ? date.toString() : null);
        cardMap.put("cardHolder", card.getHolderLastname());

        new Handler(Looper.getMainLooper()).post(() -> {
          if (attachEvent != null) {
            attachEvent.success(cardMap);
          }
        });

        isoDep.close();
      } catch (IOException e) {
        e.printStackTrace();
        new Handler(Looper.getMainLooper()).post(() -> {
          if (flutterResult != null) {
            flutterResult.error("NFC_READ_ERROR", "Error reading NFC tag", e.getMessage());
          }
        });
      } catch (Exception e) {
        e.printStackTrace();
        new Handler(Looper.getMainLooper()).post(() -> {
          if (flutterResult != null) {
            flutterResult.error("NFC_READ_ERROR", "Error processing NFC tag", e.getMessage());
          }
        });
      }
    }
  }


  public static String prettyPrintCardNumber(String cardNumber) {
    if (cardNumber == null) return null;
    char delimiter = ' ';
    return cardNumber.replaceAll(".{4}(?!$)", "$0" + delimiter);
  }


}
