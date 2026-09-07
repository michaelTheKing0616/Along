import 'package:along_core/along_core.dart';

/// R-24 incident category grid (doc 02 §11 `incident_type` enum).
class IncidentCategory {
  const IncidentCategory({
    required this.type,
    required this.iconName,
  });

  final String type;
  final String iconName;
}

const incidentCategories = [
  IncidentCategory(type: 'safety', iconName: 'shield'),
  IncidentCategory(type: 'fare_dispute', iconName: 'payments'),
  IncidentCategory(type: 'vehicle_quality', iconName: 'directions_car'),
  IncidentCategory(type: 'driver_behavior', iconName: 'person'),
  IncidentCategory(type: 'lost_item', iconName: 'inventory_2'),
  IncidentCategory(type: 'other', iconName: 'more_horiz'),
];

String incidentCategoryLabel(String type, String Function(String key) l10n) =>
    switch (type) {
      'safety' => l10n('incidentCategorySafety'),
      'fare_dispute' => l10n('incidentCategoryFareDispute'),
      'vehicle_quality' => l10n('incidentCategoryVehicleQuality'),
      'driver_behavior' => l10n('incidentCategoryDriverBehavior'),
      'lost_item' => l10n('incidentCategoryLostItem'),
      'other' => l10n('incidentCategoryOther'),
      _ => type,
    };
