# Copyright (c) 2025-present. This file is part of V-Sekai https://v-sekai.org/.
# K. S. Ernest (Fire) Lee & Contributors
# http_glb_host.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var glb_data: PackedByteArray = PackedByteArray()
var http_server: TCPServer
const PORT = 8080

func _enter_tree():
	http_server = TCPServer.new()
	var err_http: Error = http_server.listen(PORT)
	if err_http != OK:
		push_error("HTTP Server start error: " + str(err_http))
		return

func _exit_tree():
	if not http_server:
		return
	http_server.stop()
	http_server = null

func _process(delta):
	if not http_server or not http_server.is_connection_available():
		return
	var http_client: StreamPeerTCP = http_server.take_connection()
	if not http_client:
		return
	var request: String
	if http_client.get_available_bytes() > 0:
		request = http_client.get_utf8_string(http_client.get_available_bytes()).strip_edges()
	else:
		http_client.disconnect_from_host()
		return
	if not request.begins_with("GET /"):
		var error_response = "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nInvalid request."
		http_client.put_data(error_response.to_utf8_buffer())
		http_client.disconnect_from_host()
		return
	var gltf_doc: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	var flags: int = 0 
	flags = flags | EditorSceneFormatImporter.IMPORT_USE_NAMED_SKIN_BINDS | EditorSceneFormatImporter.IMPORT_GENERATE_TANGENT_ARRAYS
	var error: Error = gltf_doc.append_from_scene(get_editor_interface().get_edited_scene_root(), state, flags)
	if error != OK:
		glb_data = PackedByteArray()
		push_error("GLTF export error: " + str(error))
	else:
		glb_data = gltf_doc.generate_buffer(state)
	
	if glb_data.size() > 0:
		var response: String = "HTTP/1.1 200 OK\r\nContent-Type: model/gltf-binary\r\nContent-Disposition: attachment; filename=\"model.glb\"\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % glb_data.size()
		http_client.put_data(response.to_utf8_buffer())
		http_client.put_data(glb_data)
	else:
		var error_response: String = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nGLB data not available."
		http_client.put_data(error_response.to_utf8_buffer())
	
	http_client.disconnect_from_host()
