extends Control

@onready var narracao_player = $NarracaoPlayer
@onready var area_placa = $AreaPlaca # O nó que criamos no Passo 1
@onready var label_explicacao = $AreaPlaca/LabelTexto
# Referências aos botões de navegação...

var textos = {
	1: "Nosso acordo: manter tudo limpo para todos brincarem!",
	2: "Nosso acordo: tratar todo mundo com carinho e respeito!",
	3: "Nosso acordo: a fila é justa e todo mundo espera a sua vez!"
}

# --- FUNÇÃO READY ---
func _ready():
	atualizar_icone_som()

	# Configura o texto de instrução inicial
	if label_explicacao:
		# DICA: Como mudamos a mecânica, sugiro usar "Arraste" em vez de "Toque"
		label_explicacao.text = "Ajude a coruja a preencher a placa da turma. Arraste um acordo para descobrir sua regra."
		
		# Garante que esteja visível
		label_explicacao.visible = true 
		
		# Garante a cor correta (caso tenha mudado para preto no teste anterior)
		label_explicacao.modulate = Color.WHITE # Ou a cor que você definiu no LabelSettings
	
	# Conecta o sinal da placa
	if area_placa:
		area_placa.regra_recebida.connect(_on_placa_recebeu_regra)

# --- FUNÇÃO DA PLACA ---
func _on_placa_recebeu_regra(id):
	print("PASSO 2: O sinal chegou no script principal! ID: ", id) # Espião 2
	
	label_explicacao.text = textos[id]
	label_explicacao.visible = true
	# ... resto da sua animação
	# --- CÓDIGO DE TESTE VISUAL (Apague depois que funcionar) ---
	label_explicacao.modulate = Color.BLACK # Força a cor preta
	label_explicacao.z_index = 10 # Força ficar na frente de tudo
	label_explicacao.scale = Vector2(1.5, 1.5) # Reseta tamanho caso esteja minúsculo
	# ------------------------------------------------------------
# Animação aplicada direto no texto
	var t = create_tween()
	label_explicacao.scale = Vector2(0.5, 0.5)
	t.tween_property(label_explicacao, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)
	
	
# --- Mantenha suas funções de navegação e som abaixo ---
func _on_botao_avancar_pressed():
	GerenciadorGlobal.avancar_pagina()

func _on_botao_retroceder_pressed():
	GerenciadorGlobal.retroceder_pagina()

# --- DECLARAÇÃO DE VARIÁVEIS (Lá em cima) ---
@onready var botao_som = $TextureRect/BotaoSom # Caminho corrigido (sem TextureRect antes)

# Carregar as imagens (Ajuste o caminho se precisar!)
var img_som_ligado = preload("res://assets/imagens/icone_som_ligado.png") 
var img_som_desligado = preload("res://assets/imagens/icone_som_desligado.png")

# --- FUNÇÃO DE CLIQUE (Conecte o sinal "pressed" do botão aqui) ---
func _on_botao_som_pressed():
	
	# 2. Alterna o estado global do som
	GerenciadorGlobal.toggle_som()
	
	# 3. Controla a narração atual (se existir)
	if narracao_player:
		if GerenciadorGlobal.is_stopped:
			narracao_player.stop()
		else:
			# Opcional: Se quiser que volte a tocar de onde parou
			# narracao_player.play() 
			pass
			
	# 4. Troca a imagem do botão
	atualizar_icone_som()


# --- FUNÇÃO AUXILIAR PARA TROCAR O ÍCONE ---
func atualizar_icone_som():
	if not botao_som: return

	var som_esta_ligado = not GerenciadorGlobal.is_stopped
	var imagem_correta = img_som_ligado if som_esta_ligado else img_som_desligado
	
	# Verifica qual tipo de botão você está usando para aplicar a imagem certa
	if botao_som is TextureButton:
		botao_som.texture_normal = imagem_correta
	elif botao_som is Button: # Se for um botão padrão do Godot
		botao_som.icon = imagem_correta
