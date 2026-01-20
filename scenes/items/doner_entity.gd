extends ItemEntity
class_name DonerEntity

## A Döner is a composite item: it stores a list of Ingredient data resources and updates visuals on change.
## It can optionally render a plate backdrop (kitchen vs. customer).
var _show_plate_visual: bool = true
@export var show_plate_visual: bool:
	get:
		return _show_plate_visual
	set(value):
		_show_plate_visual = value
		_update_plate_visual()

## Collected ingredient data resources (not IDs). Matching is done via each ingredient's `item_id`.
var ingredients: Array[Ingredient] = []

## Collected freshness data for ingredients
var ingredient_freshness_data: Array[Dictionary] = []

@export var plate_texture: Texture2D

@onready var plate_sprite: Sprite2D = $Plate
@onready var base_sprite: Sprite2D = $Base
@onready var ingredients_root: Node2D = $Ingredients

var _brot_unten: Sprite2D
var _brot_oben: Sprite2D
var _sosse: Sprite2D
var _fleisch_layers: Array[Sprite2D] = []
var _tomate_layers: Array[Sprite2D] = []
var _salat_layers: Array[Sprite2D] = []
var _zwiebel_layers: Array[Sprite2D] = []
var _gurke_layers: Array[Sprite2D] = []

func _ready() -> void:
	z_index = 1
	if plate_texture == null:
		plate_texture = preload("res://assets/food/items/teller-sprite.png")
	_build_doner_layers()
	_hide_all_layers()
	_apply_doner_layers()
	_update_plate_visual()

func add_ingredient(ingredient_entity: IngredientEntity) -> bool:
	## Adds an ingredient into the döner. On success, the ingredient entity is consumed (queue_free).
	if ingredient_entity == null or ingredient_entity.ingredient == null:
		return false

	if ingredient_entity.requires_preparation() and not ingredient_entity.is_prepared:
		return false

	var new_id := ingredient_entity.ingredient.item_id
	if new_id == &"":
		return false

	if new_id == &"brot":
		if _has_bread():
			return false
		ingredients.append(ingredient_entity.ingredient)
		ingredient_freshness_data.append({
			"ingredient": ingredient_entity.ingredient,
			"creation_time": ingredient_entity.creation_time,
			"is_vegetable": ingredient_entity.is_vegetable()
		})
		print("[DonerEntity] Brot hinzugefügt: Brot")
		_apply_doner_layers()
		ingredient_entity.queue_free()
		return true

	if not _has_bread():
		return false

	ingredients.append(ingredient_entity.ingredient)
	ingredient_freshness_data.append({
		"ingredient": ingredient_entity.ingredient,
		"creation_time": ingredient_entity.creation_time,
		"is_vegetable": ingredient_entity.is_vegetable()
	})
	print("[DonerEntity] Zutat hinzugefügt: ", ingredient_entity.ingredient.name)
	_apply_doner_layers()
	ingredient_entity.queue_free()
	return true

func _has_bread() -> bool:
	for ing in ingredients:
		if ing != null and ing.item_id == &"brot":
			return true
	return false

func _update_plate_visual() -> void:
	if plate_sprite == null:
		return
	plate_sprite.visible = _show_plate_visual
	if plate_texture:
		plate_sprite.texture = plate_texture

