# Copyright (c) 2025-present. This file is part of V-Sekai https://v-sekai.org/.
# K. S. Ernest (Fire) Lee & Contributors
# EXT_voyage_exporter.gd
# SPDX-License-Identifier: MIT

extends GLTFDocumentExtension

func _import_preflight(state: GLTFState, extensions: PackedStringArray) -> Error:
	if !extensions.has("EXT_voyage_exporter"):
		return ERR_SKIP;
	return OK;
	
func _get_supported_extensions() -> PackedStringArray:
	return ["EXT_voyage_exporter"]

func _parse_image_data(state: GLTFState, image_data: PackedByteArray, mime_type: String, ret_image: Image) -> Error:
	if mime_type == "image/vnd-ms.dds":
		return ret_image.load_dds_from_buffer(image_data)
	return OK

func _parse_texture_json(stat, texture_json, gltf_texture: GLTFTexture) -> Error:
	if !texture_json.has("extensions"):
		return OK;
	var extensions: Dictionary = texture_json["extensions"];
	if !extensions.has("EXT_voyage_exporter"):
		return OK
	var texture_dds: Dictionary = extensions["EXT_voyage_exporter"];
	if !texture_dds.has("source"):
		return ERR_PARSE_ERROR
	gltf_texture.src_image = texture_dds["source"]
	return OK;

func  _get_saveable_image_formats() ->  PackedStringArray:
	return ["DDS"]
	
func _serialize_image_to_bytes(state: GLTFState, image: Image, image_dict: Dictionary, image_format: String, lossy_quality: float) -> PackedByteArray:
	if image_format == "DDS":
		if image.is_compressed():
			image.decompress()
		var width = image.get_width()
		var height = image.get_height()
		var new_width = 1
		while new_width < width:
			new_width *= 2
		var new_height = 1
		while new_height < height:
			new_height *= 2
		if width != new_width or height != new_height:
			image.resize(new_width, new_height, Image.INTERPOLATE_LANCZOS)
		if not image.is_compressed():
			image.compress_from_channels(Image.COMPRESS_S3TC, Image.USED_CHANNELS_RGBA)
		image_dict["mimeType"] = "image/vnd-ms.dds"
		var format: String
		match image.get_format():
					Image.FORMAT_DXT1:
						format = "DXT1"
					Image.FORMAT_DXT3:
						format = "DXT3"
					Image.FORMAT_DXT5:
						format = "DXT5"
					Image.FORMAT_BPTC_RGBA:
						format = "BC7"
					_:
						return PackedByteArray()
		image_dict["extensions"] = {
			"EXT_voyage_exporter": {
				"width": image.get_width(),
				"height": image.get_height(),
				"format": format
			}
		}
		return image.save_dds_to_buffer()
	return PackedByteArray()

func _save_image_at_path(state: GLTFState, image: Image, file_path: String, image_format: String, _lossy_quality: float) -> Error:
	if image_format == "DDS":
		if not image.is_compressed():
			image.compress_from_channels(Image.COMPRESS_S3TC, Image.USED_CHANNELS_RGBA)
		return image.save_dds(file_path)
	return ERR_INVALID_PARAMETER

func _serialize_texture_json(state: GLTFState, texture_json: Dictionary, gltf_texture: GLTFTexture, image_format: String) -> Error:
	var EXT_voyage_exporter: Dictionary 
	EXT_voyage_exporter["source"] = gltf_texture.get_src_image();
	var texture_extensions : Dictionary
	texture_extensions["EXT_voyage_exporter"] = EXT_voyage_exporter
	texture_json["extensions"] = texture_extensions;
	state.add_used_extension("EXT_voyage_exporter", true);
	return OK;
