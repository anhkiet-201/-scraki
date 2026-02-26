// import 'dart:convert';
// import 'dart:io';
// import 'dart:async';
// import 'package:http/http.dart' as http;

// Future<String> getAccessToken({
//   required String clientId,
//   required String refreshToken,
// }) async {
//   final res = await http.post(
//     Uri.parse("https://login.microsoftonline.com/common/oauth2/v2.0/token"),
//     headers: {"Content-Type": "application/x-www-form-urlencoded"},
//     body: {
//       "client_id": clientId,
//       "grant_type": "refresh_token",
//       "refresh_token": refreshToken,
//     },
//   );

//   if (res.statusCode != 200) {
//     throw Exception("TOKEN ERROR: ${res.body}");
//   }

//   // print("DEBUG: Token Response: ${res.body}");
//   return jsonDecode(res.body)["access_token"];
// }

// String buildXoauth2(String email, String accessToken) {
//   final raw = "user=$email\u0001auth=Bearer $accessToken\u0001\u0001";
//   return base64Encode(utf8.encode(raw));
// }

// Future<String?> readOtpFromImap({
//   required String email,
//   required String accessToken,
// }) async {
//   int maxRetries = 3;
//   for (int i = 0; i < maxRetries; i++) {
//     SecureSocket? socket;
//     try {
//       print("Connecting to IMAP (Attempt ${i + 1}/$maxRetries)...");
//       socket = await SecureSocket.connect(
//         'outlook.office365.com',
//         993,
//         onBadCertificate: (_) => true,
//       );

//       // Helper to read response
//       final StreamIterator<String> reader = StreamIterator(
//         socket
//             .cast<List<int>>()
//             .transform(utf8.decoder)
//             .transform(const LineSplitter()),
//       );

//       // Consume initial OK
//       await reader.moveNext();

//       // Authenticate
//       final xoauth2 = buildXoauth2(email, accessToken);
//       socket.write("A01 AUTHENTICATE XOAUTH2 $xoauth2\r\n");

//       // Wait for Auth response
//       while (await reader.moveNext()) {
//         final line = reader.current;
//         if (line.startsWith("A01 OK")) {
//           print("✅ IMAP Authenticated");
//           break;
//         }
//         if (line.startsWith("A01 NO") || line.startsWith("A01 BAD")) {
//           throw Exception("IMAP Auth Failed: $line");
//         }
//         if (line.startsWith("+")) {
//           socket.write("\r\n");
//         }
//       }

//       // Select Inbox
//       socket.write("A02 SELECT INBOX\r\n");
//       int? messageCount;

//       while (await reader.moveNext()) {
//         final line = reader.current;
//         if (line.contains("EXISTS")) {
//           final parts = line.split(" ");
//           if (parts.length > 1) {
//             messageCount = int.tryParse(parts[1]);
//           }
//         }
//         if (line.startsWith("A02 OK")) break;
//         if (line.startsWith("A02 NO")) {
//           throw Exception("Select Inbox Failed: $line");
//         }
//       }

//       if (messageCount == null || messageCount == 0) {
//         print("Inbox is empty");
//         socket.write("A05 LOGOUT\r\n");
//         await socket.close();
//         return null;
//       }

//       print("Inbox has $messageCount messages. Fetching Subject and Body...");

//       // OTP Regex
//       final otpRegex = RegExp(r'\b\d{4,8}\b');
//       String? foundOtp;

//       // 1. Fetch Subject
//       socket.write("A03 FETCH $messageCount BODY[HEADER.FIELDS (SUBJECT)]\r\n");

//       while (await reader.moveNext()) {
//         final line = reader.current;
//         if (line.startsWith("A03 OK")) break;
//         if (line.startsWith("A03 NO")) {
//           print("Fetch Header failed: $line");
//           break;
//         }

//         // Check for Subject line and capture OTP
//         if (line.trim().startsWith("Subject:")) {
//           print("📧 ${line.trim()}");
//           final match = otpRegex.firstMatch(line);
//           if (match != null) {
//             foundOtp = match.group(0);
//           }
//         }
//       }

//       // 2. Fetch Body
//       socket.write("A04 FETCH $messageCount BODY[TEXT]\r\n");

//       StringBuffer bodyBuffer = StringBuffer();
//       bool readingBody = false;

//       while (await reader.moveNext()) {
//         final line = reader.current;

//         if (line.startsWith("A04 OK")) break;
//         if (line.startsWith("A04 NO")) {
//           print("Fetch Body failed: $line");
//           break;
//         }

//         if (line.contains("BODY[TEXT]")) {
//           readingBody = true;
//           continue;
//         }

//         if (readingBody) {
//           bodyBuffer.writeln(line);
//           if (foundOtp == null) {
//             final match = otpRegex.firstMatch(line);
//             if (match != null) {
//               foundOtp = match.group(0);
//             }
//           }
//         }
//       }

//       socket.write("A05 LOGOUT\r\n");
//       await socket.close();

//       return foundOtp;
//     } catch (e) {
//       print("❌ Connection Error (Attempt ${i + 1}): $e");
//       try {
//         socket?.destroy();
//       } catch (_) {}

//       if (i == maxRetries - 1) rethrow;
//       await Future.delayed(Duration(seconds: 2));
//     }
//   }
//   return null;
// }

// void main() async {
//   for (int i = 37; i > 0; i++) {
//     try {
//       String content;
//       final file = File('acc2.txt');
//       content = await file.readAsString();

//       final lines = content
//           .split('\n')
//           .where((l) => l.trim().isNotEmpty)
//           .toList();
//       print("Found ${lines.length} accounts in acc2.txt");

//       if (lines.isEmpty) return;

//       if (lines.length <= i) return;

//       final parts = lines[i - 1].split("|");
//       final nextParts = lines[i + 2].split("|");
//       if (parts.length < 6) return;

//       final refreshToken = parts[4].trim();
//       final clientId = parts[5].trim();
//       final password = parts[1].trim();
//       final email = parts[2].trim();
//       final nextEmail = nextParts[2].trim();

//       print("\nProcessing [$i] $email...");
//       try {
//         final accessToken = await getAccessToken(
//           clientId: clientId,
//           refreshToken: refreshToken,
//         );

//         final otp = await readOtpFromImap(
//           email: email,
//           accessToken: accessToken,
//         );

//         if (otp != null) {
//           print("📧 Email: $email");
//           print("✅ OTP: $otp");
//           print("🔑 Password: $password");
//           print("Next Email: $nextEmail");
//           // stdin.readLineSync();
//         } else {
//           print("❌ No OTP found in last email.");
//         }
//       } catch (e) {
//         print("❌ Error: $e");
//       }
//     } catch (e) {
//       print("Critical Error: $e");
//     }
//     return;
//   }
// }

// //70