func _build_doner_layers() -> void:
	## Builds visual layers based on `assets/food/doener/*` so we don't depend on a separate icon scene/script.
	if ingredients_root == null:
		return

	for child in ingredients_root.get_children():
		child.queue_free()

	_brot_unten = _create_layer_sprite("brot_unten_1", preload("res://assets/food/doener/brot-hinten.png"))

	_fleisch_layers.clear()
	_fleisch_layers.append(_create_layer_sprite("fleisch_1", preload("res://assets/food/doener/fleisch.png")))
	_fleisch_layers.append(_create_layer_sprite("fleisch_2", preload("res://assets/food/doener/fleisch-2.png")))

	_tomate_layers.clear()
	_tomate_layers.append(_create_layer_sprite("tomate_1", preload("res://assets/food/doener/tomate-1.png")))
	_tomate_layers.append(_create_layer_sprite("tomate_2", preload("res://assets/food/doener/tomate-2.png")))
	_tomate_layers.append(_create_layer_sprite("tomate_3", preload("res://assets/food/doener/tomate-3.png")))

	_salat_layers.clear()
	_salat_layers.append(_create_layer_sprite("salat_1", preload("res://assets/food/doener/salat-1.png")))
	_salat_layers.append(_create_layer_sprite("salat_2", preload("res://assets/food/doener/salat-2.png")))
	_salat_layers.append(_create_layer_sprite("salat_3", preload("res://assets/food/doener/salat-3.png")))

	_zwiebel_layers.clear()
	_zwiebel_layers.append(_create_layer_sprite("zwiebel_1", preload("res://assets/food/doener/zwiebel.png")))
	_zwiebel_layers.append(_create_layer_sprite("zwiebel_2", preload("res://assets/food/doener/zwiebel-2.png")))
	_zwiebel_layers.append(_create_layer_sprite("zwiebel_3", preload("res://assets/food/doener/zwiebel-3.png")))

	_gurke_layers.clear()
	_gurke_layers.append(_create_layer_sprite("gurke_1", preload("res://assets/food/doener/gurke-1.png")))
	_gurke_layers.append(_create_layer_sprite("gurke_2", preload("res://assets/food/doener/gurke-2.png")))
	_gurke_layers.append(_create_layer_sprite("gurke_3", preload("res://assets/food/doener/gurke-3.png")))

	_brot_oben = _create_layer_sprite("brot_oben_1", preload("res://assets/food/doener/brot-oben.png"))
	_sosse = _create_layer_sprite("sosse_1", preload("res://assets/food/doener/sosse.png"))

func _create_layer_sprite(node_name: String, texture: Texture2D) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = node_name
	s.texture = texture
	s.visible = false
	s.z_index = 1
	ingredients_root.add_child(s)
	s.position = Vector2.ZERO
	s.rotation = 0.0
	s.scale = Vector2.ONE
	return s

func _hide_all_layers() -> void:
	if _brot_unten != null:
		_brot_unten.visible = false
	for s in _fleisch_layers:
		s.visible = false
	for s in _tomate_layers:
		s.visible = false
	for s in _salat_layers:
		s.visible = false
	for s in _zwiebel_layers:
		s.visible = false
	for s in _gurke_layers:
		s.visible = false
	if _brot_oben != null:
		_brot_oben.visible = false
	if _sosse != null:
		_sosse.visible = false

func _apply_doner_layers() -> void:
	if ingredients_root == null:
		return

	_hide_all_layers()

	var counts: Dictionary = {}
	for ing in ingredients:
		if ing == null:
			continue
		var key := _render_key_for_item_id(ing.item_id)
		if key == &"":
			continue
		counts[key] = int(counts.get(key, 0)) + 1

	var has_bread := counts.has("brot")
	if has_bread:
		if _brot_unten != null:
			_brot_unten.visible = true
		if _brot_oben != null:
			_brot_oben.visible = true

	_set_layers_visible(_fleisch_layers, int(counts.get("fleisch", 0)))
	_set_layers_visible(_tomate_layers, int(counts.get("tomate", 0)))
	_set_layers_visible(_salat_layers, int(counts.get("salat", 0)))
	_set_layers_visible(_zwiebel_layers, int(counts.get("zwiebel", 0)))
	_set_layers_visible(_gurke_layers, int(counts.get("gurke", 0)))

	if int(counts.get("sosse", 0)) > 0 and _sosse != null:
		_sosse.visible = true

func _set_layers_visible(layers: Array[Sprite2D], amount: int) -> void:
	var limit: int = mini(amount, layers.size())
	for i in range(limit):
		layers[i].visible = true

func _render_key_for_item_id(id: StringName) -> StringName:
	match id:
		&"brot":
			return &"brot"
		&"fleisch", &"fleisch_burnt":
			return &"fleisch"
		&"tomate":
			return &"tomate"
		&"gurke":
			return &"gurke"
		&"salat":
			return &"salat"
		&"zwiebel":
			return &"zwiebel"
		&"sosse":
			return &"sosse"
		_:
			return &""
