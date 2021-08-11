import '../org/org.dart';

extension OrgContentExtension on OrgContent {
  OrgPlanningLine? get planningLine {
    final lines = children.whereType<OrgPlanningLine>();
    return lines.isNotEmpty ? lines.first : null;
  }
}
