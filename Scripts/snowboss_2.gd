extends CharacterBody2D

# --- ENUMS (Padrão de organização do seu Player) ---
enum BossState {
	PARADO,
	SEGUINDO,
	FUGINDO,
	RAIO,
	DASH,
	MARTELO,
	TRANSICAO,
}
const CORPO_FASE2_SCN = preload("res://Entities/corpo_fase_2.tscn")
const CABECA_FASE2_SCN = preload("res://Entities/cabeca_fase_2.tscn")
var fase_2_ativa: bool = false

# --- REFERÊNCIAS ---
@onready var corpo = $corpo
@onready var cabeca = $cabeca
@onready var anim: AnimatedSprite2D = $corpo/AnimatedSprite2D

const RAIO_SCN = preload("res://Entities/raio_boss.tscn")
const SNOWBALL_SCN = preload("res://Entities/snowball_arc.tscn")

var ultimo_ataque: String = ""
var repeticoes_ataque: int = 0
const LIMITE_REPETICAO = 2 # Permite usar o mesmo no máximo 2 vezes

const SPEED_DASH = 170.0  # Quase o dobro da perseguição
const DURACAO_DASH = 0.6
const DURACAO_MARTELO = 0.8

# Variáveis de Reação
var timer_reacao: float = 0.0
const DELAY_REACAO = 0.2
var direcao_atual: float = 1.0 # Guarda para onde ele está indo agora

var timer_estado: float = 0.0 # Controla quanto tempo ele fica fugindo ou no raio

# Variáveis de Sorteio
var timer_sorteio: float = 0.0
var chance_ataque: float = 0.0
const INCREMENTO_CHANCE = 10.0 # Sobe 10% de chance por segundo

# --- CONFIGURAÇÕES ---
const SPEED_SEGUINDO = 90.0
const FASE2_THRESHOLD = 10.0

# --- VARIÁVEIS DE CONTROLE ---
var status_atual: BossState
var health = 30.0
var player = null

func _ready():
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	go_to_seguindo_state() # Começa perseguindo direto

func _physics_process(delta):
	# Se a vida chegar no limite, trava na transição
	if health <= FASE2_THRESHOLD and status_atual != BossState.TRANSICAO:
		go_to_transicao_state()
		return

	apply_gravity(delta)
	update_state(delta) 
	move_and_slide()

# --- NÚCLEO DA STATE MACHINE ---
func update_state(delta):
	match status_atual:
		BossState.SEGUINDO:
			seguindo_state(delta)
			processar_sorteio_ataque(delta)
		BossState.FUGINDO:
			fugindo_state(delta)
		BossState.RAIO:
			raio_state(delta)
		BossState.DASH:
			dash_state(delta)   # Novo
		BossState.MARTELO:
			martelo_state(delta) # Novo
		BossState.PARADO:
			parado_state()

# =========================================================
# LÓGICA DE MOVIMENTAÇÃO
# =========================================================

func parado_state():
	velocity.x = 0

func seguindo_state(delta): # Adicione o delta aqui se não tiver
	if player:
		# 1. Descobre para onde o player está em relação ao Boss
		var direcao_alvo = sign(player.global_position.x - global_position.x)
		
		# 2. Se o player mudou de lado...
		if direcao_alvo != direcao_atual and direcao_alvo != 0:
			timer_reacao += delta # Começa a contar
			
			# 3. Só vira se o tempo de reação passar
			if timer_reacao >= DELAY_REACAO:
				direcao_atual = direcao_alvo
				timer_reacao = 0.0
		else:
			# Se o player continua no mesmo lado, reseta o timer
			timer_reacao = 0.0
			
		# 4. Aplica a movimentação baseada na direção "decidida"
		velocity.x = direcao_atual * SPEED_SEGUINDO
		
		# 5. Atualiza o visual
		if direcao_atual != 0:
			anim.flip_h = (direcao_atual < 0)
			if corpo.has_method("atualizar_direcao"):
				corpo.atualizar_direcao(direcao_atual)
	else:
		velocity.x = 0


func fugindo_state(delta):
	if player:
		# Lógica de fugir (lado oposto)
		var dir = sign(global_position.x - player.global_position.x)
		velocity.x = dir * SPEED_SEGUINDO
		
		if dir != 0:
			anim.flip_h = (dir < 0)
			if corpo.has_method("atualizar_direcao"):
				corpo.atualizar_direcao(dir)
		
		# CONTADOR MANUAL (Substitui o await)
		timer_estado -= delta
		if timer_estado <= 0:
			go_to_raio_state()

func raio_state(delta):
	velocity.x = 0
	
	# CONTADOR MANUAL
	timer_estado -= delta
	if timer_estado <= 0:
		go_to_seguindo_state()

