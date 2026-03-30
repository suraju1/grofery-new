import 'dart:io';

void main() {
  final file = File('signing_report.txt');
  if (!file.existsSync()) {
    print('Error: signing_report.txt not found');
    return;
  }

  // signingReport output can be UTF-16LE or UTF-8 depending on environment
  // We try to read it as a string
  String content;
  try {
    content = file.readAsStringSync();
  } catch (e) {
    try {
      // Try with system encoding if default fails
      content = file.readAsStringSync(encoding: systemEncoding);
    } catch (e2) {
      print('Failed to read file: $e2');
      return;
    }
  }

  final lines = content.split('\n');
  
  String? currentVariant;
  
  for (var line in lines) {
    line = line.trim();
    if (line.startsWith('Variant:')) {
      currentVariant = line;
    }
    
    if (currentVariant != null && currentVariant.contains('debug')) {
       if (line.startsWith('SHA1:')) {
         print('DEBUG_SHA1: ${line.replaceFirst('SHA1:', '').trim()}');
       }
       if (line.startsWith('SHA-256:')) {
         print('DEBUG_SHA256: ${line.replaceFirst('SHA-256:', '').trim()}');
       }
    }
    
    // Also capture release if present
    if (currentVariant != null && currentVariant.contains('release')) {
       if (line.startsWith('SHA1:')) {
         print('RELEASE_SHA1: ${line.replaceFirst('SHA1:', '').trim()}');
       }
       if (line.startsWith('SHA-256:')) {
         print('RELEASE_SHA256: ${line.replaceFirst('SHA-256:', '').trim()}');
       }
    }
  }
}
