.nolist
.include "m328def.inc"

; === Definicoes de registradores ===
.def adc_low      = r15 ; registrador para guardar a parte baixa da leitura ADC
.def adc_high     = r17 ; registrador para guardar a parte alta da leitura ADC
.def temp_low     = r18 ; registrador temporario para a parte baixa do ADC
.def temp_high    = r19 ; registrador temporario para a parte alta do ADC
.def counter4     = r23 ; registrador temporario para comparacoes
.def modo_atual   = r24 ; guarda o modo de operacao atual (1, 2 ou 3)
.def counter2     = r25 ; registrador temporario para comparacoes
.def counter_time = r28 ; contador de tempo para a interrupcao do timer
.def seco         = r30 ; flag que indica se o solo esta seco (1) ou nao (0)

; === Constantes ===
.equ min          = 10  ; constante para o modo 2 (equivalente a um tempo)
.equ cinco_min    = 75  ; constante para o modo 3 (equivalente a cinco minutos)

; === Vetores de interrupcao ===
.org 0x0000
    rjmp main           ; pula para a rotina principal no reset

.org 0x002
    jmp INT0_ISR        ; pula para a rotina de servico da interrupcao externa INT0

.org 0x001A
    jmp TIMER1_OVF_ISR  ; pula para a rotina de servico da interrupcao de overflow do timer1

; === Funcao principal ===
main:
    ldi r20, 0xFF
    out DDRD, r20       ; configura PORTD como saida
    out DDRB, r20       ; configura PORTB como saida
    cbi DDRD, 2         ; configura o pino PD2 (INT0) como entrada
    sbi PORTD, 2        ; ativa o resistor de pull-up interno em PD2

    ldi counter2, 0
    ldi adc_high, 0
    ldi modo_atual, 1     ; inicia no modo 1
    ldi counter_time, 0   ; zera contador de tempo

; === Inicializacao do ADC ===
iniciar_adc:
    ldi r16, high(RAMEND) ; inicializa o ponteiro da pilha (stack pointer) parte alta
    out SPH, r16
    ldi r16, low(RAMEND)  ; inicializa o ponteiro da pilha (stack pointer) parte baixa
    out SPL, r16

    cbi DDRC, 0           ; configura o pino PC0 (ADC0) como entrada
    ldi temp_low, (1<<REFS0) ; seleciona AVcc como tensao de referencia do ADC
    sts ADMUX, temp_low
    ; ativa o ADC, define o prescaler para 128 e inicia a primeira conversao
    ldi temp_low, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)|(1<<ADSC)
    sts ADCSRA, temp_low

; === Inicializacao do LCD ===
iniciar_lcd:
    rcall delay_ms_display_ligar
    ldi   R16, 0x33         ; comando para inicializar o LCD
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi   R16, 0x32         ; comando para inicializar o LCD
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi   R16, 0x28         ; define o modo de 4 bits, 2 linhas, matriz 5x8
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi   R16, 0x0C         ; liga o display, desliga o cursor
    rcall enviar_comando_lcd
    ldi   R16, 0x01         ; limpa o display
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi   R16, 0x06         ; modo de entrada: incrementa o cursor, sem deslocar o display
    rcall enviar_comando_lcd

; === Inicializacao da INT0 ===
inciar_int0:
    ldi r20, (1<<ISC01)     ; configura INT0 para disparar na borda de descida
    sts EICRA, r20
    ldi r20, (1<<INT0)      ; habilita a interrupcao externa INT0
    out EIMSK, r20
    sei                     ; habilita interrupcoes globais

; === Inicializacao do Timer1 ===
iniciar_timer:
    ; carrega o valor inicial do contador timer1 (aqui carrega 0)
    ldi temp_low, low(0x10000)
    sts TCNT1L, temp_low
    ldi temp_low, high(0x10000)
    sts TCNT1H, temp_low
    ldi temp_low, 0
    sts TCCR1A, temp_low    ; modo de operacao normal
    ldi temp_low, (1<<CS12)|(1<<CS10) ; define o prescaler para 1024
    sts TCCR1B, temp_low
    ldi temp_low, (1<<TOIE1) ; habilita a interrupcao de overflow do timer1
    sts TIMSK1, temp_low

; === Inicio da leitura do ADC ===
escrever_lcd:
    rjmp ler_adc            ; comeca o loop principal de leitura

