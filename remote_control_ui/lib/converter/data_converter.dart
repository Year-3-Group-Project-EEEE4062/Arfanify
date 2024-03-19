import 'dart:typed_data';

import 'package:flutter/material.dart';

Uint8List doubleToByteArray(int modeIdentifier, List<double> dataToBeSent) {
  ByteData data = ByteData(0);

  int doubleTypeIdentifier = 0x02;

  // Allocate space for mode identifier, data type identifier and length
  int dataSize = 1 + 1 + 4;

  // Allocate space for doubles
  dataSize += 8 * dataToBeSent.length;

  // Allocate appropiate memory for the message
  data = ByteData(dataSize);

  // mode identifier
  data.setUint8(0, modeIdentifier);

  // data type identifier
  data.setUint8(1, doubleTypeIdentifier);

  // how many data to extract
  data.setInt32(2, dataToBeSent.length, Endian.little);

  // the data itself
  // 1 byte for mode identifier, 1 byte for data type identifier, 4 bytes for length
  int offset = 6;

  for (double value in dataToBeSent) {
    data.setFloat64(offset, value, Endian.little);
    offset += 8; // 8 bytes for a double
  }

  // Convert ByteData to Uint8List
  Uint8List byteList = data.buffer.asUint8List();

  debugPrint("$byteList");
  debugPrint("${byteList.length}");

  return byteList;
}

Uint8List integerToByteArray(int modeIdentifier, List<int> dataToBeSent) {
  ByteData data = ByteData(0);

  int integerTypeIdentifier = 0x01;

  // Allocate space for identifier and length
  int dataSize = 1 + 1 + 4;

  // Allocate space for integers
  dataSize += 4 * dataToBeSent.length;

  data = ByteData(dataSize);

  // mode identifier
  data.setUint8(0, modeIdentifier);

  // data type identifier
  data.setUint8(1, integerTypeIdentifier);

  // how many data to extract
  data.setInt32(2, dataToBeSent.length, Endian.little);

  // the data itself
  // 1 byte for mode identifier, 1 byte for data type identifier, 4 bytes for length
  int offset = 6;

  for (int value in dataToBeSent) {
    data.setInt32(offset, value, Endian.little);
    offset += 4; // 4 bytes for an integer
  }

  // Convert ByteData to Uint8List
  Uint8List byteList = data.buffer.asUint8List();

  debugPrint("$byteList");
  debugPrint("${byteList.length}");

  return byteList;
}

List<dynamic> decodeData(Uint8List mssg) {
  // To store decoded data later
  List<dynamic> decoded = [0];
  // data type identifier
  const int integerIdentifier = 0x01;
  const int doubleIdentifier = 0x02;

  // Essentials for decoding message
  const int mssgStartingIndex = 10;
  const int mssgTypeIndex = 6;
  const int intBufferSize = 4;
  const int doubleBufferSize = 8;

  final int dataTypeIdentifier = mssg[1];

  // Get the length of the information
  final int dataLength =
      ByteData.sublistView(mssg, 2, mssgStartingIndex).getInt8(0);

  // Get the length of the information
  final int mssgType =
      ByteData.sublistView(mssg, mssgTypeIndex, mssgStartingIndex - 1)
          .getInt8(0);

  if (dataTypeIdentifier == doubleIdentifier ||
      dataTypeIdentifier == integerIdentifier) {
    if (dataTypeIdentifier == doubleIdentifier) {
      final List<double> doubleValues = [];
      for (int i = 0; i < dataLength; i++) {
        final double doubleValue = ByteData.sublistView(
                mssg,
                mssgStartingIndex + (i * doubleBufferSize),
                mssgStartingIndex + (i * doubleBufferSize) + doubleBufferSize)
            .getFloat64(0, Endian.little);
        doubleValues.add(doubleValue);
      }
      decoded = [mssgType, doubleValues];
    } else if (dataTypeIdentifier == integerIdentifier) {
      final List<int> integerValues = [];
      for (int i = 0; i < dataLength; i++) {
        final int integerValue = ByteData.sublistView(
                mssg,
                mssgStartingIndex + (i * intBufferSize),
                mssgStartingIndex + (i * intBufferSize) + intBufferSize)
            .getInt32(0, Endian.little);
        integerValues.add(integerValue);
      }
      decoded = [mssgType, integerValues];
    }

    // Return decoded data
    return decoded;
  } else {
    throw ArgumentError("Unknown identifier");
  }
}
