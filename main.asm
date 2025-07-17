.nolist
.include "m328def.inc"
.list

; ==============================================================================
; Projeto:        Display de Emojis com ADC e Interrupções Internas
; Microcontrolador: ATmega328P
; Clock:          16 MHz
; ==============================================================================

; --- Registradores ---
.def temp_low       = r18
.def temp_high      = r19
.def lcd_data_reg   = r20
.def counter_reg    = r21
.def pin_state      = r22
.def general_temp   = r23
.def delay_low      = r24
.def delay_high     = r25
.def adc_low        = r16
.def adc_high       = r17

; --- Pinos de Sinalização ---
.equ TRIGGER_TRISTE_PIN = PB3
.equ TRIGGER_NEUTRA_PIN = PB4
.equ TRIGGER_FELIZ_PIN  = PB5

; --- Pinos do LCD ---
.equ LCD_RS_PIN = PD0
.equ LCD_EN_PIN = PD1
.equ LCD_D4_PIN = PD4
.equ LCD_D5_PIN = PD5
.equ LCD_D6_PIN = PD6
.equ LCD_D7_PIN = PD7

; --- Comandos do LCD ---
.equ LCD_CLEAR_DISPLAY  = 0b00000001
.equ LCD_FUNCTION_SET   = 0b00101000
.equ LCD_DISPLAY_ON_OFF = 0b00001100
.equ LCD_ENTRY_MODE_SET = 0b00000110
.equ LCD_SET_CGRAM_ADDR = 0b01000000
.equ LCD_SET_DDRAM_ADDR = 0b10000000

.cseg
;-------------------------------------------------------------------------------
; VETORES DE INTERRUPÇÃO
;-------------------------------------------------------------------------------
.org 0x0000
    rjmp    main_entry

.org PCI0addr ; o erro pode ser causado por esse endereço incorreto (tem que ver se ele é da porta B mesmo)
    rjmp    PCI_ISR

;-------------------------------------------------------------------------------
; ROTINA DE SERVIÇO DE INTERRUPÇÃO (ISR) - PCI (PORTB)
;-------------------------------------------------------------------------------
PCI_ISR:
    push    temp_low
    in      temp_low, SREG
    push    temp_low
    push    pin_state
    push    lcd_data_reg
    push    general_temp
    push    delay_low
    push    delay_high

    ; Pequeno delay para estabilização (debounce de software), pode não ser necessário
    ldi     general_temp, 5
    rcall   delay_ms

    in      pin_state, PINB
    ; Lógica corrigida para executar a rotina quando o pino está ALTO
    sbrc    pin_state, TRIGGER_TRISTE_PIN  
    rcall   rotina_carinha_triste
    sbrc    pin_state, TRIGGER_NEUTRA_PIN  
    rcall   rotina_carinha_neutra
    sbrc    pin_state, TRIGGER_FELIZ_PIN 
    rcall   rotina_carinha_feliz

isr_exit:
    pop     delay_high
    pop     delay_low
    pop     general_temp
    pop     lcd_data_reg
    pop     pin_state
    pop     temp_low
    out     SREG, temp_low
    pop     temp_low
    reti

;-------------------------------------------------------------------------------
; PROGRAMA PRINCIPAL
;-------------------------------------------------------------------------------
main_entry:
    ; Configura a Pilha
    ldi     temp_low, high(RAMEND)
    out     SPH, temp_low
    ldi     temp_low, low(RAMEND)
    out     SPL, temp_low

    ; Inicializa o LCD e Caracteres
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

    ; Configura Pinos de Sinalização como SAÍDA
    sbi     DDRB, TRIGGER_TRISTE_PIN
    sbi     DDRB, TRIGGER_NEUTRA_PIN
    sbi     DDRB, TRIGGER_FELIZ_PIN

    ; Configura o ADC
    cbi     DDRC, PC0
    ldi     temp_low, (1<<REFS0)
    sts     ADMUX, temp_low
    ldi     temp_low, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
    sts     ADCSRA, temp_low

    ; Configura Interrupções de Mudança de Pino para PORTB
    ldi     temp_low, (1<<PCIE0)
    sts     PCICR, temp_low
    ldi     temp_low, (1<<PCINT3)|(1<<PCINT4)|(1<<PCINT5) 
    sts     PCMSK0, temp_low

    ; Habilita Interrupções Globais
    sei

    rcall   rotina_carinha_neutra

;-------------------------------------------------------------------------------
; LOOP PRINCIPAL
;-------------------------------------------------------------------------------
main_loop:
    rcall   ler_valor_adc

    ; Compara o valor do ADC e altera o estado dos pinos de sinalização.
    ldi     temp_low, low(341)
    ldi     temp_high, high(341)
    cp      adc_low, temp_low
    cpc     adc_high, temp_high
    brlo    set_state_triste

    ldi     temp_low, low(682)
    ldi     temp_high, high(682)
    cp      adc_low, temp_low
    cpc     adc_high, temp_high
    brlo    set_state_neutro

set_state_feliz:
    sbi     PORTB, TRIGGER_FELIZ_PIN
    cbi     PORTB, TRIGGER_TRISTE_PIN
    cbi     PORTB, TRIGGER_NEUTRA_PIN
    rjmp    main_loop

set_state_neutro:
    sbi     PORTB, TRIGGER_NEUTRA_PIN
    cbi     PORTB, TRIGGER_TRISTE_PIN
    cbi     PORTB, TRIGGER_FELIZ_PIN
    rjmp    main_loop

set_state_triste:
    sbi     PORTB, TRIGGER_TRISTE_PIN
    cbi     PORTB, TRIGGER_NEUTRA_PIN
    cbi     PORTB, TRIGGER_FELIZ_PIN
    rjmp    main_loop

;-------------------------------------------------------------------------------
; ROTINAS DE EXIBIÇÃO E OUTRAS
;-------------------------------------------------------------------------------
lcd_posiciona_cursor_inicio:
    ldi     lcd_data_reg, LCD_SET_DDRAM_ADDR | 0x00
    rcall   lcd_send_command
    ret

rotina_carinha_triste:
    rcall   lcd_posiciona_cursor_inicio
    ldi     lcd_data_reg, 0
    rcall   lcd_send_data
    ret

rotina_carinha_neutra:
    rcall   lcd_posiciona_cursor_inicio
    ldi     lcd_data_reg, 1
    rcall   lcd_send_data
    ret

rotina_carinha_feliz:
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
    sbrc    temp_low, ADSC
    rjmp    loop_espera_adc
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

; Delay de ~100us para clock de 16MHz
delay_100us:
    ldi     general_temp, 228 
delay_100us_loop:
    nop                 ; 1 ciclo
    nop                 ; 1 ciclo
    nop                 ; 1 ciclo
    nop                 ; 1 ciclo
    dec     general_temp    ; 1 ciclo
    brne    delay_100us_loop ; 2 ciclos (Total: 7 ciclos * 228 = 1596 ciclos ~= 100us)
    ret

lcd_toggle_enable:
    sbi     PORTD, LCD_EN_PIN
    rcall   delay_100us
    cbi     PORTD, LCD_EN_PIN
    rcall   delay_100us
    ret

lcd_write_nibble:
    mov     general_temp, lcd_data_reg
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
    cbi     PORTD, LCD_RS_PIN
    rcall   lcd_send_byte
    rcall   delay_2ms
    ret

lcd_send_data:
    sbi     PORTD, LCD_RS_PIN
    rcall   lcd_send_byte
    ret

lcd_init:
    sbi     DDRD, LCD_RS_PIN
    sbi     DDRD, LCD_EN_PIN
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