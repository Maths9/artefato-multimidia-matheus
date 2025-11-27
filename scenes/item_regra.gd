extends TextureRect

@export var id_regra: int = 1

func _get_drag_data(_at_position):
	# Cria a imagem de preview
	var preview = TextureRect.new()
	preview.texture = texture # Pega a textura do ícone atual
	
	# --- CORREÇÃO DE VISIBILIDADE ---
	# Define o modo de expansão para podermos forçar o tamanho
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Se o tamanho original for muito pequeno ou zero, forçamos um tamanho fixo (100x100)
	# Caso contrário, usa o tamanho original
	if size.x == 0 or size.y == 0:
		preview.size = Vector2(100, 100)
	else:
		preview.size = size
	
	# Deixa levemente transparente
	preview.modulate.a = 0.7
	
	# Ajusta a posição para o mouse ficar no meio da imagem
	preview.position = -preview.size / 2
	
	# Cria um container auxiliar (Isso ajuda o Godot a renderizar no topo de tudo)
	var c = Control.new()
	c.add_child(preview)
	
	# Define isso como o preview oficial do drag
	set_drag_preview(c)
	
	# Retorna os dados
	return { "id": id_regra }
