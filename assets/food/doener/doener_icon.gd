extends Node2D

func setze_döner_zusammen(zutaten_liste: Array):
	for child in get_children():
		if child is CanvasItem: 
			child.visible = false
	
	# Array -> Dictionary
	# ["tomate", "tomate", "tomate", "tomate"] -> {"tomate": 4}
	var mengen_zaehler = {}
	
	for zutat in zutaten_liste:
		# z.b. "Fleisch" -> "fleisch"
		var zutat_clean = zutat.to_lower()
		
		if zutat_clean in mengen_zaehler:
			mengen_zaehler[zutat_clean] += 1
		else:
			mengen_zaehler[zutat_clean] = 1
			
	# so viele nodes anschalten, wie gefordert sind
	for zutat_name in mengen_zaehler.keys():
		var anzahl_in_order = mengen_zaehler[zutat_name]
		
		# prüfen wie oft zutat vorkommt
		for i in range(1, anzahl_in_order + 1):
			# z.B. "tomate_1", "tomate_2", "tomate_3", "tomate_4"
			var target_node_name = zutat_name + "_" + str(i)
			
			if has_node(target_node_name):
				get_node(target_node_name).visible = true
			else:
				pass
