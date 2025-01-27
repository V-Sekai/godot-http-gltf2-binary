# Copyright (c) 2025-present. This file is part of V-Sekai https://v-sekai.org/.
# K. S. Ernest (Fire) Lee & Contributors
# http_glb_host.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var http_server: TCPServer
const PORT = 8080
const GET_DEBOUNCE_TIME = 5.0
var MSFT_texture_dds: GLTFDocumentExtension = null
var compatible: bool = false
var last_request_time: float = 0.0
var last_glb_data: PackedByteArray = PackedByteArray()

var csg_mesh: CSGMesh3D = null

func _enter_tree():
	csg_mesh = CSGMesh3D.new()
	MSFT_texture_dds = preload("res://addons/http_glb_host/MSFT_texture_dds.gd").new()
	GLTFDocument.register_gltf_document_extension(MSFT_texture_dds)
	print("MSFT_texture_dds extension loaded.")
	print(GLTFDocument.get_supported_gltf_extensions())
	http_server = TCPServer.new()
	var err_http: Error = http_server.listen(PORT)
	if err_http != OK:
		push_error("HTTP Server start error: " + str(err_http))
		return

func _exit_tree():
	if csg_mesh:
		csg_mesh.queue_free()
	if MSFT_texture_dds:
		GLTFDocument.unregister_gltf_document_extension(MSFT_texture_dds)
	if not http_server:
		return
	http_server.stop()
	http_server = null

func _process(delta):
	if http_server == null:
		return
	if not http_server.is_connection_available():
		return
	
	var http_client: StreamPeerTCP = http_server.take_connection()
	if http_client == null:
		return
	
	var request: String = ""
	if http_client.get_available_bytes() > 0:
		request = http_client.get_utf8_string(http_client.get_available_bytes()).strip_edges()
	else:
		http_client.disconnect_from_host()
		return
	
	if not request.begins_with("GET "):
		send_bad_request(http_client, "Invalid request.")
		return
	var path_end = request.find(" HTTP/")
	if path_end == -1:
		path_end = request.length()
	var full_path = request.substr(4, path_end - 4).strip_edges()
	var query_string = ""
	var path = full_path
	if full_path.find("?") != -1:
		var parts = full_path.split("?", false, 2)
		path = parts[0]
		query_string = parts[1]
	compatible = query_string.find("compatible") != -1

	var current_time = Time.get_unix_time_from_system()
	var glb_data = PackedByteArray()
	if path.is_empty() or path == "/":
		var root_node = get_editor_interface().get_edited_scene_root()
		if last_request_time > 0 and (current_time - last_request_time) <= GET_DEBOUNCE_TIME and last_glb_data.size() > 0:
			glb_data = last_glb_data
		else:
			var gltf_doc = GLTFDocument.new()
			gltf_doc.image_format = "PNG"
			if compatible and MSFT_texture_dds:
				gltf_doc.image_format = "DDS"
			var state = GLTFState.new()
			var flags = EditorSceneFormatImporter.IMPORT_USE_NAMED_SKIN_BINDS | EditorSceneFormatImporter.IMPORT_GENERATE_TANGENT_ARRAYS
			var error = gltf_doc.append_from_scene(root_node, state, flags)
			if error != OK:
				push_error("GLTF export error: " + str(error))
				return
			glb_data = gltf_doc.generate_buffer(state)
			last_glb_data = glb_data

			add_csg_mesh_with_timestamp()

		last_request_time = current_time
	else:
		send_bad_request(http_client, "Invalid path.")
		return
	
	if glb_data.size() > 0:
		var response = "HTTP/1.1 200 OK\r\nContent-Type: model/gltf-binary\r\nContent-Disposition: attachment; filename=\"model.glb\"\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % glb_data.size()
		http_client.put_data(response.to_utf8_buffer())
		http_client.put_data(glb_data)
	else:
		send_not_found(http_client, "GLB data not available.")
	http_client.disconnect_from_host()

func add_csg_mesh_with_timestamp():
	var root_node = get_editor_interface().get_edited_scene_root()
	var existing_node = root_node.get_node_or_null("ISODatetime")
	var curve_step = 10
	if existing_node:
		if existing_node is CSGMesh3D:
			var iso_datetime = Time.get_datetime_string_from_system(true)
			if existing_node.mesh is TextMesh:
				existing_node.mesh.text = iso_datetime + "Z"
				existing_node.mesh.curve_step = curve_step
	else:
		if not existing_node:
			var array_mesh: TextMesh = TextMesh.new()
			var iso_datetime = Time.get_datetime_string_from_system(true)
			array_mesh.text = iso_datetime + "Z"
			array_mesh.curve_step = curve_step
			csg_mesh.mesh = array_mesh
			csg_mesh.name = "ISODatetime"
			csg_mesh.transform.origin = Vector3(0, 1, 0)
			root_node.add_child(csg_mesh)
			csg_mesh.owner = root_node

func send_bad_request(client, message):
	var error_response = "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n" + message
	client.put_data(error_response.to_utf8_buffer())
	client.disconnect_from_host()

func send_not_found(client, message):
	var error_response = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n" + message
	client.put_data(error_response.to_utf8_buffer())
	client.disconnect_from_host()
