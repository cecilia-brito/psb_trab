;a ideia principal é se o conversor me der um valor <= 341 ele vai mostrar a carinha triste
;se for maior que 341 e menor que 682 ele vai mostrar a carinha neutra
;se for maior que 682 ele vai mostrar a carinha feliz
;lembrando que o ADC do Arduino é de 10 bits, logo, o valor máximo que ele pode retornar é 1023
;então, 341 é 1/3 de 1023 e 682 é 2/3 de 1023
;isso faz a interrupção de mudança de pino ser acionada dependendo do valor do ADC
;as interrupções vão ser usadas para mostrar os emojis, ou seja, quando o pino
;for ligado, a interrupção vai ser acionada e o emoji correspondente vai ser mostrado
;os pinos que eu vou usar são:
;PD2 - Carinha triste
;PD4 - Carinha neutra
;PB0 - Carinha feliz
;as interrupções que eu vou usar são:
;INT0 - Carinha triste (PD2)
;PCINT0 - Carinha feliz (PB0)
;PCINT2 - Carinha neutra (PD4)
;as interrupções vão ser configuradas para serem acionadas por uma borda de subida
;ou seja, quando o pino for ligado, a interrupção vai ser acionada

.nolist
.include "m328Pdef.inc"
.list

.def adc_low  = r16 ; guarda a parte menos significativa do resultado do ADC
.def adc_high = r17 ; guarda a parte mais significativa do resultado do ADC
.def temp_low = r18 ; temporário
.def temp_high= r19 ; temporário

; --- Definição de Registradores Adicionais para o LCD ---
.def lcd_data_reg = r20 ; Registrador para passar dados/comandos para as funções LCD
.def counter_reg  = r21 ; Registrador para loops, ex: loop de 8 bytes para custom char

; --- Definições de Pinos do LCD (AJUSTADO PARA O SEU .SIM1 NO SIMULIDE) ---
; RS (Register Select): Uno-98-2 -> PD2
; EN (Enable): Uno-98-3 -> PD3
; D4: Uno-98-4 -> PD4
; D5: Uno-98-5 -> PD5
; D6: Uno-98-6 -> PD6
; D7: Uno-98-7 -> PD7
; RW está aterrado no simulador.
.equ LCD_RS_PIN = PD2   ; Pino para Register Select (Dado/Comando)
.equ LCD_EN_PIN = PD3   ; Pino para Enable (Pulso de strobe)

.equ LCD_D4_PIN = PD4   ; Pino de dados D4
.equ LCD_D5_PIN = PD5   ; Pino de dados D5
.equ LCD_D6_PIN = PD6   ; Pino de dados D6
.equ LCD_D7_PIN = PD7   ; Pino de dados D7

; --- Comandos Básicos do LCD (HD44780) ---
.equ LCD_CLEAR_DISPLAY  = 0b00000001
.equ LCD_RETURN_HOME    = 0b00000010
.equ LCD_ENTRY_MODE_SET = 0b00000110 ; Incrementa cursor, sem shift
.equ LCD_DISPLAY_ON_OFF = 0b00001100 ; Display ON, Cursor OFF, Blink OFF
.equ LCD_FUNCTION_SET   = 0b00101000 ; 4-bit mode, 2 lines, 5x8 dots (para inicialização 0x28)
.equ LCD_SET_DDRAM_ADDR = 0b10000000 ; Set DDRAM Address (posição no display)
.equ LCD_SET_CGRAM_ADDR = 0b01000000 ; Set CGRAM Address (para custom chars)

; início rian
.cseg   
sad_face:           ; Será carregado no índice 0 da CGRAM
    .db 0b00000
    .db 0b01010
    .db 0b01010
    .db 0b00000
    .db 0b00000
    .db 0b01110
    .db 0b10001
    .db 0b00000

neutral_face:       ; Será carregado no índice 1 da CGRAM
    .db 0b00000
    .db 0b01010
    .db 0b01010
    .db 0b00000
    .db 0b01110
    .db 0b00000
    .db 0b00000
    .db 0b00000

