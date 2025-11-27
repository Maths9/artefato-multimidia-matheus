# Script final da Página 5, configurado para usar o acelerômetro do celular.
extends Control

# --- Referências aos Nós ---
@onready var narracao_player = $NarracaoPlayer
@onready var label_feedback = $LabelFeedback
@onready var prancha = $MundoDaFisica/Prancha
@onready var leo = $MundoDaFisica/Prancha/Leo
@onready var timer_equilibrio = $TimerEquilibrio
@onready var botao_som = $TextureRect/BotaoSom

# --- Constantes e Variáveis ---
const FORCA_MOVIMENTO = 4000.0 # Força ajustada para o controle
const FORCA_DESEQUILIBRIO = 1000.0
const ANGULO_TOLERANCIA = 2.0
const LIMITE_ROTACAO_GRAUS = 25.0
const LIMITE_POSICAO_LEO = 450.0
var equilibrio_alcancado = false
var icone_som_ligado = preload("res://assets/imagens/icone_som_ligado.png") 
var icone_som_desligado = preload("res://assets/imagens/icone_som_desligado.png")

func _ready():
	if timer_equilibrio:
		timer_equilibrio.wait_time = 3.0
		timer_equilibrio.one_shot = true
	if label_feedback:
		label_feedback.text = "Incline o celular para encontrar o equilíbrio."
	atualizar_icone_som()
	if narracao_player and not GerenciadorGlobal.is_stopped:
		narracao_player.play()
	call_deferred("aplicar_forca_inicial")

func _physics_process(delta):
	if not leo or not prancha or not timer_equilibrio: return
	if equilibrio_alcancado: return

	# --- LÓGICA REAL DO ACELERÔMETRO (ATIVA) ---
	# As linhas de simulação do teclado foram comentadas.
	# var inclinacao = 0.0
	# if Input.is_action_pressed("ui_right"): inclinacao = 0.5
	# if Input.is_action_pressed("ui_left"): inclinacao = -0.5
	
	# A linha que lê o sensor de inclinação do celular está ativa.
	var inclinacao = Input.get_accelerometer().x
	
	var forca_leo = Vector2(inclinacao * FORCA_MOVIMENTO, 0)
	leo.apply_central_force(forca_leo)
	
	# --- O resto do código permanece o mesmo ---
	if leo.position.x > LIMITE_POSICAO_LEO:
		leo.position.x = LIMITE_POSICAO_LEO
		leo.linear_velocity.x *= -0.4
	elif leo.position.x < -LIMITE_POSICAO_LEO:
		leo.position.x = -LIMITE_POSICAO_LEO
		leo.linear_velocity.x *= -0.4

	var rotacao_atual_graus = rad_to_deg(prancha.rotation)
	if rotacao_atual_graus > LIMITE_ROTACAO_GRAUS:
		prancha.rotation_degrees = LIMITE_ROTACAO_GRAUS
		prancha.angular_velocity = 0
	elif rotacao_atual_graus < -LIMITE_ROTACAO_GRAUS:
		prancha.rotation_degrees = -LIMITE_ROTACAO_GRAUS
		prancha.angular_velocity = 0

	var rotacao_em_graus = rad_to_deg(prancha.rotation)
	if abs(rotacao_em_graus) < ANGULO_TOLERANCIA:
		if timer_equilibrio.is_stopped():
			timer_equilibrio.start()
			if label_feedback:
				label_feedback.text = "Mantenha o equilíbrio..."
	else:
		if not timer_equilibrio.is_stopped():
			timer_equilibrio.stop()
			if label_feedback:
				label_feedback.text = "Mantenha o dispositivo estável para encontrar o equilíbrio."

func aplicar_forca_inicial():
	if not prancha: return
	prancha.apply_force(Vector2(0, FORCA_DESEQUILIBRIO), Vector2(300, 0))

# Script pagina_05_conteudo.gd

# ... (todo o resto do seu código permanece igual) ...

func _on_timer_equilibrio_timeout():
	# Re-verificação final para garantir que ainda está equilibrado
	var rotacao_em_graus = rad_to_deg(prancha.rotation)
	if abs(rotacao_em_graus) < ANGULO_TOLERANCIA and not equilibrio_alcancado:
		equilibrio_alcancado = true
		
		# Congela a física imediatamente para garantir a estabilidade
		prancha.freeze = true
		if leo: leo.freeze = true
		
		# --- NOVA LÓGICA DE ANIMAÇÃO COM O LABELFEEDBACK ---
		
		if label_feedback:
			# 1. Prepara o texto de celebração
			label_feedback.text = "Equilíbrio!"
			# Opcional: Centraliza o texto para a animação ficar mais bonita
			label_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			# 2. Cria um Tween para animar o texto
			var tween = create_tween()
			tween.set_parallel(false) # Garante que as animações aconteçam em sequência
			
			# Animação de "Pop-up" e destaque
			tween.tween_property(label_feedback, "scale", Vector2(1.5, 1.5), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(label_feedback, "modulate", Color.YELLOW, 0.2) # Pisca para amarelo
			tween.tween_property(label_feedback, "modulate", Color.WHITE, 0.2) # Volta para branco
			
			# Espera um pouco com a palavra "Equilíbrio!" na tela
			tween.tween_interval(0.5)
			
			# 3. Prepara a transição para o texto final
			# Animação de "fade out" do texto de celebração
			tween.tween_property(label_feedback, "modulate:a", 0.0, 0.3)
			
			# 4. Quando o "fade out" terminar, troca o texto e faz o "fade in"
			# Usamos um "await" para garantir a sequência correta
			await tween.finished
			
			# Troca o texto para a mensagem de reflexão
			label_feedback.text = "O equilíbrio foi alcançado. A consciência, quando usada, tem o poder de harmonizar nossas ações."
			# Opcional: Volta o alinhamento para a esquerda, se preferir
			label_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			label_feedback.scale = Vector2(1, 1) # Reseta a escala
			
			# Cria um novo Tween para o "fade in" do texto final
			var tween_final = create_tween()
			tween_final.tween_property(label_feedback, "modulate:a", 1.0, 0.5)
			
		else:
			# Fallback: Se o label não existir, apenas congela a física
			print("Equilíbrio alcançado, mas o LabelFeedback não foi encontrado.")

# ... (o resto do seu código, como as funções de navegação, continua aqui) ...

# --- Funções de Navegação e Som ---
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
	if GerenciadorGlobal.get("is_stopped") == true:
		if botao_som is TextureButton: botao_som.texture_normal = icone_som_desligado
	else:
		if botao_som is TextureButton: botao_som.texture_normal = icone_som_ligado
