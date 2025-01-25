# Copyright (c) 2025-present. This file is part of V-Sekai https://v-sekai.org/.
# K. S. Ernest (Fire) Lee & Contributors
# MSFT_texture_dds.gd
# SPDX-License-Identifier: MIT

extends GLTFDocumentExtension

## This class implements the MSFT_texture_dds extension for GLTF documents.

func _save_image_at_path(state: GLTFState, image: Image, file_path: String, image_format: String, _lossy_quality: float) -> Error:
	if image_format == "image/vnd-ms.dds" and image and image.get_width() > 0 and image.get_height() > 0:
		var gltf: Dictionary = state.json
		if not gltf.has("extensionsUsed"):
			gltf["extensionsUsed"] = []
		if "MSFT_texture_dds" not in gltf["extensionsUsed"]:
			gltf["extensionsUsed"].append("MSFT_texture_dds")
		var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			var dds_data = load("image_to_dds.gd").new()._convert_image_to_dds(image, file_path)
			file.store_buffer(dds_data)
			file.close()
			return OK
		else:
			return ERR_CANT_OPEN
	return OK
