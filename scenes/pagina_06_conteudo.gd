extends Control

# --- EXPORTS ---
@export_group("Botões")
@export var botao_som: BaseButton
@export var botao_avancar: BaseButton
@export var botao_retroceder: BaseButton
@export var painel_licao: Control
@export var legenda_texto: Label

@export_group("Jogo")
@export var destino_caixa: Node2D
@export var aviao: Area2D
@export var urso: Area2D
@export var carro: Area2D
@export var bola: Area2D # <--- NOVO BRINQUEDO AQUI

# --- VARIÁVEIS ---
var icone_som_ligado = load("res://assets/imagens/icone_som_ligado.png") 
var icone_som_desligado = load("res://assets/imagens/icone_som_desligado.png") 

const RAIO_CLIQUE = 150.0 
var toques_ativos = {} 
var posicoes_iniciais = {}
# ATUALIZADO: Agora são 4 brinquedos
var brinquedos_restantes = 4 
var primeiro_combo_feito = false 

func _ready():
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)
	
	# 1. GARANTIR QUE O FUNDO NÃO BLOQUEIE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("TextureRect"):
		get_node("TextureRect").mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 2. ESCONDER LIÇÃO
	if painel_licao: 
		painel_licao.visible = false
		painel_licao.scale = Vector2(0, 0)
	
	# 3. MOSTRAR BOTÕES
	if botao_avancar: botao_avancar.visible = true
	if botao_retroceder: botao_retroceder.visible = true
	
	atualizar_legenda("DESAFIO: Para começar, arraste DOIS brinquedos juntos!")
	
	if botao_som: setup_botoes()
	call_deferred("setup_brinquedos")

func _process(_delta):
	queue_redraw()

# --- INPUT (VOLTAMOS PARA _input MAS COM PROTEÇÃO) ---
func _input(event):
	# 1. PEGAR
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		
		# --- PROTEÇÃO: Se clicou em botão, IGNORA os brinquedos ---
		if clicou_em_botao(event.position):
			return 
		# ----------------------------------------------------------

		var index = 0
		if event is InputEventScreenTouch: index = event.index
		
		if not toques_ativos.has(index):
			var brinquedo = verificar_toque(event.position)
			if brinquedo:
				animar_pegada(brinquedo)
				toques_ativos[index] = brinquedo
				
				if primeiro_combo_feito:
					atualizar_legenda("Leve para a caixa.")
				elif toques_ativos.size() > 1:
					atualizar_legenda("Isso! Agora leve os dois para a caixa!")
				else:
					atualizar_legenda("Pegue mais um! O primeiro precisa de ajuda.")
				
				get_viewport().set_input_as_handled()

	# 2. ARRASTAR
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		var index = 0
		if event is InputEventScreenDrag: index = event.index
		
		if toques_ativos.has(index):
			toques_ativos[index].global_position = event.position

	# 3. SOLTAR
	elif (event is InputEventMouseButton and not event.pressed) or (event is InputEventScreenTouch and not event.pressed):
		var index = 0
		if event is InputEventScreenTouch: index = event.index
		
		if toques_ativos.has(index):
			var brinquedo = toques_ativos[index]
			toques_ativos.erase(index)
			verificar_caixa(brinquedo)

# --- FUNÇÃO NOVA: VERIFICA SE CLICOU NO BOTÃO ---
func clicou_em_botao(posicao_toque):
	var lista_botoes = [botao_som, botao_avancar, botao_retroceder]
	for botao in lista_botoes:
		if botao and botao.visible:
			# Verifica se a posição do toque está dentro do retângulo do botão
			if botao.get_global_rect().has_point(posicao_toque):
				return true
	return false

# --- RESTO DO CÓDIGO (LÓGICA DO JOGO) ---
func verificar_caixa(brinquedo):
	if not destino_caixa: 
		devolver(brinquedo)
		return
		
	if brinquedo.global_position.distance_to(destino_caixa.global_position) < 150.0:
		if primeiro_combo_feito:
			guardar(brinquedo)
		elif toques_ativos.size() > 0:
			primeiro_combo_feito = true
			guardar(brinquedo)
		else:
			atualizar_legenda("O primeiro tem que ser em dupla! Arraste dois juntos.")
			devolver(brinquedo)
	else:
		atualizar_legenda("Tente colocar dentro da caixa.")
		devolver(brinquedo)

