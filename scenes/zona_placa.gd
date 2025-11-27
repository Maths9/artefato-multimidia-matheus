# script: zona_placa.gd
extends Control

# Esse sinal avisa a página principal quando algo caiu aqui
signal regra_recebida(id_regra)

func _can_drop_data(_at_position, data):
	# Só aceita se o objeto arrastado tiver um "id"
	return typeof(data) == TYPE_DICTIONARY and data.has("id")

func _drop_data(_at_position, data):
	# Quando o mouse solta o objeto
	var id = data["id"]
	emit_signal("regra_recebida", id)
