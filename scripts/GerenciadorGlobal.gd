extends Node

var pagina_atual = 1
var total_paginas = 8
var current_page_id = "" 

# --- VARIÁVEL DE SOM ---
var is_stopped = false

# --- VARIÁVEIS DE ÁUDIO ---
var narration_player : AudioStreamPlayer 

# --- Mapeamento de Narrações ---
const NARRACOES_PAGINAS = {
	"pagina_01_capa": "res://assets/narracao/narracao1.mp3", 
	"pagina_02_conteudo": "res://assets/narracao/narracao2.mp3",
	"pagina_03_conteudo": "res://assets/narracao/narracao3.mp3", 
	"pagina_04_conteudo": "res://assets/narracao/narracao4.mp3", 
	"pagina_05_conteudo": "res://assets/narracao/narracao5.mp3", 
	"pagina_06_conteudo": "res://assets/narracao/narracao6.mp3", 
	"pagina_07_conteudo": "res://assets/narracao/narracao7.mp3", 
	"pagina_08_contracapa": "res://assets/narracao/narracao8.mp3", 
}

func _ready():
	# Cria o player de áudio automaticamente
	narration_player = AudioStreamPlayer.new()
	narration_player.name = "NarrationPlayerGlobal"
	add_child(narration_player)
	
	# NOVO: Verifica qual cena está aberta no início do jogo para tocar o som
	call_deferred("verificar_cena_inicial")


# --- Detecção Automática de Início (NOVO) ---

func verificar_cena_inicial():
	var cena_atual = get_tree().current_scene
	if not cena_atual:
		return
		
	var nome_arquivo = cena_atual.scene_file_path # Ex: res://scenes/Pagina_01_Capa.tscn
	
	# Tenta descobrir o ID da página baseado no nome do arquivo
	if "Pagina_01" in nome_arquivo:
		current_page_id = "pagina_01_capa"
		pagina_atual = 1
	elif "Pagina_08" in nome_arquivo:
		current_page_id = "pagina_08_contracapa"
		pagina_atual = 8
	else:
		# Procura por "Pagina_XX" no nome
		for i in range(2, 8):
			var string_busca = "Pagina_%02d" % i
			if string_busca in nome_arquivo:
				current_page_id = "pagina_%02d_conteudo" % i
				pagina_atual = i
				break
	
	# Se encontrou um ID válido, toca o som!
	if current_page_id != "":
		print("DEBUG: Cena inicial detectada:", current_page_id)
		play_narracao(current_page_id)


# --- Funções de Navegação ---

func avancar_pagina():
	if pagina_atual < total_paginas:
		pagina_atual += 1
		carregar_pagina(pagina_atual)

func retroceder_pagina():
	if pagina_atual > 1:
		pagina_atual -= 1
		carregar_pagina(pagina_atual)

func ir_para_capa():
	pagina_atual = 1
	carregar_pagina(pagina_atual)

func carregar_pagina(numero_pagina):
	# 1. Para o áudio anterior imediatamente
	stop_narracao()

	for child in get_tree().get_root().get_children():
		if child.is_in_group("Pagina"):
			child.queue_free()

	var caminho_cena = "res://scenes/Pagina_%02d_Conteudo.tscn" % numero_pagina
	
	if numero_pagina == 1:
		caminho_cena = "res://scenes/Pagina_01_Capa.tscn"
		current_page_id = "pagina_01_capa"
	elif numero_pagina == 8:
		caminho_cena = "res://scenes/Pagina_08_Contracapa.tscn"
		current_page_id = "pagina_08_contracapa"
	else:
		current_page_id = "pagina_%02d_conteudo" % numero_pagina 
		
	var cena_pagina_resource = load(caminho_cena)
	
	if cena_pagina_resource:
		var cena_pagina = cena_pagina_resource.instantiate()
		cena_pagina.add_to_group("Pagina") 
		get_tree().get_root().add_child(cena_pagina)
		
		# Toca a narração AUTOMATICAMENTE aqui na navegação
		play_narracao(current_page_id)
		
	else:
		print("Erro: Não foi possível carregar a cena: ", caminho_cena)


# --- FUNÇÃO DE SOM ---

func toggle_som():
	is_stopped = !is_stopped
	
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), is_stopped)

	if is_stopped:
		stop_narracao()
	else:
		play_narracao(current_page_id)


# --- FUNÇÕES DE ÁUDIO ---

func play_narracao(pagina_id: String):
	stop_narracao()
	
	if is_stopped:
		return

	var audio_path = NARRACOES_PAGINAS.get(pagina_id.to_lower()) 
	
	if audio_path and ResourceLoader.exists(audio_path):
		narration_player.stream = load(audio_path)
		narration_player.play()

func stop_narracao():
	if narration_player and narration_player.is_playing():
		narration_player.stop()
