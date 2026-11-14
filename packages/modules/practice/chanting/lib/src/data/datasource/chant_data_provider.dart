import 'package:core/core.dart';
import 'package:chant_schema/chant_schema.dart';

abstract interface class ChantDataProvider
    implements DataProvider<ChantEntity> {
  Future<List<ChantEntity>> queryAll({bool preferCache});
  Stream<List<ChantEntity>> queryAllStream();
}
