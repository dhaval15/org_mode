abstract class OrgNode {
  List<OrgNode> get children => const [];

  /// Walk AST with [visitor]. Specify a type [T] to only visit nodes of that
  /// type. The visitor function must return `true` to continue iterating, or
  /// `false` to stop.
  bool visit<T extends OrgNode>(bool Function(T) visitor) {
    final self = this;
    if (self is T) {
      if (!visitor.call(self)) {
        return false;
      }
    }
    for (final child in children) {
      if (!child.visit<T>(visitor)) {
        return false;
      }
    }
    return true;
  }

  String toOrg();
}
