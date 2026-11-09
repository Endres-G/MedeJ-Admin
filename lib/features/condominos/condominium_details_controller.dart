import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamento_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';
import 'package:mede_ja_admin/features/auth/account_role_datasrc.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_repo.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_repo.dart';
import 'package:mede_ja_admin/features/dashboard/dashboard_controller.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';
import 'package:mede_ja_admin/features/users/user_provisioning_datasrc.dart';
import 'package:mede_ja_admin/features/users/user_repo.dart';

/// Compara strings de forma natural (ex.: "Bloco 2" < "Bloco 10", "102" < "1001").
int naturalCompare(String a, String b) {
  final tokenRegex = RegExp(r'(\d+|\D+)');
  final aParts = tokenRegex
      .allMatches(a.trim().toLowerCase())
      .map((m) => m.group(0)!)
      .toList();
  final bParts = tokenRegex
      .allMatches(b.trim().toLowerCase())
      .map((m) => m.group(0)!)
      .toList();

  final minLen = aParts.length < bParts.length ? aParts.length : bParts.length;

  for (var i = 0; i < minLen; i++) {
    final aToken = aParts[i];
    final bToken = bParts[i];
    if (aToken == bToken) continue;

    final aNum = int.tryParse(aToken);
    final bNum = int.tryParse(bToken);

    if (aNum != null && bNum != null) {
      final cmp = aNum.compareTo(bNum);
      if (cmp != 0) return cmp;
    }

    final cmp = aToken.compareTo(bToken);
    if (cmp != 0) return cmp;
  }

  return aParts.length.compareTo(bParts.length);
}

enum ApartmentNumberingPattern {
  hundreds,
  tens,
  sequential,
}

List<String> generateBulkApartmentNumbers({
  required int floors,
  required int apartmentsPerFloor,
  required int firstNumber,
  ApartmentNumberingPattern pattern = ApartmentNumberingPattern.hundreds,
}) {
  if (floors <= 0 || apartmentsPerFloor <= 0 || firstNumber < 0) {
    return const [];
  }

  final generated = <String>[];

  switch (pattern) {
    case ApartmentNumberingPattern.hundreds:
      for (var floor = 0; floor < floors; floor++) {
        final floorBase = firstNumber + (floor * 100);
        for (var unit = 0; unit < apartmentsPerFloor; unit++) {
          generated.add('${floorBase + unit}');
        }
      }
      break;
    case ApartmentNumberingPattern.tens:
      for (var floor = 0; floor < floors; floor++) {
        final floorBase = firstNumber + (floor * 10);
        for (var unit = 0; unit < apartmentsPerFloor; unit++) {
          generated.add('${floorBase + unit}');
        }
      }
      break;
    case ApartmentNumberingPattern.sequential:
      final total = floors * apartmentsPerFloor;
      for (var index = 0; index < total; index++) {
        generated.add('${firstNumber + index}');
      }
      break;
  }

  return generated;
}

enum BlockNamingSequence {
  letters,
  numbers,
}

List<String> generateBulkBlockNames({
  required String prefix,
  required int count,
  BlockNamingSequence sequence = BlockNamingSequence.letters,
  int startIndex = 1,
}) {
  if (count <= 0) return const [];
  final cleanPrefix = prefix.trim();
  final names = <String>[];

  for (var i = 0; i < count; i++) {
    final suffix = sequence == BlockNamingSequence.letters
        ? _indexToLetters(i + (startIndex > 0 ? startIndex - 1 : 0))
        : '${startIndex + i}';

    names.add(cleanPrefix.isEmpty ? suffix : '$cleanPrefix $suffix');
  }

  return names;
}

String _indexToLetters(int zeroBasedIndex) {
  var n = zeroBasedIndex;
  var result = '';
  while (n >= 0) {
    result = String.fromCharCode(65 + (n % 26)) + result;
    n = (n ~/ 26) - 1;
  }
  return result;
}

@immutable
class CondominiumScope {
  final String condominiumId;
  final String? administratorId;

  const CondominiumScope({
    required this.condominiumId,
    String? administratorId,
  }) : administratorId = (administratorId == null || administratorId == '')
           ? null
           : administratorId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CondominiumScope &&
        other.condominiumId == condominiumId &&
        (other.administratorId?.trim() ?? '') ==
            (administratorId?.trim() ?? '');
  }

  @override
  int get hashCode =>
      Object.hash(condominiumId, administratorId?.trim() ?? '');
}

final condominiumDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<CondominiumDetailsController, CondominiumDetailsState, CondominiumScope>(
      (ref, scope) {
        final controller = CondominiumDetailsController(
          scope: scope,
          adminRepository: ref.watch(administratorRepositoryProvider),
          condominiumRepository: ref.watch(condominiumRepositoryProvider),
          blockRepository: ref.watch(blockRepositoryProvider),
          apartmentRepository: ref.watch(apartmentRepositoryProvider),
          userRepository: ref.watch(userRepositoryProvider),
          userAuthProvisioner: ref.watch(userAuthProvisionerProvider),
          accountRoleRepository: ref.watch(accountRoleRepositoryProvider),
          onParentCachesInvalidated: (adminId) {
            if (adminId.isNotEmpty) {
              ref.invalidate(adminDetailsControllerProvider(adminId));
            }
            ref.invalidate(dashboardControllerProvider);
          },
        );
        controller.load();
        return controller;
      },
    );

class BlockOverviewItem {
  final BlockModel block;
  final List<ApartmentModel> apartments;

  const BlockOverviewItem({
    required this.block,
    required this.apartments,
  });

  int get totalApartments => apartments.length;

  int get activeApartments => apartments.where((a) => a.active).length;

  int get inactiveApartments => totalApartments - activeApartments;

  BlockOverviewItem copyWith({
    BlockModel? block,
    List<ApartmentModel>? apartments,
  }) {
    return BlockOverviewItem(
      block: block ?? this.block,
      apartments: apartments ?? this.apartments,
    );
  }
}

class ApartmentWithBlockItem {
  final BlockModel block;
  final ApartmentModel apartment;

  const ApartmentWithBlockItem({
    required this.block,
    required this.apartment,
  });
}

class BatchCreationResult {
  final List<String> createdIds;
  final List<String> skippedDuplicates;

  const BatchCreationResult({
    required this.createdIds,
    this.skippedDuplicates = const [],
  });

  int get createdCount => createdIds.length;
  int get skippedCount => skippedDuplicates.length;
}

class CondominiumDetailsState {
  final bool isLoading;
  final bool isSaving;
  final String? resolvedAdministratorId;
  final AdministratorModel? administrator;
  final CondominiumModel? condominium;
  final List<BlockOverviewItem> blocks;
  final List<UserModel> users;
  final String? error;
  final String? actionError;

  const CondominiumDetailsState({
    this.isLoading = true,
    this.isSaving = false,
    this.resolvedAdministratorId,
    this.administrator,
    this.condominium,
    this.blocks = const [],
    this.users = const [],
    this.error,
    this.actionError,
  });

  int get totalBlocks => blocks.length;

  int get activeBlocks => blocks.where((b) => b.block.active).length;

  int get inactiveBlocks => totalBlocks - activeBlocks;

  int get blocksWithoutApartments =>
      blocks.where((b) => b.apartments.isEmpty).length;

  int get totalApartments =>
      blocks.fold(0, (sum, b) => sum + b.totalApartments);

  int get activeApartments =>
      blocks.fold(0, (sum, b) => sum + b.activeApartments);

  int get inactiveApartments => totalApartments - activeApartments;

  int get totalUsers => users.length;

  int get activeUsers => users.where((u) => u.active).length;

  int get inactiveUsers => totalUsers - activeUsers;

  int get pendingPasswordChangeUsers =>
      users.where((u) => u.mustChangePassword).length;

  List<ApartmentWithBlockItem> get allApartments {
    final items = <ApartmentWithBlockItem>[];
    for (final blockItem in blocks) {
      for (final apartment in blockItem.apartments) {
        items.add(
          ApartmentWithBlockItem(
            block: blockItem.block,
            apartment: apartment,
          ),
        );
      }
    }
    return items;
  }

  BlockOverviewItem? findBlock(String blockId) {
    for (final item in blocks) {
      if (item.block.id == blockId) {
        return item;
      }
    }
    return null;
  }

  List<String> get pendingSteps {
    final steps = <String>[];
    if (totalBlocks == 0) {
      steps.add('Blocos');
      steps.add('Apartamentos');
    } else if (totalApartments == 0 || blocksWithoutApartments > 0) {
      steps.add('Apartamentos');
    }

    if (totalUsers == 0) {
      steps.add('Contas');
    }

    return steps;
  }

  bool get isConfigurationComplete => pendingSteps.isEmpty;

