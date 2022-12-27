class MissingArgumentException implements Exception {
  final String _parameter;
  MissingArgumentException(this._parameter);

  @override
  String toString () => 'The $_parameter parameter is required.';
}