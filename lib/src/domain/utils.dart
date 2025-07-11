String? notEmptyValidator(String? value) {
  return switch (value) {
    String(:final isEmpty) when isEmpty => 'The value cannot be empty',
    _ => null,
  };
}