func guardar(brinquedo):
	if primeiro_combo_feito and brinquedos_restantes > 1:
		atualizar_legenda("Boa! Pode guardar o resto normalmente agora.")
	else:
		atualizar_legenda("Muito bem!")
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(brinquedo, "global_position", destino_caixa.global_position, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(brinquedo, "scale", Vector2(0, 0), 0.4)
	tween.tween_property(brinquedo, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(func(): brinquedo.visible = false)
	
	brinquedos_restantes -= 1
	if brinquedos_restantes <= 0:
		atualizar_legenda("Tudo limpo! Missão cumprida.")
		mostrar_licao_final()

func devolver(brinquedo):
	brinquedo.z_index = 50
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(brinquedo, "global_position", posicoes_iniciais[brinquedo], 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(brinquedo, "scale", Vector2(1, 1), 0.2)
	tween.tween_property(brinquedo, "rotation_degrees", 0, 0.2)

func mostrar_licao_final():
	if painel_licao:
		painel_licao.visible = true
		painel_licao.z_index = 4096 # Acima dos botões até
		var tween = create_tween()
		tween.tween_property(painel_licao, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- CONFIGURAÇÃO ---
func setup_botoes():
	var lista_botoes = [botao_som, botao_avancar, botao_retroceder]
	for botao in lista_botoes:
		if botao:
			botao.visible = true
			botao.z_index = 4096
			# Mouse Stop ainda é bom, mas nossa função clicou_em_botao garante a proteção
			botao.mouse_filter = Control.MOUSE_FILTER_STOP 

	if botao_som and not botao_som.pressed.is_connected(_on_botao_som_pressed):
		botao_som.pressed.connect(_on_botao_som_pressed)
	if botao_avancar and not botao_avancar.pressed.is_connected(_on_botao_avancar_pressed):
		botao_avancar.pressed.connect(_on_botao_avancar_pressed)
	if botao_retroceder and not botao_retroceder.pressed.is_connected(_on_botao_retroceder_pressed):
		botao_retroceder.pressed.connect(_on_botao_retroceder_pressed)
	if botao_som: atualizar_icone_som()

func setup_brinquedos():
	# ADICIONADO A BOLA AQUI NA LISTA
	var lista = [aviao, urso, carro, bola]
	for item in lista:
		if item:
			posicoes_iniciais[item] = item.global_position
			item.z_index = 50 

func verificar_toque(posicao_toque):
	# ADICIONADO A BOLA AQUI NA LISTA
	var lista = [aviao, urso, carro, bola]
	for item in lista:
		if item and item.visible:
			var distancia = posicao_toque.distance_to(item.global_position)
			if distancia < RAIO_CLIQUE:
				return item
	return null

func atualizar_legenda(texto):
	if legenda_texto: legenda_texto.text = texto

func animar_pegada(brinquedo):
	brinquedo.z_index = 100
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(brinquedo, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(brinquedo, "rotation_degrees", -15, 0.2)

# --- BOTÕES EVENTOS ---
func _on_botao_som_pressed():
	if GerenciadorGlobal.has_method("toggle_som"): 
		GerenciadorGlobal.toggle_som()
		atualizar_icone_som()

func _on_botao_avancar_pressed():
	if GerenciadorGlobal.has_method("avancar_pagina"): GerenciadorGlobal.avancar_pagina()

func _on_botao_retroceder_pressed():
	if GerenciadorGlobal.has_method("retroceder_pagina"): GerenciadorGlobal.retroceder_pagina()

func atualizar_icone_som():
	if not botao_som or not icone_som_ligado: return
	var parado = GerenciadorGlobal.get("is_stopped")
	if parado == null: parado = false
	botao_som.icon = icone_som_desligado if parado else icone_som_ligado

# --- DEBUG ---
func _draw():
	# ADICIONADO A BOLA AQUI NA LISTA
	var lista = [aviao, urso, carro, bola]
	for item in lista:
		if item and item.visible:
			var pos_local = item.global_position - global_position
			draw_circle(pos_local, RAIO_CLIQUE, Color(0, 1, 0, 0.3))
