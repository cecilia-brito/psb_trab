.nolist
.include "m328def.inc"

.def adc_low  = r15
.def adc_high = r17
.def temp_low = r18
.def temp_high = r19
.def counter4 = r23
.def modo_atual = r24
.def counter2 = r25
.def counter_time = r28
.def seco = r30

.equ min = 10
.equ cinco_min = 75

.org 0x0000
    rjmp main

.org 0x002
    jmp INT0_ISR

.org 0x001A
    jmp TIMER1_OVF_ISR

main:
    ldi r20, 0xFF
    out DDRD, r20
    out DDRB, r20
    cbi DDRD, 2
    sbi PORTD, 2 
    ldi counter2, 0
    ldi adc_high, 0
    ldi modo_atual, 1
    ldi counter_time, 0    ; <<< CORREÇÃO >>>
iniciar_adc:
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16
    cbi DDRC, 0
    ldi temp_low, (1<<REFS0)
    sts ADMUX, temp_low
    ldi temp_low, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)|(1<<ADSC)
    sts ADCSRA, temp_low
iniciar_lcd:
    rcall delay_ms_display_ligar
    ldi   R16, 0x33
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi   R16, 0x32
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi   R16, 0x28
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi   R16, 0x0C
    rcall enviar_comando_lcd
    ldi   R16, 0x01
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi   R16, 0x06
    rcall enviar_comando_lcd

inciar_int0:
    ldi r20, (1<<ISC01)
    sts EICRA, r20
    ldi r20, (1<<INT0)
    out EIMSK, r20
    sei

iniciar_timer:
    ldi temp_low, low(0x10000)
    sts TCNT1L, temp_low
    ldi temp_low, high(0x10000)
    sts TCNT1H, temp_low
    ldi temp_low, 0
    sts TCCR1A, temp_low
    ldi temp_low, (1<<CS12)|(1<<CS10)
    sts TCCR1B, temp_low
    ldi temp_low, (1<<TOIE1)
    sts TIMSK1, temp_low

escrever_lcd:
    rjmp ler_adc

; === Mensagens ===

mensagem_seco:
    ldi R16, 0x80
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi R16, 'E'  ; "Esta Seco!"
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
    ldi R16, 0xC0
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ret

mensagem_umido:
    ldi R16, 0x80
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi R16, 'E'  ; "Esta Umido!"
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
    ldi R16, 0xC0
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ret

mensagem_nseco:
    ldi   R16, 0x80         ;clear LCD
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar

    ldi R16, 'E'
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
    ;Segunda linha

    ldi R16, 0xC0        
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ret
; === Leitura ADC e Classificação ===

ler_adc:
    lds r20, ADCSRA
    ori r20, (1 << ADSC)
    sts ADCSRA, r20
esperar_adc:
    lds r21, ADCSRA
    sbrs r21, 4
    rjmp esperar_adc
    lds r21, ADCSRA
    ori r21, (1 << ADIF)
    sts ADCSRA, r21
    
    lds adc_low, ADCL
    lds adc_high, ADCH
    ldi seco, 0

    mov temp_low, adc_low
    mov temp_high, adc_high

    ldi counter2, low(900)
    ldi counter4, high(900)
    cp  temp_low, counter2
    cpc temp_high, counter4
    brsh show_seco

    ldi counter2, low(400)
    ldi counter4, high(400)
    cp  temp_low, counter2
    cpc temp_high, counter4
    brlo show_umido

show_nseco:
   rcall mensagem_nseco
   rjmp fim_adc
    
show_umido:
    rcall mensagem_umido
    rjmp fim_adc

show_seco:
    ldi seco, 1
    rcall mensagem_seco

 fim_adc:        
        ldi R16, 0xC0
        rcall enviar_comando_lcd
        rcall delay_ms_display_ligar
        
        ldi r16, 48
        add r16, modo_atual
        rcall enviar_dado_lcd
        rcall delay_ms_display_ligar

        rjmp ler_adc
; === LCD ===

enviar_comando_lcd:
    mov R27, R16
    andi R27, 0xF0
    in r20, PORTD
    andi r20, 0x0F
    or r27, r20
    out PORTD, R27
    cbi PORTB, 1
    sbi PORTB, 0
    rcall delay_short
    cbi PORTB, 0
    rcall delay_us
    mov R27, R16
    swap R27
    andi R27, 0xF0
    in r20, PORTD
    andi r20, 0x0F
    or r27, r20
    out PORTD, R27
    sbi PORTB, 0
    rcall delay_short
    cbi PORTB, 0
    rcall delay_us
    ret

enviar_dado_lcd:
    mov R27, R16
    andi R27, 0xF0
    in r20, PORTD
    andi r20, 0x0F
    or R27, r20
    out PORTD, R27
    sbi PORTB, 1
    sbi PORTB, 0
    rcall delay_short
    cbi PORTB, 0
    rcall delay_us
    mov R27, R16
    swap R27
    andi R27, 0xF0
    in r20, PORTD
    andi r20, 0x0F
    or R27, r20
    out PORTD, R27
    sbi PORTB, 0
    rcall delay_short
    cbi PORTB, 0
    rcall delay_us
    ret

; === Interrupções ===

INT0_ISR:
    push r16
    in r16, SREG
    push r16

    inc modo_atual
    cpi modo_atual, 4       ; compara com 4
    brne fim_int0           ; se não for 4, sai da interrupção
    ldi modo_atual, 1       ; se for 4, volta pra 1

fim_int0:
    pop r16
    out SREG, r16
    pop r16
    reti


TIMER1_OVF_ISR:
    push r16
    push r17
    in r16, SREG
    push r16
   
    cpi seco, 1
    brlo nao_seco
    inc counter_time

    cpi modo_atual, 1
    brne modo2
    rcall tocar_buzzer
    rjmp fim_isr

modo2:
    cpi modo_atual, 2
    brne modo3
    cpi counter_time, min
    brne fim_isr
    rcall tocar_buzzer
    rjmp fim_isr

modo3:
    cpi modo_atual, 3
    brne fim_isr
    cpi counter_time, cinco_min
    brne fim_isr
    rcall tocar_buzzer

nao_seco:
    push r20
    ldi r20, low(0x10000)
    sts TCNT1L, r20
    ldi r20, high(0x10000)
    sts TCNT1H, r20
    ldi counter_time, 0
    pop r20
fim_isr:
    
    pop r16
    out SREG, r16
    pop r17
    pop r16
    reti

tocar_buzzer:
    sbi PORTB, 5
    rcall delay_segundos_mensagem
    cbi PORTB, 5
    ret

; === Delays ===

delay_short:
    nop
    nop
    ret

delay_us:
    ldi R20, 90
loop1: rcall delay_short
    dec R20
    brne loop1
    ret

delay_ms_display_ligar:
    ldi R21, 40
loop2: rcall delay_us
    dec R21
    brne loop2
    ret

delay_segundos_mensagem:
    ldi R20, 255
loop3: ldi R21, 255
loop4: ldi R22, 20
loop5: dec R22
    brne loop5
    dec R21
    brne loop4
    dec R20
    brne loop3
    ret
