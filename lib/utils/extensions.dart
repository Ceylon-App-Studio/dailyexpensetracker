extension FirstWhereOrNullExtension<E> on Iterable<E> {
  /// Returns the first element that satisfies [test], or null if none found.
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
