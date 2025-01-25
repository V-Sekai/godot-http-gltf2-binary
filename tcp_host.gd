@tool
extends EditorPlugin

var server: TCPServer
var glb_data: PackedByteArray = PackedByteArray()
var is_running := false

func _enter_tree():
	add_tool_menu_item("Start Export Server", _on_toggle_server)

func _exit_tree():
	remove_tool_menu_item("Start Export Server")
	if server:
		server.stop()
		server = null

func _process(_delta):
	if server and server.is_connection_available():
		var client = server.take_connection()
		if client:
			client.set_blocking(false)
			handle_client(client)

func handle_client(client):
	var request = client.get_utf8_packet().strip_edges()
	if request.begins_with("GET /model.glb"):
		if glb_data.size() > 0:
			var response = "HTTP/1.1 200 OK\r\nContent-Type: model/gltf-binary\r\nContent-Length: %d\r\nConnection: keep-alive\r\n\r\n" % glb_data.size()
			client.put_packet(response.to_utf8())
			client.put_packet(glb_data)
		else:
			var error_response = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nGLB data not available."
			client.put_packet(error_response.to_utf8())
	else:
		var error_response = "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nInvalid request."
		client.put_packet(error_response.to_utf8())

func _on_toggle_server():
	if is_running:
		server.stop()
		server = null
		is_running = false
		remove_tool_menu_item("Stop Export Server")
		add_tool_menu_item("Start Export Server", _on_toggle_server)
	else:
		var callable = Callable(self, "_thread_export_scene")
		callable = callable.bind(get_tree().get_current_scene())
		var task_id = WorkerThreadPool.add_task(callable)
		WorkerThreadPool.wait_for_task_completion(task_id)
		is_running = true
		remove_tool_menu_item("Start Export Server")
		add_tool_menu_item("Stop Export Server", _on_toggle_server)

func _thread_export_scene(scene):
	var gltf_doc = GLTFDocument.new()
	var state = GLTFState.new()
	var error = gltf_doc.append_from_scene(scene, state)
	if error == OK:
		glb_data = gltf_doc.generate_buffer(state)
	else:
		push_error("GLTF export error: " + str(error))
	var err = OK
	if server == null:
		server = TCPServer.new()
		err = server.listen(8080)
	if err != OK:
		push_error("Server start error: " + str(err))
