class ToggleTransportTypeUseCase {
  const ToggleTransportTypeUseCase();

  Set<int> call(Set<int> current, int type) {
    final next = {...current};
    if (!next.add(type)) {
      next.remove(type);
    }
    return next;
  }
}