happy_face:         ; Será carregado no índice 2 da CGRAM
    .db 0b00000
    .db 0b01010
    .db 0b01010
    .db 0b00000
    .db 0b00000
    .db 0b10001
    .db 0b01110
    .db 0b00000

delay_100us: ; 
    ldi r22, 100 ; 
delay_100us_loop:
    nop
    dec r22
    brne delay_100us_loop
    ret

delay_2ms: ; Atraso maior, necessário após alguns comandos LCD
    ldi r23, high(500) ; Estes valores são exemplos para 16MHz.
    ldi r24, low(500)  ; Você pode precisar de mais ou menos iterações.
delay_2ms_loop:
    sbiw r23:r24, 1
    brne delay_2ms_loop
    ret

; --- Funções de Comunicação com o LCD ---

; lcd_toggle_enable: Gera um pulso no pino EN do LCD (Alto -> Baixo)
lcd_toggle_enable:
    sbi PORTD, LCD_EN_PIN ; EN alto
    rcall delay_100us      ; Pequeno atraso para EN
    cbi PORTD, LCD_EN_PIN ; EN baixo
    ret

; lcd_write_nibble: Escreve um nibble (4 bits) nos pinos de dados do LCD (PD4-PD7)
; Entrada: lcd_data_reg (contém o nibble nos 4 bits baixos)
lcd_write_nibble:
    ; Limpa apenas os bits de dados (PD4-PD7) no PORTD
    cbi PORTD, LCD_D4_PIN
    cbi PORTD, LCD_D5_PIN
    cbi PORTD, LCD_D6_PIN
    cbi PORTD, LCD_D7_PIN

    ; Seta os bits de dados no PORTD de acordo com o nibble em lcd_data_reg
    sbrc lcd_data_reg, 0 ; Se bit 0 de lcd_data_reg for 1, liga PD4
    sbi PORTD, LCD_D4_PIN
    sbrc lcd_data_reg, 1 ; Se bit 1 de lcd_data_reg for 1, liga PD5
    sbi PORTD, LCD_D5_PIN
    sbrc lcd_data_reg, 2 ; Se bit 2 de lcd_data_reg for 1, liga PD6
    sbi PORTD, LCD_D6_PIN
    sbrc lcd_data_reg, 3 ; Se bit 3 de lcd_data_reg for 1, liga PD7
    sbi PORTD, LCD_D7_PIN

    rcall lcd_toggle_enable ; Pulsa EN para travar o nibble
    ret

; lcd_send_byte: Envia um byte completo (8 bits) ao LCD em modo 4 bits
; Entrada: lcd_data_reg (contém o byte completo)
lcd_send_byte:
    swap lcd_data_reg         ; Coloca o nibble alto (bits 7-4) nos bits 3-0
    rcall lcd_write_nibble    ; Envia o nibble alto
    swap lcd_data_reg         ; Retorna o nibble alto para sua posição original, nibble baixo (bits 3-0) agora está nos bits 3-0
    rcall lcd_write_nibble    ; Envia o nibble baixo
    ret

; lcd_send_command: Envia um comando ao LCD
; Entrada: lcd_data_reg (contém o comando)
lcd_send_command:
    cbi PORTD, LCD_RS_PIN   ; RS = 0 (modo comando)
    rcall lcd_send_byte     ; Envia o byte do comando
    rcall delay_2ms         ; Atraso para o comando ser processado
    ret

; lcd_send_data: Envia um caractere/dado ao LCD
; Entrada: lcd_data_reg (contém o caractere ASCII ou índice do custom char)
lcd_send_data:
    sbi PORTD, LCD_RS_PIN   ; RS = 1 (modo dado)
    rcall lcd_send_byte     ; Envia o byte do dado
    rcall delay_100us       ; Atraso curto
    ret

