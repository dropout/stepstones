import 'package:admin_chants/src/domain/entity/picked_chant_file_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';

abstract interface class ChantFilePicker {
  /// Lets the user choose a file for [type]; null when cancelled.
  Future<PickedChantFileEntity?> pick(ChantAssetType type);
}
