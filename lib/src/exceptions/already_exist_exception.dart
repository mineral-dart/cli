class AlreadyExistException implements Exception {
  final Uri _location;
  AlreadyExistException(this._location);

  @override
  String toString () => 'Path $_location already exists, please select another one.';
}