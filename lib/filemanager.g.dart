// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filemanager.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileModel _$FileModelFromJson(Map<String, dynamic> json) {
  return FileModel(
    json['name'] as String,
    json['size'] as int,
  );
}

Map<String, dynamic> _$FileModelToJson(FileModel instance) => <String, dynamic>{
      'name': instance.name,
      'size': instance.size,
    };

FolderModel _$FolderModelFromJson(Map<String, dynamic> json) {
  return FolderModel(
    json['fullPath'] as String,
    json['name'] as String,
    (json['folders'] as List)
        .map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    (json['files'] as List)
        .map((e) => FileModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$FolderModelToJson(FolderModel instance) =>
    <String, dynamic>{
      'fullPath': instance.fullPath,
      'name': instance.name,
      'folders': instance.folders,
      'files': instance.files,
    };
