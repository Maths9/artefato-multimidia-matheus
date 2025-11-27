extends Control

# --- CONFIGURAÇÕES DE LAYOUT ---
@export_category("1. Organizador")
@export var usar_layout_automatico: bool = false
@export var posicao_bola: Vector2 = Vector2(360, 900)
@export var posicao_gol: Vector2 = Vector2(150, 650)
@export var posicao_amigo: Vector2 = Vector2(930, 404) 

# --- REFERÊNCIAS ---
@export_category("2. Referências")
@export var bola: RigidBody2D 
@export var linha_mira: Line2D 
@export var alvo_gol: Area2D
@export var alvo_amigo: Area2D
@export var texto_narrativa: Control 

@export_category("3. Ajustes de Interação")
@export var forca_lancamento: float = 3.0 
@export var raio_clique: float = 150.0 
@export var margem_parede: float = 80.0 
@export var distancia_deteccao: float = 250.0 
@export var limite_forca_maxima: float = 200.0 

var esta_arrastando: bool = false
var ancora_estilingue: Vector2 
var escolha_concluida: bool = false 
var animacao_final: bool = false 

var centro_real_gol: Vector2
var centro_real_amigo: Vector2
var texto_original: String = "" 

var icone_som_ligado = load("res://assets/imagens/icone_som_ligado.png")
var icone_som_desligado = load("res://assets/imagens/icone_som_desligado.png")
@onready var botao_som = $"TextureRect/BotaoSom" 

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS

	if texto_narrativa and "text" in texto_narrativa:
		texto_original = texto_narrativa.text

	if bola:
		# Correção visual
		var sprite_visual = null
		for filho in bola.get_children():
			if filho is Sprite2D:
				sprite_visual = filho
				break
		
		if sprite_visual and sprite_visual.position != Vector2.ZERO:
			var pos_real = sprite_visual.global_position
			bola.global_position = pos_real
			for f in bola.get_children(): 
				if f is Node2D: f.position = Vector2.ZERO

		if usar_layout_automatico:
			bola.global_position = posicao_bola
			if alvo_gol: alvo_gol.global_position = posicao_gol
			if alvo_amigo: alvo_amigo.global_position = posicao_amigo
		
		ancora_estilingue = bola.global_position
		
		centro_real_gol = obter_centro_do_shape(alvo_gol)
		centro_real_amigo = obter_centro_do_shape(alvo_amigo)
		
		# --- CORREÇÃO DO "ÍMÃ" (SEM ERRO) ---
		if alvo_gol:
			alvo_gol.gravity_point = false
			# alvo_gol.gravity_distance_scale = 0  <-- REMOVIDO (Causava o erro)
			alvo_gol.gravity = 0
			alvo_gol.monitoring = true
			alvo_gol.monitorable = true
			
		if alvo_amigo:
			alvo_amigo.gravity_point = false
			# alvo_amigo.gravity_distance_scale = 0 <-- REMOVIDO (Causava o erro)
			alvo_amigo.gravity = 0
			alvo_amigo.monitoring = true
			alvo_amigo.monitorable = true

		# Física da Bola
		bola.gravity_scale = 0 
		bola.linear_damp = 1.0 
		bola.angular_damp = 3.0 
		bola.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
		
		var mat = PhysicsMaterial.new()
		mat.friction = 0.2; mat.bounce = 0.5
		bola.physics_material_override = mat
		
		bola.freeze = true 
		bola.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		bola.z_index = 100
		
		criar_paredes_limite()
		queue_redraw()
	else:
		print("ERRO: Bola não conectada!")
	
	if linha_mira:
		linha_mira.visible = false
		linha_mira.width = 20.0 
		linha_mira.default_color = Color.GREEN
		linha_mira.z_index = 90 
		linha_mira.begin_cap_mode = Line2D.LINE_CAP_ROUND
		linha_mira.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	atualizar_icone_som()

func obter_centro_do_shape(area: Area2D) -> Vector2:
	if not area: return Vector2.ZERO
	for filho in area.get_children():
		if filho is CollisionShape2D:
			return filho.global_position
	return area.global_position

func criar_paredes_limite():
	if has_node("ParedesLimites"): return 
	var corpo = StaticBody2D.new()
	corpo.name = "ParedesLimites"
	add_child(corpo)
	var r = get_viewport_rect(); var e = 50.0; var o = 20.0
	var w = [
		{p=Vector2(r.size.x/2, -e/2-o), s=Vector2(r.size.x, e)},
		{p=Vector2(r.size.x/2, r.size.y+e/2+o), s=Vector2(r.size.x, e)},
		{p=Vector2(-e/2-o, r.size.y/2), s=Vector2(e, r.size.y)},
		{p=Vector2(r.size.x+e/2+o, r.size.y/2), s=Vector2(e, r.size.y)}
	]
	for d in w:
		var c = CollisionShape2D.new(); var s = RectangleShape2D.new()
		s.size = d.s; c.shape = s; c.position = d.p; corpo.add_child(c)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if bola and bola.global_position.distance_to(event.global_position) < raio_clique:
				esta_arrastando = true
				bola.freeze = true
				bola.gravity_scale = 0 
				bola.linear_velocity = Vector2.ZERO
		else:
			if esta_arrastando:
				lancar_bola(); esta_arrastando = false

