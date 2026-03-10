extends Node

@export var node_scene: PackedScene
var cached_nodes: Array[Node2D]

func spawn() -> Node2D:
	for node in cached_nodes:
		if node.visible == false:
			node.visible = true
			node.set_process(true)
			node.set_physics_process(true)
			return node
	return _create_new()
	
# instantiate a new node
func _create_new() -> Node2D:
	var node = node_scene.instantiate()
	cached_nodes.append(node)
	#get_tree().get_root().add_child(node)
	get_tree().get_root().add_child.call_deferred(node)
	return node
