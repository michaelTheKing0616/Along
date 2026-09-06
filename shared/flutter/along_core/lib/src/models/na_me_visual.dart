/// Maps server Na Me tokens to design-system labels (no hardcoded palette).
String naMeColourLabel(String colorToken) {
  final slug = _tokenSlug(colorToken);
  return slug.toUpperCase();
}

String naMeShapeLabel(String shape) => shape.toUpperCase();

String _tokenSlug(String token) {
  final parts = token.split('.');
  return parts.isNotEmpty ? parts.last : token;
}
