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
