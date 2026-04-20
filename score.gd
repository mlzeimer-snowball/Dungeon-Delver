extends RichTextLabel

var default_text = "SCORE: "
var score: int

func _ready() -> void:
	var world = get_tree().get_first_node_in_group("world")
	world.score_update.connect(_on_score_update.bind(world))

func _process(delta: float) -> void:
	var text = str(default_text) + str(score)
	self.text = text

func _on_score_update(world):
	score = world.score
