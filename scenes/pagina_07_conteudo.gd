extends Control

# --- Carregar as texturas dos ícones de Som ---
var icone_som_ligado = load("res://assets/imagens/icone_som_ligado.png") 
var icone_som_desligado = load("res://assets/imagens/icone_som_desligado.png") 

# --- Variáveis @onready (CORRIGIDAS para a nova estrutura) ---
@onready var video_player = $VideoStreamPlayer
@onready var botao_play = $BotaoPlay
@onready var botao_pause = $BotaoPause 
@onready var botao_som = $BotaoSom


func _ready():
	if is_instance_valid(botao_som):
		atualizar_icone_som()
	
	if is_instance_valid(botao_play):
		botao_play.show()
	
	if is_instance_valid(botao_pause):
		botao_pause.hide()

# --- Funções de Navegação ---
func _on_botao_avancar_pressed():
	GerenciadorGlobal.avancar_pagina()

func _on_botao_retroceder_pressed():
	GerenciadorGlobal.retroceder_pagina()

# --- Função de Som ---
func _on_botao_som_pressed():
	GerenciadorGlobal.toggle_som()
	if is_instance_valid(botao_som):
		atualizar_icone_som()

func atualizar_icone_som():

	if not GerenciadorGlobal.is_stopped:
		botao_som.icon = icone_som_ligado
	else:
		botao_som.icon = icone_som_desligado

func _on_botao_play_pressed():
	print("DEBUG: _on_botao_play_pressed foi chamado!")
	
	if is_instance_valid(video_player) and is_instance_valid(botao_play) and is_instance_valid(botao_pause):
		
		video_player.paused = false
		video_player.call_deferred("play")
		
		# AÇÃO: Esconde Play, Mostra Pause
		botao_play.hide()
		botao_pause.show()

func _on_botao_pause_pressed():
	print("DEBUG: Botão de Pausa pressionado!")
	
	if is_instance_valid(video_player) and is_instance_valid(botao_play) and is_instance_valid(botao_pause):
		
		# AÇÃO: Pausa o vídeo
		video_player.paused = true
		

		botao_pause.hide()
		botao_play.show()


func _on_video_stream_player_finished():
	
	if is_instance_valid(video_player):
		# Paramos o vídeo (volta ao primeiro frame)
		video_player.stop()
		
	if is_instance_valid(botao_play):
		# Mostramos o botão de play novamente
		botao_play.show()
		
	# NOVO: Escondemos o botão de pausa se o vídeo terminar
	if is_instance_valid(botao_pause):
		botao_pause.hide()

func _on_check_button_pressed() -> void:
	pass # Replace with function body.
