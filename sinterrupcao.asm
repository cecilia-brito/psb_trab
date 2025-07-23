.nolist 
.include "m328Pdef.inc"
.list

; ==============================================================================
; Projeto:        Display de Emojis com ADC (Pinagem Modificada)
; Microcontrolador: ATmega328P
; Clock:          16 MHz
; Descrição:      Versão sem interrupções, usando RS=PB1, EN=PB0, D4-D7=PD4-PD7
; ==============================================================================

; --- Registradores ---
.def temp_low       = r18
.def temp_high      = r19
.def lcd_data_reg   = r20
.def counter_reg    = r21
.def last_state     = r22
.def general_temp   = r23
.def delay_low      = r24
.def delay_high     = r25
.def adc_low        = r16
.def adc_high       = r17

; --- Estados para os Emojis ---
.equ STATE_TRISTE = 0
.equ STATE_NEUTRO = 1
.equ STATE_FELIZ  = 2

; --- Pinos do LCD (modo de 4 bits) --- ;<-- MUDANÇA: Definições atualizadas
.equ LCD_RS_PIN = PB1 ; Pino Register Select: 0 para comando, 1 para dados (AGORA EM PORTB)
.equ LCD_EN_PIN = PB0 ; Pino Enable: um pulso neste pino trava os dados no LCD (AGORA EM PORTB)
.equ LCD_D4_PIN = PD4 ; Pino de dados 4 do LCD
.equ LCD_D5_PIN = PD5 ; Pino de dados 5 do LCD
.equ LCD_D6_PIN = PD6 ; Pino de dados 6 do LCD
.equ LCD_D7_PIN = PD7 ; Pino de dados 7 do LCD

; --- Comandos do LCD ---
.equ LCD_CLEAR_DISPLAY  = 0b00000001
.equ LCD_FUNCTION_SET   = 0b00101000
.equ LCD_DISPLAY_ON_OFF = 0b00001100
.equ LCD_ENTRY_MODE_SET = 0b00000110
.equ LCD_SET_CGRAM_ADDR = 0b01000000
.equ LCD_SET_DDRAM_ADDR = 0b10000000

.cseg
;-------------------------------------------------------------------------------
; VETOR DE RESET
;-------------------------------------------------------------------------------
.org 0x0000
    rjmp    main_entry

;-------------------------------------------------------------------------------
; PROGRAMA PRINCIPAL
;-------------------------------------------------------------------------------
main_entry:
    ; Configura a Pilha
    ldi     temp_low, high(RAMEND)
    out     SPH, temp_low
    ldi     temp_low, low(RAMEND)
    out     SPL, temp_low

    ; Inicializa o LCD e Caracteres Customizados
    rcall   lcd_init
    ldi     ZH, high(sad_face<<1)
    ldi     ZL, low(sad_face<<1)
    ldi     lcd_data_reg, 0
    rcall   lcd_create_char

    ldi     ZH, high(neutral_face<<1)
    ldi     ZL, low(neutral_face<<1)
    ldi     lcd_data_reg, 1
    rcall   lcd_create_char

    ldi     ZH, high(happy_face<<1)
    ldi     ZL, low(happy_face<<1)
    ldi     lcd_data_reg, 2
    rcall   lcd_create_char

    ; Configura o ADC
    cbi     DDRC, PC0
    ldi     temp_low, (1<<REFS0)
    sts     ADMUX, temp_low
    ldi     temp_low, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
    sts     ADCSRA, temp_low

    ; Inicializa o estado para forçar a primeira escrita no LCD
    ldi     last_state, 0xFF
    ;rjmp    main_loop

;-------------------------------------------------------------------------------
; LOOP PRINCIPAL
;-------------------------------------------------------------------------------
main_loop:
    rcall   ler_valor_adc

    ; Compara o valor do ADC e chama a rotina de exibição diretamente
    ldi     temp_low, low(341)
    ldi     temp_high, high(341)
    cp      adc_low, temp_low
    cpc     adc_high, temp_high
    brlo    display_triste

    ldi     temp_low, low(682)
    ldi     temp_high, high(682)
    cp      adc_low, temp_low
    cpc     adc_high, temp_high
    brlo    display_neutro

display_feliz:
    ldi     temp_low, STATE_FELIZ
    cpse    temp_low, last_state
    rcall   rotina_carinha_feliz
    rjmp    main_loop

display_neutro:
    ldi     temp_low, STATE_NEUTRO
    cpse    temp_low, last_state
    rcall   rotina_carinha_neutra
    rjmp    main_loop

display_triste:
    ldi     temp_low, STATE_TRISTE
    cpse    temp_low, last_state
    rcall   rotina_carinha_triste
    rjmp    main_loop


;-------------------------------------------------------------------------------
; ROTINAS DE EXIBIÇÃO E OUTRAS
;-------------------------------------------------------------------------------
lcd_posiciona_cursor_inicio:
    ldi     lcd_data_reg, LCD_SET_DDRAM_ADDR | 0x00
    rcall   lcd_send_command
    ret

rotina_carinha_triste:
    mov     last_state, temp_low
    rcall   lcd_posiciona_cursor_inicio
    ldi     lcd_data_reg, 0
    rcall   lcd_send_data
    ret

rotina_carinha_neutra:
    mov     last_state, temp_low
    rcall   lcd_posiciona_cursor_inicio
    ldi     lcd_data_reg, 1
    rcall   lcd_send_data
    ret

