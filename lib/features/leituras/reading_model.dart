import 'package:cloud_firestore/cloud_firestore.dart';

enum MeterType {
  gas,
  water;

  String get label {
    switch (this) {
      case MeterType.gas:
        return 'Gás';
      case MeterType.water:
        return 'Água';
    }
  }

  String get unit => 'm³';

  static MeterType fromString(String? value) {
    if (value == null) return MeterType.gas;
    final lower = value.trim().toLowerCase();
    if (lower == 'water' || lower == 'agua' || lower == 'água') {
      return MeterType.water;
    }
    return MeterType.gas;
  }
}

class ReadingModel {
  final String id;
  final String readingValue;
  final MeterType meterType;
  final String? photoUrl;
  final String? photoPath;
  final DateTime readAt;
  final String? userId;
  final bool synced;

  // Campos de contexto estrutural (anexados pelo controller/dataSource)
  final String? apartmentId;
  final String? apartmentName;
  final String? blockId;
  final String? blockName;
  final String? condominiumId;
  final String? condominiumName;
  final String? administratorId;
  final String? administratorName;

  const ReadingModel({
    required this.id,
    required this.readingValue,
    this.meterType = MeterType.gas,
    this.photoUrl,
    this.photoPath,
    required this.readAt,
    this.userId,
    this.synced = true,
    this.apartmentId,
    this.apartmentName,
    this.blockId,
    this.blockName,
    this.condominiumId,
    this.condominiumName,
    this.administratorId,
    this.administratorName,
  });

  /// Retorna o valor numérico para cálculo de consumo (m³).
  double? get numericValue {
    if (readingValue.trim().isEmpty) return null;
    final normalized = readingValue.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  factory ReadingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    String? apartmentId,
    String? apartmentName,
    String? blockId,
    String? blockName,
    String? condominiumId,
    String? condominiumName,
    String? administratorId,
    String? administratorName,
  }) {
    final data = snapshot.data() ?? {};
    final rawReadAt = data['readAt'];
    DateTime parsedDate;
    if (rawReadAt is Timestamp) {
      parsedDate = rawReadAt.toDate();
    } else if (rawReadAt is DateTime) {
      parsedDate = rawReadAt;
    } else {
      parsedDate = DateTime.now();
    }

    final parsedType = MeterType.fromString(
      data['type'] as String? ?? data['meterType'] as String?,
    );

    return ReadingModel(
      id: snapshot.id,
      readingValue: (data['readingValue'] as String?)?.trim() ?? '',
      meterType: parsedType,
      photoUrl: data['photoUrl'] as String?,
      photoPath: data['photoPath'] as String?,
      readAt: parsedDate,
      userId: data['userId'] as String?,
      synced: data['synced'] as bool? ?? true,
      apartmentId: apartmentId ?? (data['apartmentId'] as String?),
      apartmentName: apartmentName ?? (data['apartmentName'] as String?),
      blockId: blockId ?? (data['blockId'] as String?),
      blockName: blockName ?? (data['blockName'] as String?),
      condominiumId: condominiumId ?? (data['condominiumId'] as String?),
      condominiumName: condominiumName ?? (data['condominiumName'] as String?),
      administratorId: administratorId ?? (data['administratorId'] as String?),
      administratorName: administratorName ?? (data['administratorName'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': meterType.name,
      'meterType': meterType.name,
      'readingValue': readingValue,
      'photoUrl': photoUrl,
      'photoPath': photoPath,
      'readAt': Timestamp.fromDate(readAt),
      'userId': userId,
      'synced': synced,
      if (apartmentId != null) 'apartmentId': apartmentId,
      if (apartmentName != null) 'apartmentName': apartmentName,
      if (blockId != null) 'blockId': blockId,
      if (blockName != null) 'blockName': blockName,
      if (condominiumId != null) 'condominiumId': condominiumId,
      if (condominiumName != null) 'condominiumName': condominiumName,
    };
  }

  ReadingModel copyWith({
    String? id,
    String? readingValue,
    MeterType? meterType,
    String? photoUrl,
    String? photoPath,
    DateTime? readAt,
    String? userId,
    bool? synced,
    String? apartmentId,
    String? apartmentName,
    String? blockId,
    String? blockName,
    String? condominiumId,
    String? condominiumName,
    String? administratorId,
    String? administratorName,
  }) {
    return ReadingModel(
      id: id ?? this.id,
      readingValue: readingValue ?? this.readingValue,
      meterType: meterType ?? this.meterType,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPath: photoPath ?? this.photoPath,
      readAt: readAt ?? this.readAt,
      userId: userId ?? this.userId,
      synced: synced ?? this.synced,
      apartmentId: apartmentId ?? this.apartmentId,
      apartmentName: apartmentName ?? this.apartmentName,
      blockId: blockId ?? this.blockId,
      blockName: blockName ?? this.blockName,
      condominiumId: condominiumId ?? this.condominiumId,
      condominiumName: condominiumName ?? this.condominiumName,
      administratorId: administratorId ?? this.administratorId,
      administratorName: administratorName ?? this.administratorName,
    );
  }
}