; lcd_init: Inicializa o módulo LCD para modo 4-bit
lcd_init:
    ; Configura pinos do LCD como saída (TODOS NO PORTD conforme .sim1)
    sbi DDRD, LCD_RS_PIN
    sbi DDRD, LCD_EN_PIN
    sbi DDRD, LCD_D4_PIN
    sbi DDRD, LCD_D5_PIN
    sbi DDRD, LCD_D6_PIN
    sbi DDRD, LCD_D7_PIN

    cbi PORTD, LCD_RS_PIN ; Garante RS em LOW
    cbi PORTD, LCD_EN_PIN ; Garante EN em LOW

    rcall delay_2ms         ; Espera estabilização (power-on, >15ms recomendado)

    ; Sequência de inicialização do HD44780 para modo 4 bits
    ; Envia 0x03 três vezes para resetar e garantir modo 8 bits primeiro
    ldi lcd_data_reg, 0b00000011 ; Comando 0x03 (apenas o nibble alto importa)
    rcall lcd_write_nibble
    rcall delay_2ms          ; Atraso > 4.1ms

    rcall lcd_write_nibble   ; Comando 0x03 novamente
    rcall delay_100us        ; Atraso > 100us

    rcall lcd_write_nibble   ; Comando 0x03 pela terceira vez
    rcall delay_100us

    ldi lcd_data_reg, 0b00000010 ; Comando 0x02 (seta para modo 4 bits)
    rcall lcd_write_nibble
    rcall delay_100us

    ; Agora o LCD está em modo 4 bits. Enviar comandos completos de 8 bits.
    ldi lcd_data_reg, LCD_FUNCTION_SET ; Function Set: 4-bit, 2 linhas, 5x8 dots
    rcall lcd_send_command

    ldi lcd_data_reg, LCD_DISPLAY_ON_OFF ; Display ON, Cursor OFF, Blink OFF
    rcall lcd_send_command

    ldi lcd_data_reg, LCD_CLEAR_DISPLAY ; Limpa o display
    rcall lcd_send_command

    ldi lcd_data_reg, LCD_ENTRY_MODE_SET ; Entry Mode Set: Incrementa cursor, sem shift
    rcall lcd_send_command

    ret

; lcd_create_char: Carrega um caractere customizado na CGRAM do LCD
; Entrada: lcd_data_reg (índice do char, 0-7)
;          ZH:ZL (endereço inicial do padrão de 8 bytes na memória de programa - Flash)
lcd_create_char:
    push r22            ; Salva registrador usado por LPM
    push r23            ; Salva registrador usado por LPM

    ; Converte o índice do char para o endereço de CGRAM
    lsl lcd_data_reg    ; * 2
    lsl lcd_data_reg    ; * 4
    lsl lcd_data_reg    ; * 8 (índice * 8 para o offset na CGRAM)
    ori lcd_data_reg, LCD_SET_CGRAM_ADDR ; Adiciona o comando base para CGRAM (0x40)

    rcall lcd_send_command ; Envia o comando para definir o endereço de escrita na CGRAM

    ldi counter_reg, 8    ; Loop 8 vezes (8 bytes por caractere)
    load_char_loop:
        lpm r22, Z+      ; Carrega 1 byte do padrão de Flash para r22, incrementa Z
        mov lcd_data_reg, r22 ; Move o byte para o registrador de dados do LCD
        rcall lcd_send_data ; Envia o byte para a CGRAM
        dec counter_reg
        brne load_char_loop

    pop r23
    pop r22
    ret

; lcd_set_cursor: Move o cursor do LCD para uma posição específica
; Entrada: lcd_data_reg (endereço DDRAM, e.g., 0x00 para linha 0, coluna 0; 0x40 para linha 1, coluna 0)
lcd_set_cursor:
    ori lcd_data_reg, LCD_SET_DDRAM_ADDR ; Adiciona o comando base para DDRAM (0x80)
    rcall lcd_send_command
    ret

; --- Rotinas de Exibição das Carinhas (Chamadas pelas ISRs) ---
; Elas limpam o display e mostram a carinha correspondente na posição 0,0.

