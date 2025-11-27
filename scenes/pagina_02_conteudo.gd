extends Control

# --- Referências ---
@onready var narracao_player = $NarracaoPlayer
@onready var botao_coracao = $BotaoCoracao
@onready var botao_som = $TextureRect/BotaoSom
@onready var label_moral = get_node_or_null("LabelMoral")

# <--- NOVO: Referência às partículas
@onready var particulas_coracao = get_node_or_null("ParticulasCoracao")

var escala_final_texto = Vector2(1.0, 1.0)

# Tweens
var tween_pulsar: Tween
var tween_balao: Tween

# Estado
var texto_esta_aberto = false

func _ready():
	# 1. Configurar a Label (Começa oculta)
	if label_moral:
		label_moral.pivot_offset = label_moral.size / 2
		label_moral.scale = Vector2(0, 0)
		label_moral.modulate.a = 0
		label_moral.visible = false 
		texto_esta_aberto = false
	
	# 2. Configurar o Coração
	if botao_coracao:
		botao_coracao.pivot_offset = botao_coracao.size / 2
		iniciar_pulsar_coracao()
		
	# <--- NOVO: Garante que as partículas não começam emitindo sozinho
	if particulas_coracao:
		particulas_coracao.emitting = false
		particulas_coracao.one_shot = true # Reforço de segurança
	
	atualizar_icone_som()
	if narracao_player and not GerenciadorGlobal.is_stopped:
		narracao_player.play()

func iniciar_pulsar_coracao():
	if not botao_coracao: return
	if tween_pulsar: tween_pulsar.kill()
	
	tween_pulsar = create_tween().set_loops()
	tween_pulsar.tween_property(botao_coracao, "scale", Vector2(1.05, 1.05), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_pulsar.tween_property(botao_coracao, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_botao_coracao_pressed():
	if not label_moral: return

	if tween_balao: tween_balao.kill()
	
	tween_balao = create_tween().set_parallel(true)
	
	if texto_esta_aberto:
		# --- FECHAR ---
		tween_balao.tween_property(label_moral, "scale", Vector2(0, 0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween_balao.tween_property(label_moral, "modulate:a", 0.0, 0.4)
		texto_esta_aberto = false
		# (Opcional: não soltamos partículas ao fechar, só ao abrir)
		
	else:
		# --- ABRIR ---
		label_moral.pivot_offset = label_moral.size / 2
		label_moral.visible = true
		
		tween_balao.tween_property(label_moral, "scale", escala_final_texto, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_balao.tween_property(label_moral, "modulate:a", 1.0, 0.6)
		texto_esta_aberto = true
		
		# <--- NOVO: DISPARA A EXPLOSÃO DE PARTÍCULAS!
		# Usamos .restart() para garantir que ele dispare do início mesmo se clicarmos rápido
		if particulas_coracao:
			particulas_coracao.restart()

# --- Navegação e Som (Igual ao anterior) ---
func _on_botao_avancar_pressed():
	if narracao_player: narracao_player.stop()
	GerenciadorGlobal.avancar_pagina()

func _on_botao_retroceder_pressed():
	if narracao_player: narracao_player.stop()
	GerenciadorGlobal.retroceder_pagina()

func _on_botao_som_pressed():
	GerenciadorGlobal.toggle_som()
	if narracao_player:
		if GerenciadorGlobal.is_stopped:
			narracao_player.stop()
		else:
			narracao_player.play()
	atualizar_icone_som()

func atualizar_icone_som():
	if not botao_som: return
	if not GerenciadorGlobal.is_stopped:
		if botao_som is TextureButton: botao_som.texture_normal = preload("res://assets/imagens/icone_som_ligado.png")
		else: botao_som.icon = preload("res://assets/imagens/icone_som_ligado.png")
	else:
		if botao_som is TextureButton: botao_som.texture_normal = preload("res://assets/imagens/icone_som_desligado.png")
		else: botao_som.icon = preload("res://assets/imagens/icone_som_desligado.png")
