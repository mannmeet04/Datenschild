class Breach {
  final String name;
  final String title;
  final String? domain;
  final String? breachDate;
  final String? industry;
  final List<String> dataClasses;
  final int? records;
  final String? description;
  final String? logoUrl;
  final bool sensitive;
  final bool verified;

  const Breach({
    required this.name,
    required this.title,
    this.domain,
    this.breachDate,
    this.industry,
    this.dataClasses = const [],
    this.records,
    this.description,
    this.logoUrl,
    this.sensitive = false,
    this.verified = false,
  });

  factory Breach.fromJson(Map<String, dynamic> json) => Breach(
        name: json['name'] as String,
        title: (json['title'] as String?) ?? json['name'] as String,
        domain: json['domain'] as String?,
        breachDate: json['breachDate'] as String?,
        industry: json['industry'] as String?,
        dataClasses: ((json['dataClasses'] as List?) ?? const []).cast<String>(),
        records: (json['records'] as num?)?.toInt(),
        description: json['description'] as String?,
        logoUrl: json['logoUrl'] as String?,
        sensitive: (json['sensitive'] as bool?) ?? false,
        verified: (json['verified'] as bool?) ?? false,
      );
}

class MonitoredEmail {
  final String id;
  final String maskedEmail;
  final bool verified;
  final DateTime? lastCheckedAt;
  final List<Breach> breaches;

  const MonitoredEmail({
    required this.id,
    required this.maskedEmail,
    required this.verified,
    this.lastCheckedAt,
    this.breaches = const [],
  });

  factory MonitoredEmail.fromJson(Map<String, dynamic> json) => MonitoredEmail(
        id: json['id'] as String,
        maskedEmail: json['maskedEmail'] as String,
        verified: json['verified'] as bool,
        lastCheckedAt: json['lastCheckedAt'] == null
            ? null
            : DateTime.parse(json['lastCheckedAt'] as String).toLocal(),
        breaches: ((json['breaches'] as List?) ?? const [])
            .map((b) => Breach.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}
