import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class XorEncryption {
  /// Derives the 32-byte XOR key using the same algorithm as the backend:
  /// SHA256("${downloadToken}:${userId}:ebook-drm")
  static Uint8List deriveKey(String downloadToken, String userId) {
    final input = '$downloadToken:$userId:ebook-drm';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  /// XOR decrypt (same operation as encrypt — XOR is symmetric)
  static Uint8List decrypt(Uint8List data, Uint8List key) {
    final result = Uint8List(data.length);
    final keyLen = key.length;
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i % keyLen];
    }
    return result;
  }
}