func _physics_process(_delta):
	if animacao_final and bola: 
		bola.rotation_degrees += 360 * _delta

	if esta_arrastando and bola:
		var m = get_global_mouse_position(); var r = get_viewport_rect()
		m.x = clamp(m.x, margem_parede, r.size.x - margem_parede)
		m.y = clamp(m.y, margem_parede, r.size.y - margem_parede)
		bola.global_position = m
		
		verificar_hover_zonas()
		atualizar_visual_mira()
		queue_redraw()
	
	if bola and not esta_arrastando and not escolha_concluida:
		# Deteção
		if alvo_gol and bola.global_position.distance_to(centro_real_gol) < distancia_deteccao:
			_processar_decisao("REGRA")
		if alvo_amigo and bola.global_position.distance_to(centro_real_amigo) < distancia_deteccao:
			_processar_decisao("ETICA")
		
		if alvo_gol and alvo_gol.overlaps_body(bola): _processar_decisao("REGRA")
		if alvo_amigo and alvo_amigo.overlaps_body(bola): _processar_decisao("ETICA")
		
		# Reset
		if not get_viewport_rect().grow(200).has_point(bola.global_position):
			bola.global_position = ancora_estilingue
			bola.freeze = true
			bola.gravity_scale = 0 
			bola.linear_velocity = Vector2.ZERO

func verificar_hover_zonas():
	if escolha_concluida: return
	var detectou_algo = false
	
	if alvo_gol:
		var dist_gol = bola.global_position.distance_to(centro_real_gol)
		if dist_gol < distancia_deteccao or alvo_gol.overlaps_body(bola):
			mudar_texto_preview("REGRA")
			alvo_gol.modulate = Color(1, 0.6, 0.6)
			detectou_algo = true
		else:
			alvo_gol.modulate = Color(1, 1, 1)

	if not detectou_algo and alvo_amigo:
		var dist_amigo = bola.global_position.distance_to(centro_real_amigo)
		if dist_amigo < distancia_deteccao or alvo_amigo.overlaps_body(bola):
			mudar_texto_preview("ETICA")
			alvo_amigo.modulate = Color(0.6, 1, 0.6)
			detectou_algo = true
		else:
			alvo_amigo.modulate = Color(1, 1, 1)
	elif alvo_amigo:
		alvo_amigo.modulate = Color(1, 1, 1)

	if not detectou_algo:
		mudar_texto_preview("RESET")

func mudar_texto_preview(tipo):
	if not texto_narrativa or not "text" in texto_narrativa: return
	
	if tipo == "REGRA":
		texto_narrativa.text = "Você está escolhendo a REGRA.\nSolte para apitar a falta..."
	elif tipo == "ETICA":
		texto_narrativa.text = "Você está escolhendo a ÉTICA.\nSolte para ajudar o amigo..."
	elif tipo == "RESET":
		if texto_narrativa.text != texto_original:
			texto_narrativa.text = texto_original

func atualizar_visual_mira():
	if linha_mira:
		linha_mira.visible = true
		linha_mira.clear_points()
		linha_mira.add_point(ancora_estilingue)
		linha_mira.add_point(bola.global_position)
		var dist = ancora_estilingue.distance_to(bola.global_position)
		var tensao = clamp(dist / limite_forca_maxima, 0.0, 1.0)
		linha_mira.default_color = Color.GREEN.lerp(Color.RED, tensao)

func _draw():
	# Debug visual (descomente se precisar)
	# if alvo_gol: draw_circle(centro_real_gol, distancia_deteccao, Color(1, 0, 0, 0.2))
	# if alvo_amigo: draw_circle(centro_real_amigo, distancia_deteccao, Color(0, 1, 0, 0.2))
	pass

func lancar_bola():
	if linha_mira: linha_mira.visible = false
	var v = bola.global_position - ancora_estilingue
	
	bola.freeze = false
	bola.sleeping = false
	
	# Ativa gravidade para cair se errar
	bola.gravity_scale = 1.0 
	
	bola.apply_central_impulse(v * forca_lancamento)

func _processar_decisao(decisao):
	if escolha_concluida: return
	escolha_concluida = true
	
	print("DECISÃO TOMADA: ", decisao)
	
	if decisao == "REGRA":
		if alvo_gol: alvo_gol.modulate = Color.RED
		mudar_texto_final("REGRA")
	elif decisao == "ETICA":
		if alvo_amigo: alvo_amigo.modulate = Color.GREEN
		mudar_texto_final("ETICA")
	
	avancar_historia()

func mudar_texto_final(escolha):
	if texto_narrativa and "text" in texto_narrativa:
		if escolha == "REGRA":
			texto_narrativa.text = "Você decidiu seguir a REGRA!\nLéo apitou a falta e o jogo continuou, mas o amigo ficou triste..."
		else:
			texto_narrativa.text = "Você decidiu pela ÉTICA!\nLéo parou o jogo para ajudar o amigo. A amizade venceu!"

func avancar_historia():
	animacao_final = true
	bola.call_deferred("set_freeze_enabled", true)
	bola.linear_velocity = Vector2.ZERO
	bola.gravity_scale = 0 
	
	await get_tree().create_timer(3.0).timeout
	if GerenciadorGlobal: GerenciadorGlobal.avancar_pagina()

func _on_botao_avancar_pressed(): if GerenciadorGlobal: GerenciadorGlobal.avancar_pagina()
func _on_botao_retroceder_pressed(): if GerenciadorGlobal: GerenciadorGlobal.retroceder_pagina()
func _on_botao_som_pressed(): if GerenciadorGlobal: GerenciadorGlobal.toggle_som(); atualizar_icone_som()
func atualizar_icone_som(): 
	if botao_som and GerenciadorGlobal:
		botao_som.icon = icone_som_ligado if not GerenciadorGlobal.is_stopped else icone_som_desligado