rotina_carinha_feliz:
    mov     last_state, temp_low
    rcall   lcd_posiciona_cursor_inicio
    ldi     lcd_data_reg, 2
    rcall   lcd_send_data
    ret

ler_valor_adc:
    lds     temp_low, ADCSRA
    ori     temp_low, (1<<ADSC)
    sts     ADCSRA, temp_low
loop_espera_adc:
    lds     temp_low, ADCSRA
    sbrs    temp_low, ADIF
    rjmp    loop_espera_adc
    lds     temp_low, ADCSRA
    ori     temp_low, (1<<ADIF)
    sts     ADCSRA, temp_low
    lds     adc_low, ADCL
    lds     adc_high, ADCH
    ret

;-------------------------------------------------------------------------------
; ROTINAS DE BAIXO NÍVEL
;-------------------------------------------------------------------------------
delay_ms:
    push    delay_low
    push    delay_high
    push    general_temp
delay_ms_outer_loop:
    ldi     delay_high, 5
    ldi     delay_low, 249
delay_ms_inner_loop:
    sbiw    delay_low, 1
    brne    delay_ms_inner_loop
    dec     general_temp
    brne    delay_ms_outer_loop
    pop     general_temp
    pop     delay_high
    pop     delay_low
    ret

delay_2ms:
    push    delay_low
    push    delay_high
    ldi     delay_high, high(8000)
    ldi     delay_low, low(8000)
delay_2ms_loop:
    sbiw    delay_low, 1
    brne    delay_2ms_loop
    pop     delay_high
    pop     delay_low
    ret

delay_100us:
    ldi     general_temp, 228
delay_100us_loop:
    nop
    nop
    nop
    nop
    dec     general_temp
    brne    delay_100us_loop
    ret

lcd_toggle_enable:
    sbi     PORTB, LCD_EN_PIN  ; <-- MUDANÇA: Agora opera na PORTB
    rcall   delay_100us
    cbi     PORTB, LCD_EN_PIN  ; <-- MUDANÇA: Agora opera na PORTB
    rcall   delay_100us
    ret

lcd_write_nibble:
    in      temp_low, PORTD
    andi    temp_low, 0x0F
    or      temp_low, general_temp
    out     PORTD, temp_low
    rcall   lcd_toggle_enable
    ret

lcd_send_byte:
    mov     general_temp, lcd_data_reg
    andi    general_temp, 0xF0
    rcall   lcd_write_nibble
    mov     general_temp, lcd_data_reg
    swap    general_temp
    andi    general_temp, 0xF0
    rcall   lcd_write_nibble
    ret

lcd_send_command:
    cbi     PORTB, LCD_RS_PIN  ; <-- MUDANÇA: Agora opera na PORTB
    rcall   lcd_send_byte
    rcall   delay_2ms
    ret

lcd_send_data:
    sbi     PORTB, LCD_RS_PIN  ; <-- MUDANÇA: Agora opera na PORTB
    rcall   lcd_send_byte
    ret

lcd_init:
    sbi     DDRB, LCD_RS_PIN   ; <-- MUDANÇA: Configura pino RS como saída na PORTB
    cbi     PORTB, LCD_RS_PIN   ; RS = 0 — garantido antes da inicialização
    sbi     DDRB, LCD_EN_PIN   ; <-- MUDANÇA: Configura pino EN como saída na PORTB
    sbi     DDRD, LCD_D4_PIN
    sbi     DDRD, LCD_D5_PIN
    sbi     DDRD, LCD_D6_PIN
    sbi     DDRD, LCD_D7_PIN

    ldi     general_temp, 50
    rcall   delay_ms

    ldi     lcd_data_reg, 0b00110000
    rcall   lcd_write_nibble
    ldi     general_temp, 5
    rcall   delay_ms

    rcall   lcd_write_nibble
    rcall   delay_100us
    rcall   lcd_write_nibble
    rcall   delay_100us

    ldi     lcd_data_reg, 0b00100000
    rcall   lcd_write_nibble
    rcall   delay_2ms

    ldi     lcd_data_reg, LCD_FUNCTION_SET
    rcall   lcd_send_command
    ldi     lcd_data_reg, LCD_DISPLAY_ON_OFF
    rcall   lcd_send_command
    ldi     lcd_data_reg, LCD_CLEAR_DISPLAY
    rcall   lcd_send_command
    ldi     lcd_data_reg, LCD_ENTRY_MODE_SET
    rcall   lcd_send_command
    ret

lcd_create_char:
    push    general_temp
    push    lcd_data_reg
    lsl     lcd_data_reg
    lsl     lcd_data_reg
    lsl     lcd_data_reg
    ori     lcd_data_reg, LCD_SET_CGRAM_ADDR
    rcall   lcd_send_command
    ldi     counter_reg, 8
load_char_loop:
    lpm     temp_low, Z+
    mov     lcd_data_reg, temp_low
    rcall   lcd_send_data
    dec     counter_reg
    brne    load_char_loop
    pop     lcd_data_reg
    pop     general_temp
    ret

;-------------------------------------------------------------------------------
; DADOS (CGRAM)
;-------------------------------------------------------------------------------
sad_face:
    .db 0b00000, 0b01010, 0b01010, 0b00000, 0b00000, 0b01110, 0b10001, 0b00000
neutral_face:
    .db 0b00000, 0b01010, 0b01010, 0b00000, 0b01110, 0b00000, 0b00000, 0b00000
happy_face:
    .db 0b00000, 0b01010, 0b01010, 0b00000, 0b00000, 0b10001, 0b01110, 0b00000