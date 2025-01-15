extends PolyBody
class_name PolyActor

signal resolved

var selectable = false
var selected = false
var configured = false
var config = Dictionary()

# Extenders must super() all the functions defined here.
func _ready() -> void:
	super()
	reset()

# All PolyActors must have an Outline child and super() their _process.
func _process(delta: float) -> void:
	super(delta)
	if selectable:
		get_node("Outline").texture = preload("res://Visuals/DottedLine.png")
		get_node("Outline").width = 3 if selected else 2

# Runs when the actor is selected to be configured. Extenders must ensure to only work if selectable.
func select() -> void:
	if selectable:
		selected = true

# Runs when the configuration is cancelled.
func deselect() -> void:
	selected = false

# Runs when the configuration is verified.
func configure() -> void:
	configured = true
	selected = false

# Runs when the actor performs its action.
func resolve() -> Signal:
	return resolved

# Runs at the start of a new round, including the first.
func reset() -> void:
	selected = false
	configured = false
