import 'package:file_selector/file_selector.dart';

import 'package:admin_chants/src/domain/entity/picked_chant_file_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/service/chant_file_picker.dart';

class FileSelectorChantFilePicker implements ChantFilePicker {
  const FileSelectorChantFilePicker();

  @override
  Future<PickedChantFileEntity?> pick(ChantAssetType type) async {
    final file = await openFile(
      acceptedTypeGroups: [XTypeGroup(label: type.fileName, extensions: type.extensions)],
    );
    return file == null ? null : PickedChantFileEntity(path: file.path, name: file.name);
  }
}