; === Mensagens no LCD ===
mensagem_seco:
    ldi R16, 0x80           ; move o cursor para o inicio da primeira linha
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar

    ldi R16, 'E'        ; escreve "Esta Seco!"
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 's'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 't'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'a'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, ' '
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'S'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'e'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'c'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'o'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, '!'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, ' '
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, ' '
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, ' '
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 0xC0           ; move o cursor para o inicio da segunda linha
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ret

mensagem_umido:
    ldi R16, 0x80           ; move o cursor para o inicio da primeira linha
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar

    ldi R16, 'E'        ; escreve "Esta Molhado!"
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 's'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 't'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'a'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, ' '
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'M'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'o'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'l'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'h'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'a'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'd'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'o'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, '!'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, ' '
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 0xC0           ; move o cursor para o inicio da segunda linha
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ret

mensagem_nseco:
    ldi R16, 0x80           ; move o cursor para o inicio da primeira linha
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar

    ldi R16, 'E'        ; escreve "Esta Umido!"
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 's'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 't'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'a'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, ' '
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'U'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'm'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'i'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'd'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, 'o'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, '!'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, ' '
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, ' '
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ldi R16, ' '
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 0xC0           ; move o cursor para o inicio da segunda linha
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ret
; === Leitura ADC e classificacao ===
ler_adc:
    lds r20, ADCSRA
    ori r20, (1 << ADSC)    ; inicia uma nova conversao ADC
    sts ADCSRA, r20

esperar_adc:
    lds r21, ADCSRA
    sbrs r21, 4             ; espera a conversao terminar verificando a flag ADIF
    rjmp esperar_adc
    lds r21, ADCSRA
    ori r21, (1 << ADIF)    ; limpa a flag de interrupcao do ADC (escrevendo 1 nela)
    sts ADCSRA, r21

    lds adc_low, ADCL       ; le a parte baixa do resultado do ADC
    lds adc_high, ADCH      ; le a parte alta do resultado do ADC
    ldi seco, 0             ; assume que nao esta seco

    mov temp_low, adc_low
    mov temp_high, adc_high

    ; compara o valor do ADC com 900
    ; valores altos indicam que o solo esta seco
    ldi counter2, low(900)
    ldi counter4, high(900)
    cp  temp_low, counter2
    cpc temp_high, counter4
    brsh show_seco          ; se ADC >= 900, pula para show_seco

    ; compara o valor do ADC com 400
    ; valores baixos indicam que o solo esta molhado
    ldi counter2, low(400)
    ldi counter4, high(400)
    cp  temp_low, counter2
    cpc temp_high, counter4
    brlo show_umido         ; se ADC < 400, pula para show_umido

show_nseco:
    ; se o valor estiver entre 400 e 900, e considerado umido
    rcall mensagem_nseco
    rjmp fim_adc

show_umido:
    rcall mensagem_umido
    rjmp fim_adc

show_seco:
    ldi seco, 1             ; define a flag 'seco' como verdadeira
    rcall mensagem_seco

fim_adc:
    ; exibe o modo atual na segunda linha do LCD
    ldi R16, 0xC0           ; move o cursor para o inicio da segunda linha
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar

    ldi r16, 48             ; 48 e o codigo ASCII para '0'
    add r16, modo_atual     ; converte o numero do modo para o caractere ASCII correspondente
    rcall enviar_dado_lcd
    rcall delay_ms_display_ligar

    rjmp ler_adc            ; repete o processo

; === Envia comando para LCD ===
enviar_comando_lcd:
    mov R27, R16
    andi R27, 0xF0          ; mascara os 4 bits mais significativos
    in  r20, PORTD
    andi r20, 0x0F          ; mantem os 4 bits menos significativos de PORTD
    or  r27, r20            ; combina os bits
    out PORTD, R27          ; envia os 4 bits mais significativos para o LCD

    cbi PORTB, 1            ; RS = 0 para comando
    sbi PORTB, 0            ; E = 1 (pulso de enable, inicio)
    rcall delay_short
    cbi PORTB, 0            ; E = 0 (pulso de enable, fim)
    rcall delay_us

    mov R27, R16
    swap R27                ; troca os nibbles (4 bits) do registrador
    andi R27, 0xF0          ; mascara os 4 bits (agora) mais significativos
    in  r20, PORTD
    andi r20, 0x0F
    or  r27, r20
    out PORTD, R27          ; envia os 4 bits menos significativos para o LCD

    sbi PORTB, 0            ; E = 1 (pulso de enable, inicio)
    rcall delay_short
    cbi PORTB, 0            ; E = 0 (pulso de enable, fim)
    rcall delay_us
    ret