func dash_state(delta):
	# Ele mantém a velocidade que demos no go_to_dash
	velocity.x = direcao_atual * SPEED_DASH
	
	timer_estado -= delta
	if timer_estado <= 0:
		go_to_martelo_state()

func martelo_state(delta):
	velocity.x = 0 # Para para bater

# =========================================================
# TRANSIÇÕES (Onde você define o que acontece ao mudar de estado)
# =========================================================

func go_to_seguindo_state():
	status_atual = BossState.SEGUINDO
	anim.play("andando") # Nome da sua animação de caminhada
	print("BOSS: Iniciando Perseguição")

func go_to_parado_state():
	status_atual = BossState.PARADO
	anim.play("idle") # Nome da sua animação parado
	
func go_to_fugindo_state():
	status_atual = BossState.FUGINDO
	anim.play("andando")
	timer_estado = 1.5 # Ele vai fugir por 1.5 segundos
	print("BOSS: Fugindo...")
	
	# Espera 1.5 segundos fugindo e então ataca
	await get_tree().create_timer(1.5).timeout
	if status_atual == BossState.FUGINDO: # Checa se ainda está vivo/no estado
		go_to_raio_state()

func go_to_raio_state():
	status_atual = BossState.RAIO
	anim.play("soltando_raio")
	timer_estado = 2.5 # O raio dura 2 segundos
	
	# Vira para o player no início do golpe
	if player:
		var dir = sign(player.global_position.x - global_position.x)
		anim.flip_h = (dir < 0)
		if corpo.has_method("atualizar_direcao"):
			corpo.atualizar_direcao(dir)
			
	print("BOSS: --- RAIO!!! ---")

func go_to_dash_state():
	status_atual = BossState.DASH
	anim.play("andando") # No futuro aqui seria a anim de dash/deslize
	timer_estado = DURACAO_DASH
	
	# Decide a direção do Dash no momento em que começa
	if player:
		direcao_atual = sign(player.global_position.x - global_position.x)
		# Força a virada instantânea para o dash ser preciso
		anim.flip_h = (direcao_atual < 0)
		if corpo.has_method("atualizar_direcao"):
			corpo.atualizar_direcao(direcao_atual)
	
	print("BOSS: DASH!!!")

func go_to_martelo_state():
	status_atual = BossState.MARTELO
	anim.play("martelada") 
	
	if corpo.has_method("set_martelada_ativa"):
		corpo.set_martelada_ativa(true)
		
	print("BOSS: POW! Martelada!")

func go_to_transicao_state():
	status_atual = BossState.TRANSICAO
	velocity = Vector2.ZERO # Para o movimento imediatamente
	
	# 1. Feedback visual de que algo está mudando
	anim.play("idle") # Ou uma animação de "dor" se tiver
	# Um flash branco ou tremor no próprio Boss ajuda na maquiagem
	var tween = create_tween()
	tween.tween_property(corpo, "modulate", Color(10, 10, 10), 0.1)
	tween.tween_property(corpo, "modulate", Color(1, 1, 1), 0.1)
	
	print("BOSS: Iniciando Transição...")

	# 2. O tempo de drama (2 segundos antes de "explodir")
	await get_tree().create_timer(2.0).timeout
	
	# 3. Chama a função que faz a troca das peças
	executar_spawn_fase_2()

func executar_spawn_fase_2():
	# Referências de posição baseadas nos Markers que você criou
	# Usamos global_position para que as novas peças nasçam exatamente onde o corpo/cabeça estavam
	var pos_corpo = $corpo/PontoCorpo.global_position
	var pos_cabeca = $corpo/PontoCabeca.global_position
	var direcao_atual = -1.0 if anim.flip_h else 1.0
	
	# 4. Instanciar as cenas novas
	var corpo_f2 = CORPO_FASE2_SCN.instantiate()
	var cabeca_f2 = CABECA_FASE2_SCN.instantiate()
	
	# 5. Adicionar ao PAI do Boss (o cenário/level)
	# IMPORTANTE: Adicionar ao pai garante que quando o SnowBoss der queue_free, eles continuem lá
	get_parent().add_child(corpo_f2)
	get_parent().add_child(cabeca_f2)
	
	# 6. Definir posições e direções iniciais
	corpo_f2.global_position = pos_corpo
	cabeca_f2.global_position = pos_cabeca
	
	# Se os seus novos inimigos tiverem uma função para setar o lado que olham:
	if corpo_f2.has_method("configurar_inicio"):
		corpo_f2.configurar_inicio(direcao_atual)
	
	# 7. A Maquiagem (Tremor e Partículas)
	# Se você tiver um sistema de partículas de neve, dispare aqui na posição do Boss
	
	print("BOSS: Transformação completa. Removendo SnowBoss original.")
	
	# 8. O Boss original some para sempre
	queue_free()


