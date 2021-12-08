#	Trabalho 02 - Opção 02 Jogo - Disciplina de Organização e arquitetura de computadores
#	Dupla:
#	Beatriz	Helena Dias Rocha	NUSP:	11300051
#	Rafael Kuhn Takano		NUSP:	11200459
#
#	Descrição da aplicação:
#	Jogo semelhante ao famoso flappy bird, implementando em MIPS
#	Utilizando o bitmap display com a resolução de blocos 8x8 em uma tela de 256 x 256
#	e o Keyboard MMIO Simulator, oferecido pelo MARS(Mips Assembly and Runtime Simulator)
#	Controles:
#	tecla 'a': o passaro sobe
#	tecla 'z': o passaro desce
#	sem inputs ele continua na mesma altura 

.data
	#Espaço usado pelo display bitmap, onde os gráficos são desenhados  
	display:		.space	4096
	
	#Codigo hexadecimal das cores utilizadas no jogo
	verdeCano:		.word 	0x4cff00
	verdeEscuro:		.word 	0x00b512
	birdColor:		.word	0xffff00
	background1: 		.word 	0x05C6FF
	background2: 		.word 	0x37D6E8
	background3: 		.word 	0xC9F9FF
	
	#Coordenada Y da posição do passaro, que se mantem fixo na coordena X = 1
	bird:			.word 	16
	
	#Coordenadas do canos que aparecem na tela, o cano inicial sempre começa com X = 32, Y = 13
	cano1:			.word	0
	cano2:			.word	0
	cano3:			.word	0x0d20
	
	#Pontuação medida pelo numero de canos ultrapassados
	score:			.word	0
	
	#indicador da direção em que o passaro deve seguir(subir ou descer)
	direcao: 		.word	0
	
	#Frase exposta ao fim do jogo, junto com a pontuação final no console
	frase_gameover:		.asciiz "Sua pontuação final foi: "		

.text

#Loop do Jogo 
game_loop:

	#Modifica a memoria do display bitmap
	jal		atualiza_tela
	
	#Checa colisão, move o passaro e os canos
	jal		update_logic	
	
	#Checa se ultrapassou um cano e incrementa a pontuação
	jal		pontuacao
	
	#Delay entre os loops do jogo
	li		$t1,0x30000
delay:
	add 		$t1, $t1,-1
	bnez		$t1, delay
	
	#Acessa a memoria do Keyboard MMIO
	jal 		recebe_input
	
	#Reinicia o Loop
	j		game_loop	

#Modifica a memoria do display bitmap para o frame atual
atualiza_tela:

	#Guarda endereço de retorno na pilha do $sp
	addiu		$sp,$sp,-4
	sw		$ra,($sp)
	
	#pinta o background
	jal		pinta_fundo
	
	#pinta o passaro
	jal		pinta_bird
	
	#pinta os canos
	jal		pinta_canos
	
	#Recupera o endereço de retorno da pilha
	lw		$ra,($sp)
	addiu		$sp,$sp,4
	
	#retorna ao GameLoop
	jr		$ra

#pinta o background
pinta_fundo:
	#obtem-se o endereço do display
	la 		$a0, display
	
	#recebe os dados da cor 1 do background
	lw		$t1, background1
	li		$t2, 640	
	
pinta_f_loop1:
	#pinta a parte do background com a cor 1
	sw		$t1,($a0)
	add		$a0,$a0,4
	sub		$t2,$t2,1
	bnez 		$t2, pinta_f_loop1
	
	#recebe os dados da cor 2 do background
	lw		$t1, background2
	li		$t2, 256	
	
pinta_f_loop2:
	#pinta a parte do background com a cor 2
	sw		$t1,($a0)
	add		$a0,$a0,4
	sub		$t2,$t2,1
	bnez 		$t2, pinta_f_loop2

	#recebe os dados da cor 3 do background	
	lw		$t1, background3
	li		$t2, 128	
	
pinta_f_loop3:
	#pinta a parte do background com a cor 3
	sw		$t1,($a0)
	add		$a0,$a0,4
	sub		$t2,$t2,1
	bnez 		$t2, pinta_f_loop3
	
	#retorna ao atualiza_tela										
	jr 		$ra	

#pinta os canos
pinta_canos:

	#inicia t2 como a qtde de canos e a0 como o endereço o cano1
	li		$t2, 3
	la 		$a0, cano1
	 	
	#Guarda endereço de retorno na pilha do $sp 	
	addiu		$sp,$sp,-4
	sw		$ra,($sp)
	
pinta_cs_loop:
	
	#pinta um cano na tela
	jal		pinta_cano
	
	#passa para o endereço dos dados do proximo cano e diminui o contador de canos
	add		$a0,$a0,4
	sub		$t2,$t2,1
	bnez 		$t2, pinta_cs_loop
	
	#Recupera o endereço de retorno da pilha
	lw		$ra,($sp)
	addiu		$sp,$sp,4
	
	#retorna ao atualiza_tela
	jr		$ra