; === Envia caractere para LCD ===
enviar_dado_lcd:
    mov R27, R16
    andi R27, 0xF0          ; mascara os 4 bits mais significativos
    in  r20, PORTD
    andi r20, 0x0F
    or  R27, r20
    out PORTD, R27          ; envia os 4 bits mais significativos

    sbi PORTB, 1            ; RS = 1 para dado
    sbi PORTB, 0            ; E = 1 (pulso de enable, inicio)
    rcall delay_short
    cbi PORTB, 0            ; E = 0 (pulso de enable, fim)
    rcall delay_us

    mov R27, R16
    swap R27                ; troca os nibbles
    andi R27, 0xF0          ; mascara os 4 bits (agora) mais significativos
    in  r20, PORTD
    andi r20, 0x0F
    or  R27, r20
    out PORTD, R27          ; envia os 4 bits menos significativos

    sbi PORTB, 0            ; E = 1 (pulso de enable, inicio)
    rcall delay_short
    cbi PORTB, 0            ; E = 0 (pulso de enable, fim)
    rcall delay_us
    ret

; === Interrupcao externa INT0 ===
INT0_ISR:
    push r16                ; salva o registrador r16 na pilha
    in   r16, SREG          ; salva o registrador de status (SREG)
    push r16

    inc modo_atual          ; incrementa o modo de operacao
    cpi modo_atual, 4       ; compara se o modo chegou a 4
    brne fim_int0           ; se nao for 4, continua
    ldi modo_atual, 1       ; se for 4, volta para o modo 1

fim_int0:
    pop r16                 ; restaura o SREG
    out SREG, r16
    pop r16                 ; restaura r16
    reti                    ; retorna da interrupcao

; === Interrupcao Timer1 Overflow ===
TIMER1_OVF_ISR:
    push r16                ; salva contexto na pilha
    push r17
    in   r16, SREG
    push r16

    cpi seco, 1             ; verifica se a flag 'seco' esta em 1
    brlo nao_seco           ; se nao estiver seco, pula para o final

    inc counter_time        ; se estiver seco, incrementa o contador de tempo

    cpi modo_atual, 1
    brne modo2
    rcall tocar_buzzer      ; modo 1: toca o buzzer a cada overflow do timer
    rjmp fim_isr

modo2:
    cpi modo_atual, 2
    brne modo3
    cpi counter_time, min   ; modo 2: compara o tempo com a constante 'min'
    brne fim_isr
    rcall tocar_buzzer      ; se o tempo for atingido, toca o buzzer
    rjmp fim_isr

modo3:
    cpi modo_atual, 3
    brne fim_isr
    cpi counter_time, cinco_min ; modo 3: compara com a constante 'cinco_min'
    brne fim_isr
    rcall tocar_buzzer      ; se o tempo for atingido, toca o buzzer

nao_seco:
    ; se o solo nao estiver seco, reseta o contador do timer e o contador de tempo
    push r20
    ldi  r20, low(0x10000)
    sts  TCNT1L, r20
    ldi  r20, high(0x10000)
    sts  TCNT1H, r20
    ldi  counter_time, 0
    pop  r20

fim_isr:
    pop  r16                ; restaura o contexto da pilha
    out  SREG, r16
    pop  r17
    pop  r16
    reti                    ; retorna da interrupcao

; === Ativa o buzzer ===
tocar_buzzer:
    sbi PORTB, 5            ; liga o buzzer (pino PB5)
    rcall delay_segundos_mensagem ; espera um tempo
    cbi PORTB, 5            ; desliga o buzzer
    ret

; === Funcoes de atraso ===
delay_short:
    nop
    nop
    ret

delay_us:
    ldi  R20, 90
loop1:
    rcall delay_short
    dec  R20
    brne loop1
    ret

delay_ms_display_ligar:
    ldi  R21, 40
loop2:
    rcall delay_us
    dec  R21
    brne loop2
    ret

delay_segundos_mensagem: ; esta e uma rotina de atraso longo, nao necessariamente precisa
    ldi  R20, 255
loop3:
    ldi  R21, 255
loop4:
    ldi  R22, 20
loop5:
    dec  R22
    brne loop5
    dec  R21
    brne loop4
    dec  R20
    brne loop3
    ret