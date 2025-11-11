class_name DoenerOrder
extends Resource

## Enum für alle möglichen Zutaten
enum Ingredient {
	FLEISCH,
	SALAT,
	TOMATE,
	ZWIEBEL,
	GURKE,
	SOSSE_SCHARF,
	SOSSE_MILD,
	KAESE
}

## Name der Bestellung (z.B. "Döner ohne Zwiebel")
@export var order_name: String = "Döner Standard"

## Zutaten die im Döner sein MÜSSEN
@export var required_ingredients: Array[Ingredient] = []

## Zutaten die NICHT im Döner sein dürfen
@export var excluded_ingredients: Array[Ingredient] = []

## Prüft ob zubereiteter Döner der Bestellung entspricht
func matches(prepared_ingredients: Array) -> bool:
	# Prüfe ob alle benötigten Zutaten vorhanden sind
	for ingredient in required_ingredients:
		if ingredient not in prepared_ingredients:
			print("Missing ingredient: ", Ingredient.keys()[ingredient])
			return false
	
	# Prüfe ob keine ausgeschlossenen Zutaten vorhanden sind
	for ingredient in excluded_ingredients:
		if ingredient in prepared_ingredients:
			print("Unwanted ingredient: ", Ingredient.keys()[ingredient])
			return false
	
	return true

## Debug: Gibt Bestellung als Text aus
func get_order_description() -> String:
	var result = order_name + "\n"
	
	if required_ingredients.size() > 0:
		result += "Mit: "
		for ing in required_ingredients:
			result += Ingredient.keys()[ing] + ", "
		result = result.trim_suffix(", ") + "\n"
	
	if excluded_ingredients.size() > 0:
		result += "Ohne: "
		for ing in excluded_ingredients:
			result += Ingredient.keys()[ing] + ", "
		result = result.trim_suffix(", ")
	
	return result
