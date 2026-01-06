import 'package:scraki/features/poster/domain/entities/poster_data.dart';

class CaptionGenerator {
  static List<String> generateCaptions(PosterData data) {
    return [
      _generateProfessional(data),
      _generateExciting(data),
      _generateShort(data),
    ];
  }

  static String _generateProfessional(PosterData data) {
    return '''
🚀 CƠ HỘI NGHỀ NGHIỆP TẠI ${data.companyName.toUpperCase()}

Vị trí: ${data.jobTitle}
📍 Địa điểm: ${data.location}
💰 Mức lương: ${data.salaryRange}

📌 Yêu cầu:
${data.requirements.take(3).map((e) => "- $e").join("\n")}

👉 Ứng tuyển ngay: ${data.contactInfo}
#tuyendung #vieclam #${data.companyName.replaceAll(' ', '')}
''';
  }

  static String _generateExciting(PosterData data) {
    return '''
🔥 [GẤP] ${data.companyName} ĐANG TÌM ĐỒNG ĐỘI! 🔥

🌟 Vị trí cực HOT: ${data.jobTitle}
💸 Lương thưởng hấp dẫn: ${data.salaryRange}
🏢 Làm việc tại: ${data.location}

✨ Tại sao bạn nên gia nhập?
${data.benefits.take(3).map((e) => "✅ $e").join("\n")}

📞 Liên hệ ngay để không bỏ lỡ: ${data.contactInfo}
#hiring #jobopening #hotjob
''';
  }

  static String _generateShort(PosterData data) {
    return '''
[TUYỂN DỤNG] ${data.jobTitle} - ${data.companyName}
📍 ${data.location} | 💰 ${data.salaryRange}
📞 LH: ${data.contactInfo}
''';
  }
}