#pinta um cano individualmente
pinta_cano:

	#salva a cor dos canos
	lw		$t3, verdeCano
	lw 		$t4, verdeEscuro	
	
	#inicia a altura que esta sendo pintada e os dados do cano
	li		$t5, 0		#altura do cano
	lb		$t6, ($a0)	#X
	lb		$t7, 1($a0)	#Y
	
	#recebe o endereço do display
	la		$a1, display

	#descobre os limites em que nada será pintado
	add		$t8, $t7, 2
	add		$t9, $t7, -2
	
	#Posiciona o endereço do a1 no X correto
	mul		$t1, $t6, 4
	add		$a1, $a1, $t1
		
pinta_c_loop:
	
	#se o cano nao exista, ou seja, possui o valor 0, nao o pinta
	beqz		$t7, fim_c_loop			
	
	#caso o endereço do display esteja acima do limite inferior do buraco no cano passa para a proxima verificação 
	bge  		$t5, $t9, verifica_buraco 			

pixel1:
	
	#caso o cano não esteja na extremidade à esquerda da tela desenha o primeiro pixel da fileira	
	beqz		$t6, pixel2					
  	sw		$t3,-4($a1)		
  	
pixel2:

	#caso o cano não esteja com o pixel2 fora da tela o desenha
  	beq		$t6, 32, pixel3  	
 	sw		$t3,($a1) 	
 	
pixel3: 	

	#caso o cano não esteja com o pixel3 fora da tela o desenha
 	bge  		$t6, 31, prox_fileira_c_loop
	sw		$t4,4($a1)
		
	j		prox_fileira_c_loop
	
verifica_buraco:
	#caso o endereço do display esteja acima do limite superior do buraco pinta a linha do cano, caso não vai para a proxima linha
	bgt 		$t5, $t8, pixel1
				

prox_fileira_c_loop:
	#passa o endereço para a proxima fireira e aumenta o contador de altura
	add		$t5, $t5, 1
	add		$a1, $a1, 128
	bne		$t5, 32, pinta_c_loop
		 
fim_c_loop:	
	#retorna ao atualiza_tela	 
 	jr		$ra 			

#Pinta o passaro
pinta_bird:
	#recebe os dados do passaro e sua cor
	lw		$t1, bird
	lw		$t2, birdColor
	
	#posiciona o endereço do display no X correto
	la		$a0, display+4
	
	#posiciona o endereço do display no Y correto
	add		$t1, $t1, -1
	mul		$t1, $t1, 128	
	add		$a0, $t1, $a0
	
	#pinta o pixel da primeira fileira
	sw		$t2, ($a0)
	add		$a0, $a0, 128
	
	#pinta o pixeis da segunda fileira
	sw		$t2, ($a0)	
	sw		$t2, 4($a0)	
	add		$a0, $a0, 128
	
	#pinta o pixel da terceira fileira
	sw		$t2, ($a0)
	
fim_b_loop:
	#retorna ao atualiza_tela
	jr 		$ra

#Le o valor obtido pelo MMIO 
recebe_input:

	#Le e limpa o endereço do MMIO
        lw 		$v0, 0xffff0004
        li 		$t1, 0
        sw		$t1, 0xffff0004	
        
        #faz um branch de acordo com o que foi lido no MMIO
	beq		$v0, 97, sobe
	beq		$v0, 122, desce
	
#Caso o valor lido nao seja nem 'a' ou 'z' salva 0 em direcao
no_lugar:
	sw		$t1, direcao
	j 		fim_recebe_input

#Caso o valor lido seja 'z' salva 1 em direcao
desce:
	li 		$t1, 1
	sw		$t1, direcao
	j 		fim_recebe_input	

#Caso o valor lido seja 'a' salva 2 em direcao
sobe:
	li 		$t1, 2
	sw		$t1, direcao
	j 		fim_recebe_input

fim_recebe_input:
	#retorna ao GameLoop      
        jr 		$ra
        
#Atualiza os dados do jogo
update_logic:

	#Guarda endereço de retorno na pilha do $sp
	addiu		$sp,$sp,-4
	sw		$ra,($sp)

#Verifica colisão e caso ela ocorra realiza o game_over
checa_colisao:
	
	#le os valores do passaro e posiciona o endereço do display no ponto certo
	lw		$t1, bird
	la		$a0, display+4
	add 		$t1, $t1, -1
	mul		$t1, $t1, 128
	add		$a0, $t1, $a0
	
	#para cada pixel do passaro verifica se o cano sobrepos o passaro, ou seja, checa se os pixeis que devem ser amarelos continuam sendo amarelos
	lw		$t2, ($a0)
	bne		$t2, 0xffff00, game_over
	add		$a0, $a0, 128
	lw		$t2, ($a0)	
	bne		$t2, 0xffff00, game_over
	lw		$t2, 4($a0)	
	bne		$t2, 0xffff00, game_over
	add		$a0, $a0, 128
	lw		$t2, ($a0) 
	bne		$t2, 0xffff00, game_over

