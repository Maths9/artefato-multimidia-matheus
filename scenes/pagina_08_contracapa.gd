extends Control

# --- Carregar as texturas dos ícones de Som ---
var icone_som_ligado = load("res://assets/imagens/icone_som_ligado.png") 
var icone_som_desligado = load("res://assets/imagens/icone_som_desligado.png") 

# --- Variável @onready para o Som ---
# ATUALIZADO: Corrigido o caminho para a sua hierarquia da Página 8
@onready var botao_som = $TextureRect/BotaoSom

func _ready():
	# Atualiza o ícone do botão assim que a cena carregar
	atualizar_icone_som()

# --- Funções de Navegação ---
# Conecte o sinal 'pressed' do 'BotaoRetroceder' a esta função
func _on_botao_retroceder_pressed():
	GerenciadorGlobal.retroceder_pagina()

# Conecte o sinal 'pressed' do 'BotaoVoltarInicio' a esta função
# ATUALIZADO para usar 'ir_para_capa'
func _on_botao_voltar_inicio_pressed():
	GerenciadorGlobal.ir_para_capa()

# --- Função de Som ---
# Conecte o sinal 'pressed' do 'BotaoSom' a esta função
func _on_botao_som_pressed():
	GerenciadorGlobal.toggle_som()
	atualizar_icone_som()

func atualizar_icone_som():
	# Esta função verifica o estado no GerenciadorGlobal e muda o ícone
	# ATUALIZADO para usar 'is_stopped'
	if not GerenciadorGlobal.is_stopped:
		botao_som.icon = icone_som_ligado
	else:
		botao_som.icon = icone_som_desligado
