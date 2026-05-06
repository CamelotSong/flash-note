// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allNotesHash() => r'allNotes_generated_hash_v1';

/// See also [allNotes].
@ProviderFor(allNotes)
final allNotesProvider = AutoDisposeStreamProvider<List<Note>>.internal(
  allNotes,
  name: r'allNotesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allNotesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllNotesRef = AutoDisposeStreamProviderRef<List<Note>>;

String _$noteByIdHash() => r'noteById_generated_hash_v1';

/// Copied from [noteById].
@ProviderFor(noteById)
const noteByIdProvider = NoteByIdFamily();

/// Copied from [noteById].
class NoteByIdFamily extends Family<AsyncValue<Note?>> {
  /// Copied from [noteById].
  const NoteByIdFamily();

  /// Copied from [noteById].
  NoteByIdProvider call(
    int id,
  ) {
    return NoteByIdProvider(
      id,
    );
  }

  @override
  NoteByIdProvider getProviderOverride(
    covariant NoteByIdProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'noteByIdProvider';
}

/// Copied from [noteById].
class NoteByIdProvider extends AutoDisposeFutureProvider<Note?> {
  /// Copied from [noteById].
  NoteByIdProvider(
    int id,
  ) : this._internal(
          (ref) => noteById(
            ref as NoteByIdRef,
            id,
          ),
          from: noteByIdProvider,
          name: r'noteByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$noteByIdHash,
          dependencies: NoteByIdFamily._dependencies,
          allTransitiveDependencies:
              NoteByIdFamily._allTransitiveDependencies,
          id: id,
        );

  NoteByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final int id;

  @override
  Override overrideWith(
    FutureOr<Note?> Function(NoteByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NoteByIdProvider._internal(
        (ref) => create(ref as NoteByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Note?> createElement() {
    return _NoteByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);
    return _SystemHash.finish(hash);
  }
}

mixin NoteByIdRef on AutoDisposeFutureProviderRef<Note?> {
  /// The parameter `id` of this provider.
  int get id;
}

class _NoteByIdProviderElement extends AutoDisposeFutureProviderElement<Note?>
    with NoteByIdRef {
  _NoteByIdProviderElement(super.provider);

  @override
  int get id => (origin as NoteByIdProvider).id;
}

String _$remindersForNoteHash() => r'remindersForNote_generated_hash_v1';

/// Copied from [remindersForNote].
@ProviderFor(remindersForNote)
const remindersForNoteProvider = RemindersForNoteFamily();

/// Copied from [remindersForNote].
class RemindersForNoteFamily extends Family<AsyncValue<List<Reminder>>> {
  /// Copied from [remindersForNote].
  const RemindersForNoteFamily();

  /// Copied from [remindersForNote].
  RemindersForNoteProvider call(
    int noteId,
  ) {
    return RemindersForNoteProvider(
      noteId,
    );
  }

  @override
  RemindersForNoteProvider getProviderOverride(
    covariant RemindersForNoteProvider provider,
  ) {
    return call(
      provider.noteId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'remindersForNoteProvider';
}

/// Copied from [remindersForNote].
class RemindersForNoteProvider
    extends AutoDisposeStreamProvider<List<Reminder>> {
  /// Copied from [remindersForNote].
  RemindersForNoteProvider(
    int noteId,
  ) : this._internal(
          (ref) => remindersForNote(
            ref as RemindersForNoteRef,
            noteId,
          ),
          from: remindersForNoteProvider,
          name: r'remindersForNoteProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$remindersForNoteHash,
          dependencies: RemindersForNoteFamily._dependencies,
          allTransitiveDependencies:
              RemindersForNoteFamily._allTransitiveDependencies,
          noteId: noteId,
        );

  RemindersForNoteProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.noteId,
  }) : super.internal();

  final int noteId;

  @override
  Override overrideWith(
    Stream<List<Reminder>> Function(RemindersForNoteRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RemindersForNoteProvider._internal(
        (ref) => create(ref as RemindersForNoteRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        noteId: noteId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Reminder>> createElement() {
    return _RemindersForNoteProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RemindersForNoteProvider && other.noteId == noteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, noteId.hashCode);
    return _SystemHash.finish(hash);
  }
}

mixin RemindersForNoteRef on AutoDisposeStreamProviderRef<List<Reminder>> {
  /// The parameter `noteId` of this provider.
  int get noteId;
}

class _RemindersForNoteProviderElement
    extends AutoDisposeStreamProviderElement<List<Reminder>>
    with RemindersForNoteRef {
  _RemindersForNoteProviderElement(super.provider);

  @override
  int get noteId => (origin as RemindersForNoteProvider).noteId;
}

String _$pendingRemindersHash() => r'pendingReminders_generated_hash_v1';

/// See also [pendingReminders].
@ProviderFor(pendingReminders)
final pendingRemindersProvider =
    AutoDisposeStreamProvider<List<Reminder>>.internal(
  pendingReminders,
  name: r'pendingRemindersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingRemindersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PendingRemindersRef = AutoDisposeStreamProviderRef<List<Reminder>>;

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