#Move o passaro para cima ou para baixo		
desloca_bird:

	#le o valor em direcao, caso 1 aumenta o valor da variavel bird, o deslocando para baixo na tela, caso 2 diminui o valor da variavel bird, o deslocando para cima  
	lw		$t1, direcao
	beq 		$t1,1, para_baixo
	beq 		$t1,2, para_cima
	j		move_canos
	
para_baixo:
	lw		$t1,bird
	
	#se $t1 é 31, o passaro esta na encostado na parte de baixo da tela, logo nao abaixa mais
	beq		$t1, 31, move_canos
	add		$t1,$t1,1
	sw		$t1,bird
	j		move_canos

para_cima:
	lw		$t1,bird
	
	#se $t1 é 1, o passaro esta na encostado na parte superior da tela, logo nao sobe mais
	beq		$t1, 1, move_canos
	add		$t1,$t1,-1
	sw		$t1,bird	
	j		move_canos
	
#Move todos os canos um pixel para a esquerda
move_canos:

	#inicia a qtde de canos e os dados do primeiro cano
	li		$t1, 3
	la		$a0, cano1
move_canos_loop:

	#move o cano de $a0
	jal		move_cano
	
	#diminui o contador de canos e passa para o proximo
	add		$t1,$t1,-1
	add		$a0,$a0,4
	bnez 		$t1, move_canos_loop
	
	#se o cano3 estiver no X = 21 adiciona um novo cano na tela e exclui o cano na extremidade a esquerda
	lb		$t1, cano3
	bne		$t1, 21, fim_update_logic
	jal 		cria_cano
	
fim_update_logic:
	#Recupera o endereço de retorno da pilha
	lw		$ra,($sp)
	addiu		$sp,$sp,4
	
	#retorna ao GameLoop
	jr 		$ra

#le a variavel X do cano e decrementa ela em uma un unidade
move_cano:
	lb		$t2,($a0)
	beqz 		$t2, move_cano_volta
	add		$t2,$t2,-1
	sb		$t2,($a0)

move_cano_volta:
	#retorna ao move_canos_loop	
	jr 		$ra

#Conta a pontuação caso o passaro ultrapasse um cano
pontuacao:
	#caso o cano1 esteja logo em cima do passaro incrementa a variavel score em uma unidade
	lb		$t1,cano1
	bne		$t1, 1, fim_pontuacao

	lw		$t1, score
	add		$t1, $t1, 1
	sw		$t1, score	
				
fim_pontuacao:
	#retorna ao GameLoop
	jr		$ra

#Desenha a tela de fim de jogo com as cores do background invertidas, escreve a pontuação do jogador no console e finaliza o programa
game_over:
	
	#delay para o jogador notar a colisao
	li		$t1,0x60000
delay2:
	add 		$t1, $t1,-1
	bnez		$t1, delay2
	
	#pinta-se a tela com as cores do background invertidas, da mesma maneira que pinta_fundo, logo não seram repetidos os comentários
	la 		$a0, display
	lw		$t1, background1
	neg		$t1, $t1
	li		$t2, 640	
	
pinta_go_loop1:
	sw		$t1,($a0)
	add		$a0,$a0,4
	sub		$t2,$t2,1
	bnez 		$t2, pinta_go_loop1
	
	lw		$t1, background2
	neg		$t1, $t1
	li		$t2, 256	
	
pinta_go_loop2:
	sw		$t1,($a0)
	add		$a0,$a0,4
	sub		$t2,$t2,1
	bnez 		$t2, pinta_go_loop2
	
	lw		$t1, background3
	neg		$t1, $t1
	li		$t2, 128	
	
pinta_go_loop3:
	sw		$t1,($a0)
	add		$a0,$a0,4
	sub		$t2,$t2,1
	bnez 		$t2, pinta_go_loop3
			
	#Escreve a string de fim de jogo no console		
	li		$v0, 4
	la		$a0, frase_gameover
	syscall
	
	#Escreve o score no console
	li		$v0, 1
	lw		$a0, score
	syscall
	
	#Finaliza o programa
	li 		$v0,10
	syscall
	
#Cria um novo cano quando o cano1 chega no X = 0
cria_cano:
	#Le o Y do cano3
	lb		$t1, cano3+1
	
	#Gera um inteiro aleatorio entre 0 e 13
	li		$v0, 42
	li		$a1, 0xe
	syscall

	#Define o Y = do novo cano e mantem esse valor dentro da tela
	add		$t1,$t1,$a0	
	sub		$t1,$t1,7				
	bge 		$t1, 0x1d, limite_superior	 
	blt		$t1, 0x03, limite_inferior
	
#Passa o cano2 para o 1, o 3 para o 2 e o novo para o 3
limite_return:
	lw 		$t2, cano2
	sw		$t2, cano1
	lw 		$t2, cano3
	sw		$t2, cano2
	li 		$t2, 0x20
	sb		$t2, cano3
	sb 		$t1, cano3+1
	
	#retorna ao update_logic
	jr		$ra		

#Define o Y = 29																																																																												
limite_superior:
	li 		$t1, 0x1d
	j		limite_return

#Define o Y = 3	
limite_inferior:
	li		$t1, 0x03
	j		limite_return
					
