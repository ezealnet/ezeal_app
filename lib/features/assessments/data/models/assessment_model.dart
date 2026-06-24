class Assessment {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String assessmentType;
  final int durationMinutes;
  final int questionCount;
  final int basePrice;
  final String priceType;
  final bool isPublished;

  const Assessment({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.assessmentType,
    required this.durationMinutes,
    required this.questionCount,
    required this.basePrice,
    required this.priceType,
    required this.isPublished,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      assessmentType: json['assessment_type'] as String? ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      questionCount: (json['question_count'] as num?)?.toInt() ?? 20,
      basePrice: (json['base_price'] as num?)?.toInt() ?? 299,
      priceType: json['price_type'] as String? ?? 'paid',
      isPublished: json['is_published'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'assessment_type': assessmentType,
      'duration_minutes': durationMinutes,
      'question_count': questionCount,
      'base_price': basePrice,
      'price_type': priceType,
      'is_published': isPublished,
    };
  }

  Assessment copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    String? assessmentType,
    int? durationMinutes,
    int? questionCount,
    int? basePrice,
    String? priceType,
    bool? isPublished,
  }) {
    return Assessment(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      assessmentType: assessmentType ?? this.assessmentType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      questionCount: questionCount ?? this.questionCount,
      basePrice: basePrice ?? this.basePrice,
      priceType: priceType ?? this.priceType,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}