rotina_limpar_display_e_cursor:
    ; Limpa o display
    ldi lcd_data_reg, LCD_CLEAR_DISPLAY
    rcall lcd_send_command
    ; Vai para a posição inicial (0,0)
    ldi lcd_data_reg, 0x00 ; Endereço DDRAM para 0,0
    rcall lcd_set_cursor
    ret

; rotina_carinha_triste: rotina para mostrar o emoji triste
rotina_carinha_triste: ; Chamada pela INT0_ISR (PD2)
    push r20 ; Salva o registrador lcd_data_reg, pois será usado aqui
    rcall rotina_limpar_display_e_cursor
    ldi lcd_data_reg, 0x00 ; Índice da carinha triste na CGRAM (definimos como 0)
    rcall lcd_send_data
    pop r20 ; Restaura o registrador
    ret

; rotina_carinha_neutra: rotina para mostrar o emoji neutro
rotina_carinha_neutra: ; Chamada pela PCINT2_ISR (PD4)
    push r20
    rcall rotina_limpar_display_e_cursor
    ldi lcd_data_reg, 0x01 ; Índice da carinha neutra na CGRAM (definimos como 1)
    rcall lcd_send_data
    pop r20
    ret

; rotina_carinha_feliz: rotina para mostrar o emoji feliz
rotina_carinha_feliz: ; Chamada pela PCINT0_ISR (PB0)
    push r20
    rcall rotina_limpar_display_e_cursor
    ldi lcd_data_reg, 0x02 ; Índice da carinha feliz na CGRAM (definimos como 2)
    rcall lcd_send_data
    pop r20
    ret

; fim rian

.org 0x0000
    rjmp main_reset_vector  ; 0x0000: Reset vector (PC começa aqui na inicialização/reset)
    rjmp INT0_ISR           ; 0x0002: External Interrupt Request 0 (INT0 - pino PD2)
    rjmp unused_isr         ; 0x0004: External Interrupt Request 1 (INT1)
    rjmp PCINT0_ISR         ; 0x0006: Pin Change Interrupt Request 0 (PCINT0-7 - pino PB0)
    rjmp unused_isr         ; 0x0008: Pin Change Interrupt Request 1 (PCINT8-15)
    rjmp PCINT2_ISR         ; 0x000A: Pin Change Interrupt Request 2 (PCINT16-23 - pino PD4)
    rjmp unused_isr         ; 0x000C: Watchdog Time-out Interrupt
    rjmp unused_isr         ; 0x000E: Timer/Counter2 Compare Match A
    rjmp unused_isr         ; 0x0010: Timer/Counter2 Compare Match B
    rjmp unused_isr         ; 0x0012: Timer/Counter2 Overflow
    rjmp unused_isr         ; 0x0014: Timer/Counter1 Capture Event
    rjmp unused_isr         ; 0x0016: Timer/Counter1 Compare Match A
    rjmp unused_isr         ; 0x0018: Timer/Counter1 Compare Match B
    rjmp unused_isr         ; 0x001A: Timer/Counter1 Overflow
    rjmp unused_isr         ; 0x001C: Timer/Counter0 Compare Match A
    rjmp unused_isr         ; 0x001E: Timer/Counter0 Compare Match B
    rjmp unused_isr         ; 0x0020: Timer/Counter0 Overflow
    rjmp unused_isr         ; 0x0022: SPI Serial Transfer Complete
    rjmp unused_isr         ; 0x0024: USART Rx Complete
    rjmp unused_isr         ; 0x0026: USART Data Register Empty
    rjmp unused_isr         ; 0x0028: USART Tx Complete
    rjmp unused_isr         ; 0x002A: ADC Conversion Complete
    rjmp unused_isr         ; 0x002C: EEPROM Ready
    rjmp unused_isr         ; 0x002E: Analog Comparator
    rjmp unused_isr         ; 0x0030: 2-wire Serial Interface (TWI)
    rjmp unused_isr         ; 0x0032: Store Program Memory Read
    rjmp unused_isr         ; 0x0034: Unused (BOOTLOADER_READY)