# =========================================================
# COMBATE
# =========================================================

func processar_sorteio_ataque(delta):
	timer_sorteio += delta
	# A cada 1 segundo, tentamos a sorte
	if timer_sorteio >= 1.0:
		timer_sorteio = 0.0
		chance_ataque += INCREMENTO_CHANCE
		
		print("BOSS: Chance de ataque em ", chance_ataque, "%")
		
		if randf() * 100.0 < chance_ataque:
			decidir_ataque()

func decidir_ataque():
	chance_ataque = 0.0
	
	# 1. Sorteio inicial (0 = Raio/Fuga, 1 = Dash/Martelo)
	var sorteio = randi() % 2
	var ataque_escolhido = ""
	
	if sorteio == 0:
		ataque_escolhido = "raio"
	else:
		ataque_escolhido = "martelo"

	# 2. VERIFICAÇÃO DE REPETIÇÃO
	if ataque_escolhido == ultimo_ataque:
		repeticoes_ataque += 1
	else:
		repeticoes_ataque = 1 # Reset se mudar o ataque
		ultimo_ataque = ataque_escolhido

	# 3. SE EXCEDER O LIMITE, FORÇA O OUTRO ATAQUE
	if repeticoes_ataque > LIMITE_REPETICAO:
		print("BOSS: Ataque ", ataque_escolhido, " repetido demais! Trocando...")
		if ataque_escolhido == "raio":
			ataque_escolhido = "martelo"
		else:
			ataque_escolhido = "raio"
		
		# Atualiza a memória para o novo ataque forçado
		ultimo_ataque = ataque_escolhido
		repeticoes_ataque = 1

	# 4. EXECUÇÃO FINAL
	if ataque_escolhido == "raio":
		go_to_fugindo_state()
	else:
		go_to_dash_state()


func disparar_chuva_bolas():
	print("DEBUG BOSS: Função disparar_chuva_bolas iniciada!")
	
	if not SNOWBALL_SCN:
		print("DEBUG BOSS: ERRO! A cena da bola de neve não foi carregada (SNOWBALL_SCN nula)")
		return

	var ponto = $corpo/PontoImpacto
	if not ponto:
		print("DEBUG BOSS: ERRO! Nó PontoImpacto não encontrado")
		return

	var numero_de_bolas = 16 
	var spot_safe_inicio = randi_range(2, 7) 
	
	print("DEBUG BOSS: Gerando ", numero_de_bolas, " bolas. Safe spot em: ", spot_safe_inicio)
	
	for i in range(numero_de_bolas):
		if i == spot_safe_inicio or i == spot_safe_inicio + 1:
			continue
			
		var bola = SNOWBALL_SCN.instantiate()
		
		# Verificando o ambiente antes de adicionar
		if get_parent():
			get_parent().add_child(bola)
		else:
			print("DEBUG BOSS: ERRO! Boss não tem um nó pai para segurar as bolas")
			add_child(bola) # Tenta adicionar a si mesmo como fallback
		
		bola.global_position = ponto.global_position
		
		var fracao = float(i) / float(numero_de_bolas - 1)
		var direcao_horizontal = lerp(-1.0, 1.0, fracao)
		var forca_x = direcao_horizontal * 350.0 
		var forca_y = -450.0 - (randf() * 150.0) 
		
		if "velocity" in bola:
			bola.velocity = Vector2(forca_x, forca_y)
		else:
			print("DEBUG BOSS: AVISO! A bola instanciada não possui a variável 'velocity'")

	print("DEBUG BOSS: Ciclo de geração concluído!")

func disparar_raio():
	var raio = RAIO_SCN.instantiate()
	
	# Adicionamos ao PAI (Cenário) para o raio ser independente do movimento do Boss
	get_parent().add_child(raio)
	
	# Posicionamos no marcador da boca
	raio.global_position = $corpo/PontoRaio.global_position
	
	# Pegamos a direção BASEADA NO FLIP do sprite do Boss
	var direcao_final = -1.0 if anim.flip_h else 1.0
	
	# Passamos para o raio se configurar
	if raio.has_method("configurar_raio"):
		raio.configurar_raio(direcao_final)

# =========================================================
# SISTEMA
# =========================================================

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += 900 * delta

func take_damage(amount, _pos = Vector2.ZERO, _proj = false):
	health -= amount
	# Feedback visual de dano que mora no script do corpo
	if corpo.has_method("flash_damage"):
		corpo.flash_damage()

func mostrar_aviso_raio():
	var aviso = RAIO_SCN.instantiate()
	get_parent().add_child(aviso)
	
	aviso.global_position = $corpo/PontoRaio.global_position
	var dir = -1.0 if anim.flip_h else 1.0
	
	if aviso.has_method("configurar_como_aviso"):
		aviso.configurar_como_aviso(dir)
