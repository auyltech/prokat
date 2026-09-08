enum ChatListFilter {
  active,
  archived;

  String get apiValue {
    switch (this) {
      case ChatListFilter.active:
        return 'ACTIVE';
      case ChatListFilter.archived:
        return 'ARCHIVED';
    }
  }
}
