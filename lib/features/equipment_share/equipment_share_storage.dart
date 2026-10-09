import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/storage/secure_storage_client.dart';
import 'package:prokat/features/equipment_share/equipment_share_booking_intent.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_overlay.dart';
import 'package:prokat/features/equipment_share/equipment_share_state.dart';
import 'package:uuid/uuid.dart';

final equipmentShareStorageProvider = Provider<EquipmentShareStorage>(
  (ref) => EquipmentShareStorage(),
);

class EquipmentShareStorage {
  EquipmentShareStorage({
    FlutterSecureStorage? storage,
    String Function()? newIntentId,
  }) : _storage = storage ?? SecureStorageClient.instance,
       _newIntentId = newIntentId ?? const Uuid().v4;

  final FlutterSecureStorage _storage;
  final String Function() _newIntentId;
  String get _stateKey => shareStorageKey('equipment_share_state');
  String get _epochKey => shareStorageKey('equipment_share_privacy_epoch');
  static const _legacyKeys = [
    'equipment_share_pending_uri',
    'equipment_share_accepted_open',
    'equipment_share_overlay',
    'equipment_share_booking_intent',
  ];
  Future<void> _queue = Future<void>.value();
  int _revision = 0;
  int _accountGeneration = 0;
  int? _overlayClaim;
  String? _effectClaim;
  bool _revoking = false;
  bool _quarantined = false;
  String _knownEpoch = '0';
  bool _referrerChecked = false;

  int get accountGeneration => _accountGeneration;
  int get revision => _revision;

