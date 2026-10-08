import 'package:mede_ja_admin/features/blocos/bloco_datasrc.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';

class BlockRepository {
  final BlockFirestoreDataSource _dataSource;

  BlockRepository({BlockFirestoreDataSource? dataSource})
    : _dataSource = dataSource ?? BlockFirestoreDataSource();

  Future<List<BlockModel>> getBlocks(
    String administratorId,
    String condominiumId,
  ) {
    return _dataSource.getBlocks(administratorId, condominiumId);
  }

  Future<BlockModel> getBlock(
    String administratorId,
    String condominiumId,
    String blockId,
  ) {
    return _dataSource.getBlock(administratorId, condominiumId, blockId);
  }

  Future<String> createBlock(
    String administratorId,
    String condominiumId,
    BlockModel block,
  ) {
    return _dataSource.createBlock(administratorId, condominiumId, block);
  }

  Future<void> updateBlock(
    String administratorId,
    String condominiumId,
    BlockModel block,
  ) {
    return _dataSource.updateBlock(administratorId, condominiumId, block);
  }

  Future<void> deleteBlock(
    String administratorId,
    String condominiumId,
    String blockId,
  ) {
    return _dataSource.deleteBlock(administratorId, condominiumId, blockId);
  }
}