  double get configurationProgress {
    var completed = 1; // Etapa 1: Informações (já criado)
    if (totalBlocks > 0) completed++;
    if (totalBlocks > 0 &&
        totalApartments > 0 &&
        blocksWithoutApartments == 0) {
      completed++;
    }
    if (totalUsers > 0) completed++;
    return completed / 4.0;
  }

  CondominiumDetailsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? resolvedAdministratorId,
    AdministratorModel? administrator,
    CondominiumModel? condominium,
    List<BlockOverviewItem>? blocks,
    List<UserModel>? users,
    String? error,
    bool clearError = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return CondominiumDetailsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      resolvedAdministratorId:
          resolvedAdministratorId ?? this.resolvedAdministratorId,
      administrator: administrator ?? this.administrator,
      condominium: condominium ?? this.condominium,
      blocks: blocks ?? this.blocks,
      users: users ?? this.users,
      error: clearError ? null : (error ?? this.error),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}

class CondominiumDetailsController
    extends StateNotifier<CondominiumDetailsState> {
  final CondominiumScope scope;
  final AdministratorRepository _adminRepository;
  final CondominiumRepository _condominiumRepository;
  final BlockRepository _blockRepository;
  final ApartmentRepository _apartmentRepository;
  final UserRepository _userRepository;
  final UserAuthProvisioner _userAuthProvisioner;
  final AccountRoleRepository? _accountRoleRepository;
  final void Function(String administratorId)? _onParentCachesInvalidated;

  CondominiumDetailsController({
    required this.scope,
    required AdministratorRepository adminRepository,
    required CondominiumRepository condominiumRepository,
    required BlockRepository blockRepository,
    required ApartmentRepository apartmentRepository,
    required UserRepository userRepository,
    UserAuthProvisioner? userAuthProvisioner,
    AccountRoleRepository? accountRoleRepository,
    void Function(String administratorId)? onParentCachesInvalidated,
  }) : _adminRepository = adminRepository,
       _condominiumRepository = condominiumRepository,
       _blockRepository = blockRepository,
       _apartmentRepository = apartmentRepository,
       _userRepository = userRepository,
       _userAuthProvisioner =
           userAuthProvisioner ?? FirebaseUserAuthProvisioner(),
       _accountRoleRepository = accountRoleRepository,
       _onParentCachesInvalidated = onParentCachesInvalidated,
       super(
         CondominiumDetailsState(
           resolvedAdministratorId: scope.administratorId?.trim(),
         ),
       );

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearActionError: true,
    );

    try {
      var adminId =
          state.resolvedAdministratorId ?? scope.administratorId?.trim() ?? '';
      AdministratorModel? administrator;
      CondominiumModel? condominium;

      if (adminId.isNotEmpty) {
        final results = await Future.wait<Object?>([
          _adminRepository
              .getAdministrator(adminId)
              .then<Object?>((v) => v)
              .catchError((_) => null),
          _condominiumRepository.getCondominium(adminId, scope.condominiumId),
        ]);
        administrator = results[0] as AdministratorModel?;
        condominium = results[1] as CondominiumModel;
      } else {
        // Caso a rota tenha sido acessada diretamente sem ?administratorId=
        final allAdmins = await _adminRepository.getAdministrators();
        for (final candidate in allAdmins) {
          final condos = await _condominiumRepository
              .getCondominiumsByAdministrator(candidate.id);
          final match = condos
              .where((c) => c.id == scope.condominiumId)
              .toList();
          if (match.isNotEmpty) {
            adminId = candidate.id;
            administrator = candidate;
            condominium = match.first;
            break;
          }
        }

        if (condominium == null || adminId.isEmpty) {
          throw Exception('Condomínio não encontrado.');
        }
      }

      final blocksFuture = _blockRepository.getBlocks(
        adminId,
        scope.condominiumId,
      );
      final usersFuture = _userRepository.getUsers(
        adminId,
        scope.condominiumId,
      );

      final rawBlocks = await blocksFuture;
      final rawUsers = await usersFuture;

      final sortedBlocks = List<BlockModel>.of(rawBlocks)
        ..sort((a, b) => naturalCompare(a.name, b.name));

      final blockItems = await Future.wait(
        sortedBlocks.map((block) async {
          final rawApartments = await _apartmentRepository.getApartments(
            adminId,
            scope.condominiumId,
            block.id,
          );
          final sortedApartments = List<ApartmentModel>.of(rawApartments)
            ..sort((a, b) => naturalCompare(a.name, b.name));

          return BlockOverviewItem(block: block, apartments: sortedApartments);
        }),
      );

      final sortedUsers = List<UserModel>.of(rawUsers)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        resolvedAdministratorId: adminId,
        administrator: administrator,
        condominium: condominium,
        blocks: blockItems,
        users: sortedUsers,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(isLoading: false, error: _formatError(e));
    }
  }

  Future<bool> updateCondominium({
    required String name,
    required String address,
  }) async {
    final adminId = state.resolvedAdministratorId;
    final current = state.condominium;
    if (adminId == null || adminId.isEmpty || current == null) return false;

    final updated = current.copyWith(
      name: name.trim(),
      address: address.trim(),
    );

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _condominiumRepository.updateCondominium(adminId, updated);
      _onParentCachesInvalidated?.call(adminId);

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        condominium: updated,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }



  Future<bool> toggleCondominiumActive() async {
    final adminId = state.resolvedAdministratorId;
    final current = state.condominium;
    if (adminId == null || adminId.isEmpty || current == null) return false;

    final updated = current.copyWith(active: !current.active);

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _condominiumRepository.updateCondominium(adminId, updated);
      _onParentCachesInvalidated?.call(adminId);

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        condominium: updated,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }

  Future<bool> moveToTrash() async {
    final adminId = state.resolvedAdministratorId;
    final current = state.condominium;
    if (adminId == null || adminId.isEmpty || current == null) return false;

    state = state.copyWith(isSaving: true, clearActionError: true);
    try {
      await _condominiumRepository.moveToTrash(adminId, current.id);
      _onParentCachesInvalidated?.call(adminId);
      if (!mounted) return true;
      state = state.copyWith(isSaving: false, clearActionError: true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }



  bool hasBlockWithName(String name, {String? ignoreBlockId}) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    return state.blocks.any(
      (item) =>
          item.block.id != ignoreBlockId &&
          item.block.name.trim().toLowerCase() == normalized,
    );
  }

  Future<String?> createBlock({
    required String name,
    bool active = true,
  }) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) {
      state = state.copyWith(
        actionError: 'Administradora do condomínio não identificada.',
      );
      return null;
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(actionError: 'Informe o nome do bloco.');
      return null;
    }

    if (hasBlockWithName(trimmed)) {
      state = state.copyWith(
        actionError: 'Já existe um bloco "$trimmed" neste condomínio.',
      );
      return null;
    }

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      final newBlock = BlockModel(id: '', name: trimmed, active: active);
      final createdId = await _blockRepository.createBlock(
        adminId,
        scope.condominiumId,
        newBlock,
      );

      final persisted = newBlock.copyWith(
        id: createdId,
        createdAt: DateTime.now(),
      );

      final updatedBlocks = [
        ...state.blocks,
        BlockOverviewItem(block: persisted, apartments: const []),
      ]..sort((a, b) => naturalCompare(a.block.name, b.block.name));

      _onParentCachesInvalidated?.call(adminId);

      if (!mounted) return createdId;

      state = state.copyWith(
        isSaving: false,
        blocks: updatedBlocks,
        clearActionError: true,
      );
      return createdId;
    } catch (e) {
      if (!mounted) return null;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return null;
    }
  }

  Future<BatchCreationResult?> createBlocksBatch({
    required List<String> names,
    bool active = true,
  }) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) {
      state = state.copyWith(
        actionError: 'Administradora do condomínio não identificada.',
      );
      return null;
    }

    final existingNames = state.blocks
        .map((b) => b.block.name.trim().toLowerCase())
        .toSet();
    final seenNew = <String>{};
    final modelsToCreate = <BlockModel>[];
    final skipped = <String>[];

    for (final raw in names) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final normalized = trimmed.toLowerCase();

      if (existingNames.contains(normalized) || seenNew.contains(normalized)) {
        skipped.add(trimmed);
      } else {
        seenNew.add(normalized);
        modelsToCreate.add(BlockModel(id: '', name: trimmed, active: active));
      }
    }

    if (modelsToCreate.isEmpty) {
      state = state.copyWith(
        actionError:
            'Todos os blocos informados já existem neste condomínio.',
      );
      return null;
    }

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      final createdIds = await _blockRepository.createBlocksBatch(
        adminId,
        scope.condominiumId,
        modelsToCreate,
      );

      final now = DateTime.now();
      final createdItems = <BlockOverviewItem>[];
      for (var i = 0; i < modelsToCreate.length; i++) {
        final id = i < createdIds.length ? createdIds[i] : 'blk-$i';
        createdItems.add(
          BlockOverviewItem(
            block: modelsToCreate[i].copyWith(id: id, createdAt: now),
            apartments: const [],
          ),
        );
      }

      final updatedBlocks = [...state.blocks, ...createdItems]
        ..sort((a, b) => naturalCompare(a.block.name, b.block.name));

      _onParentCachesInvalidated?.call(adminId);

      final result = BatchCreationResult(
        createdIds: createdIds,
        skippedDuplicates: skipped,
      );

      if (!mounted) return result;

      state = state.copyWith(
        isSaving: false,
        blocks: updatedBlocks,
        clearActionError: true,
      );
      return result;
    } catch (e) {
      if (!mounted) return null;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return null;
    }
  }

  Future<bool> updateBlock({
    required BlockModel block,
    required String name,
  }) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) return false;

    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    if (hasBlockWithName(trimmed, ignoreBlockId: block.id)) {
      state = state.copyWith(
        actionError: 'Já existe outro bloco com o nome "$trimmed".',
      );
      return false;
    }

    final updatedBlock = block.copyWith(name: trimmed);
    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _blockRepository.updateBlock(
        adminId,
        scope.condominiumId,
        updatedBlock,
      );

      final updatedBlocks = state.blocks
          .map(
            (item) => item.block.id == block.id
                ? item.copyWith(block: updatedBlock)
                : item,
          )
          .toList()
        ..sort((a, b) => naturalCompare(a.block.name, b.block.name));

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        blocks: updatedBlocks,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }



  Future<bool> toggleBlockActive(BlockModel block) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) return false;

    final updatedBlock = block.copyWith(active: !block.active);
    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _blockRepository.updateBlock(
        adminId,
        scope.condominiumId,
        updatedBlock,
      );

      final updatedBlocks = state.blocks
          .map(
            (item) => item.block.id == block.id
                ? item.copyWith(block: updatedBlock)
                : item,
          )
          .toList();

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        blocks: updatedBlocks,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }



  bool hasApartmentInBlock(
    String blockId,
    String name, {
    String? ignoreApartmentId,
  }) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final blockItem = state.findBlock(blockId);
    if (blockItem == null) return false;

    return blockItem.apartments.any(
      (apt) =>
          apt.id != ignoreApartmentId &&
          apt.name.trim().toLowerCase() == normalized,
    );
  }

  Future<String?> createApartment({
    required String blockId,
    required String name,
    bool active = true,
  }) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) {
      state = state.copyWith(
        actionError: 'Administradora do condomínio não identificada.',
      );
      return null;
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(actionError: 'Informe o número/nome do apartamento.');
      return null;
    }

    if (state.findBlock(blockId) == null) {
      state = state.copyWith(actionError: 'Selecione um bloco válido.');
      return null;
    }

    if (hasApartmentInBlock(blockId, trimmed)) {
      state = state.copyWith(
        actionError: 'O apartamento "$trimmed" já está cadastrado neste bloco.',
      );
      return null;
    }

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      final newApartment = ApartmentModel(id: '', name: trimmed, active: active);
      final createdId = await _apartmentRepository.createApartment(
        adminId,
        scope.condominiumId,
        blockId,
        newApartment,
      );

      final persisted = newApartment.copyWith(
        id: createdId,
        createdAt: DateTime.now(),
      );

      final updatedBlocks = state.blocks.map((item) {
        if (item.block.id != blockId) return item;
        final updatedApartments = [...item.apartments, persisted]
          ..sort((a, b) => naturalCompare(a.name, b.name));
        return item.copyWith(apartments: updatedApartments);
      }).toList();

      _onParentCachesInvalidated?.call(adminId);

      if (!mounted) return createdId;

      state = state.copyWith(
        isSaving: false,
        blocks: updatedBlocks,
        clearActionError: true,
      );
      return createdId;
    } catch (e) {
      if (!mounted) return null;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return null;
    }
  }

  Future<BatchCreationResult?> createApartmentsBatch({
    required String blockId,
    required List<String> names,
    bool active = true,
  }) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) {
      state = state.copyWith(
        actionError: 'Administradora do condomínio não identificada.',
      );
      return null;
    }

    final blockItem = state.findBlock(blockId);
    if (blockItem == null) {
      state = state.copyWith(actionError: 'Selecione um bloco válido.');
      return null;
    }

    final existingNames = blockItem.apartments
        .map((a) => a.name.trim().toLowerCase())
        .toSet();
    final seenNew = <String>{};
    final modelsToCreate = <ApartmentModel>[];
    final skipped = <String>[];

    for (final raw in names) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final normalized = trimmed.toLowerCase();

      if (existingNames.contains(normalized) || seenNew.contains(normalized)) {
        skipped.add(trimmed);
      } else {
        seenNew.add(normalized);
        modelsToCreate.add(
          ApartmentModel(id: '', name: trimmed, active: active),
        );
      }
    }

    if (modelsToCreate.isEmpty) {
      state = state.copyWith(
        actionError:
            'Todos os apartamentos gerados já estão cadastrados neste bloco.',
      );
      return null;
    }

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      final createdIds = await _apartmentRepository.createApartmentsBatch(
        adminId,
        scope.condominiumId,
        blockId,
        modelsToCreate,
      );

      final now = DateTime.now();
      final createdModels = <ApartmentModel>[];
      for (var i = 0; i < modelsToCreate.length; i++) {
        final id = i < createdIds.length ? createdIds[i] : 'apt-$i';
        createdModels.add(
          modelsToCreate[i].copyWith(id: id, createdAt: now),
        );
      }

      final updatedBlocks = state.blocks.map((item) {
        if (item.block.id != blockId) return item;
        final updatedApartments = [...item.apartments, ...createdModels]
          ..sort((a, b) => naturalCompare(a.name, b.name));
        return item.copyWith(apartments: updatedApartments);
      }).toList();

      _onParentCachesInvalidated?.call(adminId);

      final result = BatchCreationResult(
        createdIds: createdIds,
        skippedDuplicates: skipped,
      );

      if (!mounted) return result;

      state = state.copyWith(
        isSaving: false,
        blocks: updatedBlocks,
        clearActionError: true,
      );
      return result;
    } catch (e) {
      if (!mounted) return null;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return null;
    }
  }

  Future<bool> updateApartment({
    required String blockId,
    required ApartmentModel apartment,
    required String name,
  }) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) return false;

    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    if (hasApartmentInBlock(
      blockId,
      trimmed,
      ignoreApartmentId: apartment.id,
    )) {
      state = state.copyWith(
        actionError: 'Já existe outro apartamento "$trimmed" neste bloco.',
      );
      return false;
    }

    final updatedApartment = apartment.copyWith(name: trimmed);
    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _apartmentRepository.updateApartment(
        adminId,
        scope.condominiumId,
        blockId,
        updatedApartment,
      );

      final updatedBlocks = state.blocks.map((item) {
        if (item.block.id != blockId) return item;
        final updatedApartments = item.apartments
            .map((a) => a.id == apartment.id ? updatedApartment : a)
            .toList()
          ..sort((a, b) => naturalCompare(a.name, b.name));
        return item.copyWith(apartments: updatedApartments);
      }).toList();

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        blocks: updatedBlocks,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }



  Future<bool> toggleApartmentActive({
    required String blockId,
    required ApartmentModel apartment,
  }) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) return false;

    final updatedApartment = apartment.copyWith(active: !apartment.active);
    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _apartmentRepository.updateApartment(
        adminId,
        scope.condominiumId,
        blockId,
        updatedApartment,
      );

      final updatedBlocks = state.blocks.map((item) {
        if (item.block.id != blockId) return item;
        final updatedApartments = item.apartments
            .map((a) => a.id == apartment.id ? updatedApartment : a)
            .toList();
        return item.copyWith(apartments: updatedApartments);
      }).toList();

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        blocks: updatedBlocks,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }



  bool hasUserWithEmail(String email, {String? ignoreUserId}) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    return state.users.any(
      (user) =>
          user.id != ignoreUserId &&
          user.email.trim().toLowerCase() == normalized,
    );
  }

  Future<ProvisionedUserCredentials?> provisionCondominiumUser({
    required String name,
    required String email,
    required String temporaryPassword,
    UserRole role = UserRole.user,
    String? apartmentId,
    bool active = true,
  }) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) {
      state = state.copyWith(
        actionError: 'Administradora do condomínio não identificada.',
      );
      return null;
    }

    final trimmedName = name.trim();
    if (trimmedName.length < 3) {
      state = state.copyWith(
        actionError: 'Informe o nome completo (mínimo de 3 caracteres).',
      );
      return null;
    }

    final normalizedEmail = email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(normalizedEmail)) {
      state = state.copyWith(actionError: 'Informe um e-mail válido.');
      return null;
    }

    if (hasUserWithEmail(normalizedEmail)) {
      state = state.copyWith(
        actionError:
            'Já existe uma conta cadastrada com este e-mail neste condomínio.',
      );
      return null;
    }

    final passwordValidation = validateTemporaryPassword(temporaryPassword);
    if (passwordValidation != null) {
      state = state.copyWith(actionError: passwordValidation);
      return null;
    }

    final cleanApartmentId =
        (apartmentId == null || apartmentId.trim().isEmpty)
        ? null
        : apartmentId.trim();

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      final persistedUser = await _userAuthProvisioner.provisionAndPersist<UserModel>(
        name: trimmedName,
        email: normalizedEmail,
        temporaryPassword: temporaryPassword,
        persistUser: (authUid) async {
          final modelToSave = UserModel(
            id: authUid,
            name: trimmedName,
            email: normalizedEmail,
            apartmentId: cleanApartmentId,
            active: active,
            role: role,
            mustChangePassword: true,
            temporaryPassword: temporaryPassword,
          );
          await _userRepository.saveUserWithId(
            adminId,
            scope.condominiumId,
            authUid,
            modelToSave,
          );
          await _accountRoleRepository?.saveAccountRole(
            AccountRoleProfile(
              uid: authUid,
              name: trimmedName,
              email: normalizedEmail,
              role: role,
              active: active,
              mustChangePassword: true,
              temporaryPassword: temporaryPassword,
              administratorId: adminId,
              condominiumId: scope.condominiumId,
            ),
            isNew: true,
          );
          return modelToSave.copyWith(createdAt: DateTime.now());
        },
      );

      final updatedUsers = [...state.users, persistedUser]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      _onParentCachesInvalidated?.call(adminId);

      final credentials = ProvisionedUserCredentials(
        user: persistedUser,
        temporaryPassword: temporaryPassword,
        condominiumId: scope.condominiumId,
        condominiumName: state.condominium?.name ?? 'Condomínio',
        administratorName: state.administrator?.name,
      );

      if (!mounted) return credentials;

      state = state.copyWith(
        isSaving: false,
        users: updatedUsers,
        clearActionError: true,
      );
      return credentials;
    } catch (e) {
      if (!mounted) return null;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return null;
    }
  }

  Future<bool> updateCondominiumUser({
    required UserModel user,
    required String name,
    UserRole? role,
    String? apartmentId,
    bool clearApartmentId = false,
  }) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) return false;

    final trimmedName = name.trim();
    if (trimmedName.length < 3) {
      state = state.copyWith(
        actionError: 'Informe um nome válido (mínimo de 3 caracteres).',
      );
      return false;
    }

    final cleanApartmentId =
        (apartmentId == null || apartmentId.trim().isEmpty)
        ? null
        : apartmentId.trim();

    final updatedUser = user.copyWith(
      name: trimmedName,
      role: role ?? user.role,
      apartmentId: cleanApartmentId,
      clearApartmentId: clearApartmentId || cleanApartmentId == null,
    );

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _userRepository.updateUser(
        adminId,
        scope.condominiumId,
        updatedUser,
      );
      await _accountRoleRepository?.saveAccountRole(
        AccountRoleProfile(
          uid: updatedUser.id,
          name: updatedUser.name,
          email: updatedUser.email,
          role: updatedUser.role,
          active: updatedUser.active,
          mustChangePassword: updatedUser.mustChangePassword,
          administratorId: adminId,
          condominiumId: scope.condominiumId,
        ),
      );

      final updatedUsers = state.users
          .map((item) => item.id == user.id ? updatedUser : item)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        users: updatedUsers,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }



  Future<bool> toggleCondominiumUserActive(UserModel user) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) return false;

    final updatedUser = user.copyWith(active: !user.active);
    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _userRepository.updateUser(
        adminId,
        scope.condominiumId,
        updatedUser,
      );
      await _accountRoleRepository?.saveAccountRole(
        AccountRoleProfile(
          uid: updatedUser.id,
          name: updatedUser.name,
          email: updatedUser.email,
          role: updatedUser.role,
          active: updatedUser.active,
          mustChangePassword: updatedUser.mustChangePassword,
          administratorId: adminId,
          condominiumId: scope.condominiumId,
        ),
      );

      final updatedUsers = state.users
          .map((item) => item.id == user.id ? updatedUser : item)
          .toList();

      _onParentCachesInvalidated?.call(adminId);

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        users: updatedUsers,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }



  Future<bool> sendUserPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return false;

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _userAuthProvisioner.sendPasswordResetEmail(normalizedEmail);
      if (!mounted) return true;

      state = state.copyWith(isSaving: false, clearActionError: true);
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }



  /// Vincula uma conta existente (ex.: conta global/sem condomínio) a este condomínio.
  Future<bool> linkExistingUser(AccountRoleProfile profile) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) {
      state = state.copyWith(
        actionError: 'Administradora do condomínio não identificada.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      final userToSave = UserModel(
        id: profile.uid,
        name: profile.name,
        email: profile.email,
        active: profile.active,
        role: profile.role,
        mustChangePassword: profile.mustChangePassword,
        temporaryPassword: profile.temporaryPassword,
        createdAt: profile.createdAt,
      );

      await _userRepository.saveUserWithId(
        adminId,
        scope.condominiumId,
        profile.uid,
        userToSave,
      );

      await _accountRoleRepository?.linkAccountRole(
        uid: profile.uid,
        administratorId: adminId,
        condominiumId: scope.condominiumId,
      );

      final updatedUsers = [
        ...state.users.where((u) => u.id != profile.uid),
        userToSave,
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      _onParentCachesInvalidated?.call(adminId);

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        users: updatedUsers,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }

  /// Desvincula o usuário deste condomínio, transformando-o em conta livre/avulsa.
  Future<bool> unlinkCondominiumUser(UserModel user) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) return false;

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _userRepository.deleteUser(adminId, scope.condominiumId, user.id);
      await _accountRoleRepository?.unlinkAccountRole(user.id);

      final updatedUsers = state.users.where((u) => u.id != user.id).toList();

      _onParentCachesInvalidated?.call(adminId);

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        users: updatedUsers,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }

  /// Regenera a senha temporária para primeiro acesso do usuário.
  Future<ProvisionedUserCredentials?> regenerateUserTemporaryPassword({
    required UserModel user,
    required String newTemporaryPassword,
  }) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) return null;

    final validation = validateTemporaryPassword(newTemporaryPassword);
    if (validation != null) {
      state = state.copyWith(actionError: validation);
      return null;
    }

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      final currentPwd = user.temporaryPassword;
      if (currentPwd != null && currentPwd.isNotEmpty) {
        try {
          await _userAuthProvisioner.updateTemporaryPassword(
            email: user.email,
            currentPassword: currentPwd,
            newPassword: newTemporaryPassword,
          );
        } catch (_) {}
      }

      final updatedUser = user.copyWith(
        mustChangePassword: true,
        temporaryPassword: newTemporaryPassword,
      );

      await _userRepository.updateUser(
        adminId,
        scope.condominiumId,
        updatedUser,
      );

      await _accountRoleRepository?.saveAccountRole(
        AccountRoleProfile(
          uid: updatedUser.id,
          name: updatedUser.name,
          email: updatedUser.email,
          role: updatedUser.role,
          active: updatedUser.active,
          mustChangePassword: true,
          temporaryPassword: newTemporaryPassword,
          administratorId: adminId,
          condominiumId: scope.condominiumId,
          createdAt: updatedUser.createdAt,
        ),
      );

      final updatedUsers = state.users
          .map((u) => u.id == user.id ? updatedUser : u)
          .toList();

      _onParentCachesInvalidated?.call(adminId);

      final credentials = ProvisionedUserCredentials(
        user: updatedUser,
        temporaryPassword: newTemporaryPassword,
        condominiumId: scope.condominiumId,
        condominiumName: state.condominium?.name ?? 'Condomínio',
        administratorName: state.administrator?.name,
      );

      if (!mounted) return credentials;

      state = state.copyWith(
        isSaving: false,
        users: updatedUsers,
        clearActionError: true,
      );
      return credentials;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return null;
    }
  }

  /// Move a conta de usuário do condomínio para a lixeira (Soft Delete).
  Future<bool> deleteCondominiumUser(UserModel user) async {
    final adminId = state.resolvedAdministratorId;
    if (adminId == null || adminId.isEmpty) return false;

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _userRepository.moveToTrash(adminId, scope.condominiumId, user.id);
      await _accountRoleRepository?.saveAccountRole(
        AccountRoleProfile(
          uid: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          active: false,
          mustChangePassword: user.mustChangePassword,
          administratorId: adminId,
          condominiumId: scope.condominiumId,
          temporaryPassword: user.temporaryPassword,
          createdAt: user.createdAt,
        ),
      );

      final updatedUsers = state.users.where((u) => u.id != user.id).toList();

      _onParentCachesInvalidated?.call(adminId);

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        users: updatedUsers,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }

  String _formatError(Object error) {
    return formatAuthAndFirestoreError(error);
  }
}
