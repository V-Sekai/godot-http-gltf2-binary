@tool
extends EditorPlugin

var glb_data: PackedByteArray = PackedByteArray()
var http_server: TCPServer
var is_running := false
const PORT = 8081

func _enter_tree():
	print("MSG_PLUGIN_ENTERED")
	var editor_settings = EditorInterface.get_editor_settings()
	http_server = TCPServer.new()
	var err_http = http_server.listen(PORT)
	if err_http != OK:
		push_error("HTTP Server start error: " + str(err_http))
		return
	is_running = true

func _exit_tree():
	print("MSG_PLUGIN_EXITING")
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
	print("Handling new client connection.")
	
	if http_client.get_available_bytes() == 0:
		http_client.disconnect_from_host()
		return
	
	var request = http_client.get_utf8_string(http_client.get_available_bytes()).strip_edges()
	if not request.begins_with("GET /model.glb"):
		print("Invalid request received.")
		var error_response = "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nInvalid request."
		http_client.put_data(error_response.to_utf8_buffer())
		http_client.disconnect_from_host()
		return
	
	print("Exporting scene to GLB.")
	var gltf_doc = GLTFDocument.new()
	var state = GLTFState.new()
	var error = gltf_doc.append_from_scene(get_editor_interface().get_edited_scene_root(), state)
	if error != OK:
		glb_data = PackedByteArray()
		push_error("GLTF export error: " + str(error))
	else:
		glb_data = gltf_doc.generate_buffer(state)
		print("GLB data generated successfully.")
	
	if glb_data.size() == 0:
		print("GLB data not available.")
		var error_response = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nGLB data not available."
		http_client.put_data(error_response.to_utf8_buffer())
		http_client.disconnect_from_host()
		return
	
	print("Serving GLB data to client.")
	var response: String = "HTTP/1.1 200 OK\r\nContent-Type: model/gltf-binary\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % glb_data.size()
	http_client.put_data(response.to_utf8_buffer())
	http_client.put_data(glb_data)
	http_client.disconnect_from_host()
