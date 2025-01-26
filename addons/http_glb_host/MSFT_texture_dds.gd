# Copyright (c) 2025-present. This file is part of V-Sekai https://v-sekai.org/.
# K. S. Ernest (Fire) Lee & Contributors
# MSFT_texture_dds.gd
# SPDX-License-Identifier: MIT

extends GLTFDocumentExtension

func _import_preflight(state: GLTFState, extensions: PackedStringArray) -> Error:
	var test_image: Image = Image.new()
	if not test_image.has_method("save_dds_from_buffer"):
		return ERR_SKIP;
	if not test_image.has_method("save_dds"):
		return ERR_SKIP;
	if !extensions.has("MSFT_texture_dds"):
		return ERR_SKIP;
	return OK;

func _get_supported_extensions() -> PackedStringArray:
	return ["MSFT_texture_dds"]

func _parse_image_data(state: GLTFState, image_data: PackedByteArray, mime_type: String, ret_image: Image) -> Error:
	if mime_type == "image/vnd-ms.dds":
		return ret_image.load_dds_from_buffer(image_data)
	return OK

func _parse_texture_json(stat, texture_json, gltf_texture: GLTFTexture) -> Error:
	if !texture_json.has("extensions"):
		return OK;
	var extensions: Dictionary = texture_json["extensions"];
	if !extensions.has("MSFT_texture_dds"):
		return OK
	var texture_dds: Dictionary = extensions["MSFT_texture_dds"];
	if !texture_dds.has("source"):
		return ERR_PARSE_ERROR
	gltf_texture.src_image = texture_dds["source"]
	return OK;

func  _get_saveable_image_formats() ->  PackedStringArray:
	return ["DDS"]
	
func _serialize_image_to_bytes(state: GLTFState, image: Image, image_dict: Dictionary, image_format: String, lossy_quality: float) -> PackedByteArray:
	if image_format == "DDS":
		image_dict["mimeType"] = "image/vnd-ms.dds"
		if not image.has_mipmaps():
			image.generate_mipmaps()
		if not image.is_compressed():
			image.compress_from_channels(Image.COMPRESS_S3TC, Image.USED_CHANNELS_RGBA)
		return image.call("save_dds_to_buffer")
	return PackedByteArray()

func _save_image_at_path(state: GLTFState, image: Image, file_path: String, image_format: String, _lossy_quality: float) -> Error:
	if image_format == "DDS":
		if not image.has_mipmaps():
			image.generate_mipmaps()
		if not image.is_compressed():
			image.compress_from_channels(Image.COMPRESS_S3TC, Image.USED_CHANNELS_RGBA)
		return image.call("save_dds", file_path)
		
	return ERR_INVALID_PARAMETER

func _serialize_texture_json(state: GLTFState, texture_json: Dictionary, gltf_texture: GLTFTexture, image_format: String) -> Error:
	var MSFT_texture_dds: Dictionary 
	MSFT_texture_dds["source"] = gltf_texture.get_src_image();
	var texture_extensions : Dictionary
	texture_extensions["MSFT_texture_dds"] = MSFT_texture_dds
	texture_json["extensions"] = texture_extensions;
	state.add_used_extension("MSFT_texture_dds", true);
	return OK;
