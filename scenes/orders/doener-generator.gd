class_name DonerGenerator
extends Node

# Referenzen auf Ingredient-Resources
@export var brot: Ingredient
@export var fleisch: Ingredient
@export var tomate: Ingredient
@export var gurke: Ingredient
@export var salat: Ingredient
@export var sosse: Ingredient
@export var zwiebel: Ingredient


func generate_doner() -> Array[Ingredient]:
	var ingredients: Array[Ingredient] = []

	# --- Brot (genau 1) ---
	ingredients.append(brot)

	# --- Fleisch (1–2) ---
	var meat_count := randi_range(1, 2)
	for i in meat_count:
		ingredients.append(fleisch)

	# --- Tomate (0–3) ---
	var tomate_count := randi_range(0, 3)
	for i in tomate_count:
		ingredients.append(tomate)

	# --- Gurke (0–3) ---
	var gurke_count := randi_range(0, 3)
	for i in gurke_count:
		ingredients.append(gurke)

	# --- Salat (0–1) ---
	var salat_count := randi_range(0, 1)
	for i in salat_count:
		ingredients.append(salat)

	# --- Soße (0–1) ---
	var sosse_count := randi_range(0, 1)
	for i in sosse_count:
		ingredients.append(sosse)

	# --- Zwiebeln (0–1) ---
	var zwiebel_count := randi_range(0, 1)
	for i in zwiebel_count:
		ingredients.append(zwiebel)

	return ingredients