  Future<T> _op<T>(Future<T> Function() operation) {
    final run = _queue.then((_) => operation());
    _queue = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  Future<String> _epoch() async {
    try {
      return _knownEpoch = await readSharePrivacyEpoch(_storage);
    } on FormatException {
      final epoch =
          '${sharePrivacyRevision(_knownEpoch) + 1}:${_newIntentId()}';
      await _storage.write(key: _epochKey, value: epoch);
      return _knownEpoch = epoch;
    }
  }

  Future<void> _write(EquipmentShareState state) async {
    final next = state.copyWith(
      installReferrerChecked: state.installReferrerChecked || _referrerChecked,
    );
    await _storage.write(key: _stateKey, value: next.encode());
    _referrerChecked = next.installReferrerChecked;
  }

  Future<void> _deleteLegacy() async {
    for (final key in _legacyKeys) {
      try {
        await _storage.delete(key: shareStorageKey(key));
      } catch (_) {}
    }
  }

  Future<bool> _revokeDurably(String epoch) async {
    var revoked = false;
    try {
      await _storage.write(key: _epochKey, value: epoch);
      revoked = true;
    } catch (_) {}
    try {
      await _write(EquipmentShareState(epoch: epoch));
      revoked = true;
    } catch (_) {
      try {
        await _storage.delete(key: _stateKey);
      } catch (_) {}
    }
    await _deleteLegacy();
    return revoked;
  }

  Future<EquipmentShareState> _read() async {
    final account = _accountGeneration;
    final epoch = await _epoch();
    if (_revoking || account != _accountGeneration) {
      return EquipmentShareState(epoch: epoch);
    }
    if (_quarantined) {
      final revokedEpoch =
          '${sharePrivacyRevision(_knownEpoch) + 1}:${_newIntentId()}';
      _knownEpoch = revokedEpoch;
      _quarantined = !await _revokeDurably(revokedEpoch);
      return EquipmentShareState(epoch: revokedEpoch);
    }
    final raw = await _storage.read(key: _stateKey);
    if (_revoking || account != _accountGeneration) {
      return EquipmentShareState(epoch: epoch);
    }
    if (raw != null) {
      final state = EquipmentShareState.tryParse(raw, epoch);
      if (state != null) {
        _referrerChecked = _referrerChecked || state.installReferrerChecked;
        return state;
      }
      final empty = EquipmentShareState(epoch: epoch);
      try {
        await _write(empty);
      } catch (_) {
        _quarantined = true;
      }
      await _deleteLegacy();
      return empty;
    }
    if (epoch != '0') return EquipmentShareState(epoch: epoch);
    return _migrateLegacy(epoch);
  }

  Future<EquipmentShareState> _migrateLegacy(String epoch) async {
    final account = _accountGeneration;
    final raw = <String?>[];
    for (final key in _legacyKeys) {
      raw.add(await _storage.read(key: shareStorageKey(key)));
    }
    if (_revoking || account != _accountGeneration) {
      return EquipmentShareState(epoch: epoch);
    }
    if (raw.every((value) => value == null)) {
      return EquipmentShareState(epoch: epoch);
    }
    final pending = raw[0] == null
        ? null
        : EquipmentShareOpen.tryParse(raw[0]!);
    final accepted = raw[1] == null
        ? null
        : EquipmentShareOpen.tryParse(raw[1]!);
    final overlay = raw[2] == null
        ? null
        : EquipmentShareOverlay.tryParse(raw[2]!);
    final intent = raw[3] == null
        ? null
        : EquipmentShareBookingIntent.tryParse(raw[3]!);
    final id = _newIntentId();
    EquipmentShareState state;
    if (raw[0] != null) {
      state = pending == null
          ? EquipmentShareState(epoch: epoch)
          : EquipmentShareState(
              epoch: epoch,
              intentId: id,
              open: pending.withEventId(id),
              pending: true,
              receivedAt: DateTime.now().toUtc(),
              installReferrerChecked:
                  pending.via == ShareOpenVia.installReferrer,
            );
    } else if (overlay != null) {
      // Old path-only overlays cannot prove which shareId produced them.
      state = EquipmentShareState(
        epoch: epoch,
        intentId: id,
        overlay: overlay,
        bookingIntent: intent?.equipmentId == overlay.equipmentId
            ? intent
            : null,
      );
    } else if (accepted?.link.equipmentId != null && intent == null) {
      state = EquipmentShareState(
        epoch: epoch,
        intentId: id,
        open: accepted!.withEventId(id),
        analyticsClaimed: true,
        receivedAt: DateTime.now().toUtc(),
        installReferrerChecked: accepted.via == ShareOpenVia.installReferrer,
      );
    } else {
      state = EquipmentShareState(
        epoch: epoch,
        intentId: intent == null ? null : id,
        bookingIntent: intent,
      );
    }
    await _write(state);
    await _deleteLegacy();
    return state;
  }

  Future<bool> savePendingOpen(
    EquipmentShareOpen open, {
    DateTime? receivedAt,
  }) {
    final token = ++_revision;
    final account = _accountGeneration;
    _effectClaim = null;
    return _op(() async {
      if (_revoking || token != _revision || account != _accountGeneration) {
        return false;
      }
      final previous = await _read();
      if (token != _revision ||
          account != _accountGeneration ||
          _revoking ||
          _quarantined) {
        return false;
      }
      final now = (receivedAt ?? DateTime.now()).toUtc();
      final same =
          previous.open?.link.uri == open.link.uri &&
          previous.open?.via == open.via;
      if (same &&
          (previous.actionable ||
              (previous.receivedAt != null &&
                  now.difference(previous.receivedAt!) >= Duration.zero &&
                  now.difference(previous.receivedAt!) <
                      const Duration(seconds: 2)))) {
        return false;
      }
      final id = _newIntentId();
      try {
        await _write(
          EquipmentShareState(
            epoch: previous.epoch,
            intentId: id,
            open: open.withEventId(id),
            pending: true,
            receivedAt: now,
            installReferrerChecked:
                previous.installReferrerChecked ||
                open.via == ShareOpenVia.installReferrer,
          ),
        );
      } catch (_) {
        _quarantined = true;
        try {
          await _write(EquipmentShareState(epoch: previous.epoch));
          _quarantined = false;
        } catch (_) {
          try {
            final epoch =
                '${sharePrivacyRevision(previous.epoch) + 1}:${_newIntentId()}';
            await _storage.write(key: _epochKey, value: epoch);
            _knownEpoch = epoch;
          } catch (_) {}
        }
        rethrow;
      }
      return token == _revision && account == _accountGeneration && !_revoking;
    });
  }

  Future<EquipmentShareOpen?> readPendingOpen() async =>
      (await readPendingSnapshot()).open;
  Future<({EquipmentShareOpen? open, int token})> readPendingSnapshot() {
    final token = _revision;
    return _op(() async {
      final state = await _read();
      return (open: state.pending ? state.open : null, token: token);
    });
  }

  Future<bool> hasRecoverableIntent() => _op(() async {
    final state = await _read();
    return state.actionable || state.openedPending;
  });

  Future<void> clearPendingUri() {
    ++_revision;
    return _op(() async {
      try {
        final state = await _read();
        if (state.pending) {
          await _write(EquipmentShareState(epoch: state.epoch));
        }
      } catch (_) {
        _quarantined = true;
      }
    });
  }

  Future<bool> clearPendingIfUnchanged(int token) => _op(() async {
    if (token != _revision) return false;
    final state = await _read();
    if (token != _revision || !state.pending) return false;
    await _write(EquipmentShareState(epoch: state.epoch));
    if (token != _revision) return false;
    ++_revision;
    return true;
  });

  Future<bool> completePendingIfUnchanged(int token, EquipmentShareOpen open) =>
      _op(() async {
        if (token != _revision || _revoking) return false;
        final state = await _read();
        final target = open.link.equipmentId;
        if (token != _revision ||
            !state.pending ||
            target == null ||
            state.open?.link.uri != open.link.uri ||
            state.open?.via != open.via ||
            (state.open?.link.equipmentId != null &&
                state.open?.link.equipmentId != target)) {
          return false;
        }
        await _write(
          EquipmentShareState(
            epoch: state.epoch,
            intentId: state.intentId,
            open: open.withEventId(state.intentId!),
            overlay: EquipmentShareOverlay(
              path: AppRoutes.equipmentSharePath(target),
              afterAuth: false,
            ),
            openedPending: true,
            receivedAt: state.receivedAt,
            installReferrerChecked: state.installReferrerChecked,
          ),
        );
        return token == _revision && !_revoking;
      });

  Future<EquipmentShareOpen?> readAcceptedOpen({
    required String equipmentId,
  }) async {
    try {
      return await _op(() async {
        final state = await _read();
        return !state.pending && state.open?.link.equipmentId == equipmentId
            ? state.open
            : null;
      });
    } catch (_) {
      return null;
    }
  }

  Future<({EquipmentShareOpen open, DateTime receivedAt})?>
  readAcceptedOpenContext({required String equipmentId}) async {
    try {
      return await _op(() async {
        final state = await _read();
        final open = state.open;
        final receivedAt = state.receivedAt;
        if (state.pending ||
            state.bookingAttributionConsumed ||
            open == null ||
            open.link.equipmentId != equipmentId ||
            receivedAt == null) {
          return null;
        }
        return (open: open, receivedAt: receivedAt);
      });
    } catch (_) {
      return null;
    }
  }

  Future<bool> consumeAcceptedBookingAttribution({
    required String equipmentId,
    required String shareId,
  }) => _op(() async {
    final state = await _read();
    final open = state.open;
    if (state.pending ||
        state.bookingAttributionConsumed ||
        open?.link.equipmentId != equipmentId ||
        open?.link.shareId != shareId) {
      return false;
    }
    await _write(state.copyWith(bookingAttributionConsumed: true));
    return true;
  });

  Future<void> clearAcceptedOpen() {
    ++_revision;
    return _op(() async {
      try {
        final state = await _read();
        await _write(EquipmentShareState(epoch: state.epoch));
      } catch (_) {
        _quarantined = true;
      }
    });
  }

  Future<void> saveBookingIntent(
    EquipmentShareBookingIntent intent, {
    bool afterAuth = false,
  }) {
    final token = afterAuth ? ++_revision : _revision;
    final account = _accountGeneration;
    return _op(() async {
      if (_revoking || account != _accountGeneration || token != _revision) {
        throw StateError('Share continuation superseded');
      }
      final state = await _read();
      if (_revoking ||
          account != _accountGeneration ||
          token != _revision ||
          _quarantined) {
        throw StateError('Share continuation superseded');
      }
      final target = state.open?.link.equipmentId ?? state.overlay?.equipmentId;
      if (state.pending || (target != null && target != intent.equipmentId)) {
        throw StateError('Share continuation superseded');
      }
      final next = state;
      await _write(
        EquipmentShareState(
          epoch: next.epoch,
          intentId: next.intentId ?? _newIntentId(),
          open: next.open,
          pending: next.pending,
          overlay: afterAuth
              ? EquipmentShareOverlay(
                  path: AppRoutes.equipmentSharePath(intent.equipmentId),
                  afterAuth: true,
                )
              : next.overlay,
          openedPending: next.openedPending,
          analyticsClaimed: next.analyticsClaimed,
          bookingAttributionConsumed: next.bookingAttributionConsumed,
          receivedAt: next.receivedAt,
          bookingIntent: intent,
          installReferrerChecked: next.installReferrerChecked,
        ),
      );
      if (afterAuth && (token != _revision || account != _accountGeneration)) {
        throw StateError('Share continuation superseded');
      }
    });
  }

  Future<EquipmentShareBookingIntent?> readBookingIntent() async {
    try {
      return await _op(() async => (await _read()).bookingIntent);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearBookingIntent() => _op(() async {
    try {
      final state = await _read();
      if (state.bookingIntent != null) {
        await _write(state.copyWith(clearBookingIntent: true));
      }
    } catch (_) {
      _quarantined = true;
    }
  });

  Future<void> saveOverlay(EquipmentShareOverlay overlay) {
    final token = ++_revision;
    final account = _accountGeneration;
    return _op(() async {
      if (token != _revision || account != _accountGeneration || _revoking) {
        return;
      }
      final state = await _read();
      if (token != _revision || state.pending || _revoking) return;
      final correlated = state.open?.link.equipmentId == overlay.equipmentId;
      await _write(
        correlated
            ? state.copyWith(overlay: overlay)
            : EquipmentShareState(
                epoch: state.epoch,
                intentId: _newIntentId(),
                overlay: overlay,
                bookingIntent:
                    state.bookingIntent?.equipmentId == overlay.equipmentId
                    ? state.bookingIntent
                    : null,
              ),
      );
    });
  }

  Future<({EquipmentShareOverlay? overlay, int token})> readOverlaySnapshot() {
    final token = _revision;
    return _op(() async {
      final state = await _read();
      return (overlay: !state.pending ? state.overlay : null, token: token);
    });
  }

  Future<bool> claimOverlayIfUnchanged(int token) => _op(() async {
    if (token != _revision || _overlayClaim == token || _revoking) return false;
    final state = await _read();
    if (token != _revision || state.pending || state.overlay == null) {
      return false;
    }
    _overlayClaim = token;
    return true;
  });
  void releaseOverlayClaim(int token) {
    if (_overlayClaim == token) _overlayClaim = null;
  }

  Future<bool> clearOverlayIfUnchanged(int token) => _op(() async {
    if (token != _revision || _revoking) return false;
    final state = await _read();
    if (token != _revision) return false;
    if (state.overlay != null) await _write(state.copyWith(clearOverlay: true));
    if (token != _revision) return false;
    ++_revision;
    _overlayClaim = null;
    return true;
  });

  Future<void> clearOverlay() {
    final token = ++_revision;
    return _op(() async {
      try {
        final state = await _read();
        if (token == _revision && state.overlay != null) {
          await _write(state.copyWith(clearOverlay: true));
        }
      } catch (_) {
        _quarantined = true;
      }
    });
  }

  Future<EquipmentShareOpen?> readOpenReceipt() => _op(() async {
    final state = await _read();
    return state.openedPending ? state.open : null;
  });
  Future<({bool analytics, int account})?> claimOpenReceipt(String id) =>
      _op(() async {
        if (_effectClaim == id || _revoking) return null;
        final state = await _read();
        if (state.intentId != id || !state.openedPending) return null;
        final account = _accountGeneration;
        if (!state.analyticsClaimed) {
          await _write(state.copyWith(analyticsClaimed: true));
        }
        if (account != _accountGeneration || _revoking) return null;
        _effectClaim = id;
        return (analytics: !state.analyticsClaimed, account: account);
      });
  bool receiptIsCurrent(String id, int account) =>
      !_revoking &&
      !_quarantined &&
      account == _accountGeneration &&
      _effectClaim == id;

  Future<void> finishOpenReceipt(
    String id,
    int account, {
    required bool delivered,
  }) => _op(() async {
    if (!receiptIsCurrent(id, account)) return;
    try {
      final state = await _read();
      if (state.intentId == id && delivered) {
        await _write(state.copyWith(openedPending: false));
      }
    } finally {
      if (_effectClaim == id) _effectClaim = null;
    }
  });

  /// Revoke before remote logout; queued old native writes precede the tombstone.
  Future<void> clearForLogout({bool holdFence = false}) {
    ++_accountGeneration;
    ++_revision;
    _revoking = true;
    _effectClaim = null;
    _overlayClaim = null;
    return _op(() async {
      try {
        _knownEpoch = await readSharePrivacyEpoch(_storage);
      } catch (_) {}
      final epoch =
          '${sharePrivacyRevision(_knownEpoch) + 1}:${_newIntentId()}';
      _knownEpoch = epoch;
      _quarantined = !await _revokeDurably(epoch);
      _revoking = holdFence;
    });
  }

  void finishLogout() => _revoking = false;

  Future<bool> wasInstallReferrerChecked() async {
    try {
      final legacy =
          await _storage.read(
            key: shareStorageKey('equipment_share_install_referrer_checked'),
          ) ==
          '1';
      if (legacy) _referrerChecked = true;
      return await _op(() async {
        final state = await _read();
        return legacy ||
            _referrerChecked ||
            state.installReferrerChecked ||
            state.epoch != '0';
      });
    } catch (_) {
      return false;
    }
  }

  Future<void> markInstallReferrerChecked() async {
    try {
      await _storage.write(
        key: shareStorageKey('equipment_share_install_referrer_checked'),
        value: '1',
      );
      _referrerChecked = true;
    } catch (_) {}
  }
}
