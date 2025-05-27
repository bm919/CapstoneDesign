class ErrorReport {
  final String id;
  final String imagePath;
  final String type;
  final String content;
  final String date;
  final String status;
  final String? adminMessage;

  ErrorReport({
    required this.id,
    required this.imagePath,
    required this.type,
    required this.content,
    required this.date,
    required this.status,
    this.adminMessage,
  });

  factory ErrorReport.fromJson(Map<String, dynamic> json) {
    return ErrorReport(
      id: json['id'],
      imagePath: json['imagePath'],
      type: json['type'],
      content: json['content'],
      date: json['date'],
      status: json['status'],
      adminMessage: json['adminMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'type': type,
      'content': content,
      'date': date,
      'status': status,
      'adminMessage': adminMessage,
    };
  }
}
