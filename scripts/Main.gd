extends Node2D
var player
var menu
var entered_area = {}
func _ready():
	player = $player
	load_game()
	$"black-rect".modulate.a = 1
	$"black-rect".fade(1,1)

func _input(event):
	if event.is_action_pressed("ui_left"):
		player.queue_free()
		player = load("res://scenes/player/player.tscn").instance()
		add_child(player)
		move_child(player, 6)
	elif event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			$Menu.visible = false
		else:
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$Menu.visible = true
		save_game()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_game()
		get_tree().quit() # default behavior

func save_game():
	print("entered save")
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.filename.empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("save")

		# Store the save dictionary as a new line in the save file.
		save_game.store_line(to_json(node_data))
	save_game.close()
	print("saving done")

func load_game():
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		player.play_song(0, true)
		return

	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for i in save_nodes:
		i.queue_free()

	save_game.open("user://savegame.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())

		player = load(node_data["filename"]).instance()
		get_node(node_data["parent"]).add_child(player)
		move_child(player, 6)
		player.position = Vector2(node_data["pos_x"], node_data["pos_y"])
		player.rotation_degrees = node_data["rotation"] + 180
		player.set_start_speed(Vector2(node_data["force_x"], node_data["force_y"]))
		player.current_song = int(node_data["music"])
		var global_vars = get_node("/root/GlobalVariables")
		global_vars.mouse = node_data["mouse"]
		global_vars.volume = node_data["volume"]
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), global_vars.volume)
	
	save_game.close()

func _on_Area2D_body_entered(body):
	player.play_song(1)


func _on_Area2D2_body_entered(body):
	player.play_song(2)
