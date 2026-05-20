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

enum RequisitionStatus { pending, inProgress, completed }

class FigmaRequisitionItem {
  final String id;
  final String code;
  final String description;
  final double requestedQuantity;
  final bool isMarked;

  const FigmaRequisitionItem({
    required this.id,
    required this.code,
    required this.description,
    required this.requestedQuantity,
    this.isMarked = false,
  });

  FigmaRequisitionItem copyWith({bool? isMarked}) {
    return FigmaRequisitionItem(
      id: id,
      code: code,
      description: description,
      requestedQuantity: requestedQuantity,
      isMarked: isMarked ?? this.isMarked,
    );
  }
}

class FigmaRequisition {
  final String id;
  final String number;
  final List<FigmaRequisitionItem> items;
  final RequisitionStatus status;

  const FigmaRequisition({
    required this.id,
    required this.number,
    required this.items,
    required this.status,
  });

  FigmaRequisition copyWith({
    RequisitionStatus? status,
    List<FigmaRequisitionItem>? items,
  }) {
    return FigmaRequisition(
      id: id,
      number: number,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }
}

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
