import 'dart:typed_data';

import 'package:flutter/material.dart';

Uint8List floatToByteArray(int modeIdentifier, List<double> dataToBeSent) {
  ByteData data = ByteData(0);

  int floatIdentifier = 0x02;

  // Allocate space for mode identifier, data type identifier and length
  int dataSize = 1 + 1 + 4;

  // Allocate space for doubles
  dataSize += 8 * dataToBeSent.length;

  // Allocate appropiate memory for the message
  data = ByteData(dataSize);

  // mode identifier
  data.setUint8(0, modeIdentifier);

  // data type identifier
  data.setUint8(1, floatIdentifier);

  // how many data to extract
  data.setInt32(2, dataToBeSent.length, Endian.little);

  // the data itself
  // 1 byte for mode identifier, 1 byte for data type identifier, 4 bytes for length
  int offset = 6;

  for (double value in dataToBeSent) {
    data.setFloat32(offset, value, Endian.little);
    offset += 4; // 8 bytes for a double
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
  List<dynamic> decoded = [];
  // data type identifier
  const int integerIdentifier = 0x01;
  const int floatIdentifier = 0x02;

  // Essentials for decoding message
  const int mssgStartingIndex = 10;
  const int mssgTypeIndex = 6;
  const int intBufferSize = 4;
  const int floatBufferSize = 4;

  final int dataTypeIdentifier = mssg[1];

  // Get the length of the information
  final int dataLength =
      ByteData.sublistView(mssg, 2, mssgStartingIndex).getInt8(0);

  // Get the message type of the information
  final int mssgType =
      ByteData.sublistView(mssg, mssgTypeIndex, mssgStartingIndex - 1)
          .getInt8(0);

  if (dataTypeIdentifier == floatIdentifier ||
      dataTypeIdentifier == integerIdentifier) {
    if (dataTypeIdentifier == floatIdentifier) {
      final List<double> doubleValues = [];
      for (int i = 0; i < dataLength; i++) {
        final double doubleValue = ByteData.sublistView(
                mssg,
                mssgStartingIndex + (i * floatBufferSize),
                mssgStartingIndex + (i * floatBufferSize) + floatBufferSize)
            .getFloat32(0, Endian.little);
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

List<dynamic> decodeData_preRelease(Uint8List mssg) {
  // To store decoded data later
  List<dynamic> decoded = [];

  // data type identifier
  const int integerIdentifier = 0x01;
  const int floatIdentifier = 0x02;

  // Essentials for decoding message
  const int mssgStartingIndex = 6;
  const int intBufferSize = 4;
  const int floatBufferSize = 4;

  final int dataTypeIdentifier = mssg[1];

  // Get the length of the information
  final int dataLength =
      ByteData.sublistView(mssg, 2, mssgStartingIndex).getInt8(0);

  if (dataTypeIdentifier == floatIdentifier ||
      dataTypeIdentifier == integerIdentifier) {
    if (dataTypeIdentifier == floatIdentifier) {
      final List<double> doubleValues = [];
      for (int i = 0; i < dataLength; i++) {
        final double doubleValue = ByteData.sublistView(
                mssg,
                mssgStartingIndex + (i * floatBufferSize),
                mssgStartingIndex + (i * floatBufferSize) + floatBufferSize)
            .getFloat32(0, Endian.little);
        doubleValues.add(doubleValue);
      }
      decoded = doubleValues;
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
      decoded = integerValues;
    }

    // Return decoded data
    return decoded;
  } else {
    throw ArgumentError("Unknown identifier");
  }
}
