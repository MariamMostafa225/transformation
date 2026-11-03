class Car {
  const Car({
    required this.id,
    required this.carNumber,
    required this.letters,
    required this.companyId,
    required this.companyName,
    this.updatedAt,
  });

  final String id;
  final String carNumber;
  final String letters;
  final String companyId;
  final String companyName;
  final DateTime? updatedAt;

  factory Car.fromMap(
    String id,
    Map<String, dynamic> data, {
    required String companyName,
  }) {
    final timestamp = data['updatedAt'];
    return Car(
      id: id,
      carNumber: (data['carNumber'] ?? '').toString(),
      letters: (data['letters'] ?? '').toString(),
      companyId: (data['companyId'] ?? '').toString(),
      companyName: companyName,
      updatedAt: timestamp is DateTime ? timestamp : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'carNumber': carNumber,
    'letters': letters,
    'companyId': companyId,
  };
}
