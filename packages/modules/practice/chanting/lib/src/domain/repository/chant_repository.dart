import 'package:chant_schema/chant_schema.dart';
import 'package:core/core.dart';

abstract interface class ChantRepository
    implements CrudRepository<ChantEntity> {
  Future<List<ChantEntity>> queryAll({bool preferCache});
  Stream<List<ChantEntity>> queryAllStream();
}