main_reset_vector: 
    rjmp main 

unused_isr:
    reti

INT0_ISR:
    rcall rotina_carinha_triste
    reti

PCINT0_ISR:
    rcall rotina_carinha_feliz
    reti

PCINT2_ISR:
    rcall rotina_carinha_neutra
    reti

main:
    ;configurar a stack
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16
    
    sbi DDRD, PD2
    sbi DDRD, PD4
    sbi DDRB, PB0

    cbi DDRD, PD2       ; INT0
    sbi PORTD, PD2      ; Pull-up

    cbi DDRD, PD4       ; PCINT20
    sbi PORTD, PD4      ; Pull-up

    cbi DDRB, PB0       ; PCINT0
    sbi PORTB, PB0      ; Pull-up

    ; configura o ADC
    ldi temp_low, (1<<REFS0)  ; usa o Vcc do Arduino como referência de voltagem
    sts ADMUX, temp_low       ; e seleciona o canal 0 como padrao
    ldi temp_low, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0) ; Liga o ADC (ADEN) e
    ; define o prescaler para 128
    sts ADCSRA, temp_low
    ;isso aqui eu tbm n sei muito bem como funciona nao mas básicamente ele seleciona 5v como 
    ;o máximo que vai vir no adc e define algo de velocidade
    ;ele configura o adc pra ler o pino PC0 que é o pino analógico 0 do Arduino

    
    ;isso aqui configura a interrupção INT0 para ser acionada por uma borda de subida
    ;ou seja, quando o pino PD2 for ligado, a interrupção vai ser acionada
    ldi r16, (1<<ISC01) | (1<<ISC00)
    sts EICRA, r16
    ldi r16, (1<<INT0)
    sts EIMSK, r16

    ; faz o mesmo pra PD4 
    ldi r16, (1<<PCIE2)
    sts PCICR, r16
    ldi r16, (1<<PCINT20)
    sts PCMSK2, r16

    ;    Configuração da PCINT para o PB0
    ldi r16, (1<<PCIE0)
    out PCICR, r16  ; usar 'out' aqui ou somar os valores e usar 'sts' uma vez só
    ldi r16, (1<<PCINT0)
    sts PCMSK0, r16

    ;ligar a chave geral das interrupções
    sei

main_loop:
    rcall ler_valor_adc

    ;compara com 341
    ldi temp_low, low(341)  ; carrega a parte baixa de 341
    ldi temp_high, high(341) ; carrega a parte alta de 341
    cp adc_low, temp_low      ; compara os bytes baixos
    cpc adc_high, temp_high   ; compara os bytes altos com carry
    brlo set_pins_for_low  

; compara com 682 e pula se for menor
    ldi temp_low, low(682)
    ldi temp_high, high(682)
    cp adc_low, temp_low
    cpc adc_high, temp_high
    brlo set_pins_for_medium  ; se for menor que 682 pula pra rotina de 'neutro'
set_pins_for_high:;liga o feliz e desliga os outros
    sbi PORTB, PB0
    cbi PORTD, PD2
    cbi PORTD, PD4 
    rjmp main_loop

set_pins_for_low:;liga o triste e desliga os outros
    sbi PORTD, PD2
    cbi PORTB, PB0
    cbi PORTD, PD4 
    rjmp main_loop

set_pins_for_medium:;liga o neutro e desliga os outros
    sbi PORTD, PD4 
    cbi PORTD, PD2 
    cbi PORTB, PB0
    rjmp main_loop

ler_valor_adc:; rotina para ler o valor do ADC

    sbi ADCSRA, ADSC;faz com que o ADC comece a conversão
    ;liga o bit adsc do ADCSRA, que inicia a conversão

    loop_espera_adc:;loop pra que a conversao dê tempo de ser feita
    sbic ADCSRA, ADSC
    rjmp loop_espera_adc

    lds adc_low, ADCL;lê a parte menos significativa do resultado do ADC
    lds adc_high, ADCH ;lê a parte mais significativa
    
    ret 