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
  final List<String> defectTypes; // Changed to List
  final String description;
  final String reportedBy;
  final String reportedById;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const FigmaDefectLog({
    required this.id,
    required this.defectTypes,
    required this.description,
    required this.reportedBy,
    required this.reportedById,
    required this.reportedAt,
    this.resolvedAt,
    this.resolvedBy,
  });
}

enum FigmaStatus { pending, inProgress, completed }

enum RequisitionStatus { pending, inProgress, completed, approved, refused }

class FigmaRequisitionItem {
  final String id;
  final String code;
  final String description;
  final double requestedQuantity;
  final bool isMarked;
  final String? productName;

  const FigmaRequisitionItem({
    required this.id,
    required this.code,
    required this.description,
    required this.requestedQuantity,
    this.isMarked = false,
    this.productName,
  });

  FigmaRequisitionItem copyWith({bool? isMarked, String? productName, double? requestedQuantity}) {
    return FigmaRequisitionItem(
      id: id,
      code: code,
      description: description,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      isMarked: isMarked ?? this.isMarked,
      productName: productName ?? this.productName,
    );
  }
}

class FigmaRequisition {
  final String id;
  final String number;
  final List<FigmaRequisitionItem> items;
  final RequisitionStatus status;
  final String requesterName;
  final String originStage;
  final String? sourceWarehouse; // e.g. "02"
  final String? targetWarehouse; // e.g. "01"
  final DateTime createdAt;

  const FigmaRequisition({
    required this.id,
    required this.number,
    required this.items,
    required this.status,
    required this.requesterName,
    required this.originStage,
    required this.createdAt,
    this.sourceWarehouse,
    this.targetWarehouse,
  });

  FigmaRequisition copyWith({
    RequisitionStatus? status,
    List<FigmaRequisitionItem>? items,
    String? sourceWarehouse,
    String? targetWarehouse,
  }) {
    return FigmaRequisition(
      id: id,
      number: number,
      items: items ?? this.items,
      status: status ?? this.status,
      requesterName: requesterName,
      originStage: originStage,
      createdAt: createdAt,
      sourceWarehouse: sourceWarehouse ?? this.sourceWarehouse,
      targetWarehouse: targetWarehouse ?? this.targetWarehouse,
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
  final String? lastSignature;
  final String? originStage;
  final DateTime? lastMoveAt;
  final List<FigmaRequisitionItem> rawMaterials;

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
    this.lastSignature,
    this.originStage,
    this.lastMoveAt,
    this.rawMaterials = const [],
  });

  FigmaOrder copyWith({
    String? id,
    int? totalQuantity,
    int? producedQuantity,
    int? remainingQuantity,
    FigmaStatus? status,
    String? currentStage,
    List<FigmaProductionLog>? productionLogs,
    List<FigmaDefectLog>? defectLogs,
    DateTime? completedAt,
    String? lastSignature,
    String? originStage,
    DateTime? lastMoveAt,
    List<FigmaRequisitionItem>? rawMaterials,
  }) {
    return FigmaOrder(
      id: id ?? this.id,
      opNumber: opNumber,
      productCode: productCode,
      productName: productName,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      producedQuantity: producedQuantity ?? this.producedQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      currentStage: currentStage ?? this.currentStage,
      productionLogs: productionLogs ?? this.productionLogs,
      defectLogs: defectLogs ?? this.defectLogs,
      completedAt: completedAt ?? this.completedAt,
      lastSignature: lastSignature ?? this.lastSignature,
      originStage: originStage ?? this.originStage,
      lastMoveAt: lastMoveAt ?? this.lastMoveAt,
      rawMaterials: rawMaterials ?? this.rawMaterials,
    );
  }
}
