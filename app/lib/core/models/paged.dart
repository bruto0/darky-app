class Paged<T> {
  const Paged({
    required this.items,
    required this.total,
    required this.page,
  });

  final List<T> items;
  final int total;
  final int page;

  bool hasMore({required int pageSize}) => page * pageSize < total;
}
