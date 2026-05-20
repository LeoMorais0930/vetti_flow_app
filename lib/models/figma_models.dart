import 'package:flutter/material.dart';

enum FigmaRole {
  almoxarifado,
  smd,
  gravacao,
  soldagem,
  teste,
  embalagem,
  expedicao,
  suporte
}

class FigmaUser {
  final String id;
  final String name;
  final String username;
  final FigmaRole role;
  final String pin;

  const FigmaUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.pin,
  });
}

class FigmaProductionLog {
  final String id;
  final String operatorName;
  final String operatorId;
  final String pin;
  final DateTime timestamp;
  final int quantityProduced;
  final String stage;

  const FigmaProductionLog({
    required this.id,
    required this.operatorName,
    required this.operatorId,
    required this.pin,
    required this.timestamp,
    required this.quantityProduced,
    required this.stage,
  });
}

class FigmaDefectLog {
  final String id;
  final String defectType;
  final String description;
  final String reportedBy;
  final String reportedById;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const FigmaDefectLog({
    required this.id,
    required this.defectType,
    required this.description,
    required this.reportedBy,
    required this.reportedById,
    required this.reportedAt,
    this.resolvedAt,
    this.resolvedBy,
  });
}

enum FigmaStatus { pending, inProgress, completed }

class FigmaOrder {
  final String id;
  final String opNumber;
  final String productCode;
  final String productName;
  final int totalQuantity;
  final int producedQuantity;
  final int remainingQuantity;
  final FigmaStatus status;
  final String createdBy;
  final DateTime createdAt;
  final String currentStage;
  final List<FigmaProductionLog> productionLogs;
  final List<FigmaDefectLog> defectLogs;
  final DateTime? completedAt;

  const FigmaOrder({
    required this.id,
    required this.opNumber,
    required this.productCode,
    required this.productName,
    required this.totalQuantity,
    required this.producedQuantity,
    required this.remainingQuantity,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.currentStage,
    required this.productionLogs,
    this.defectLogs = const [],
    this.completedAt,
  });

  FigmaOrder copyWith({
    int? producedQuantity,
    int? remainingQuantity,
    FigmaStatus? status,
    String? currentStage,
    List<FigmaProductionLog>? productionLogs,
    List<FigmaDefectLog>? defectLogs,
    DateTime? completedAt,
  }) {
    return FigmaOrder(
      id: id,
      opNumber: opNumber,
      productCode: productCode,
      productName: productName,
      totalQuantity: totalQuantity,
      producedQuantity: producedQuantity ?? this.producedQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      currentStage: currentStage ?? this.currentStage,
      productionLogs: productionLogs ?? this.productionLogs,
      defectLogs: defectLogs ?? this.defectLogs,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
