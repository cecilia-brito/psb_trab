.nolist
.include "m328def.inc"

.def adc_low  = r16 ; guarda a parte menos significativa do resultado do ADC
.def adc_high = r17 ; guarda a parte mais significativa do resultado do ADC e é o counter de centenas
.def temp_low = r18 ; temporário
.def temp_high = r19 ; temporário
.def counter4 = r23; milhar
.def counter2 = r25; dezena
.def seco = r30
.def modo_atual = r24
.def counter_time = r26
.equ min = 15
.equ cinco_min = 75
.org 0x0000
    rjmp main
.org 0x002
    jmp INT0_ISR
; .org 0x0008
;     jmp PCINT1_ISR
; .org 0x001A ;endereco vetor de interrupções timer1 por overflow(quando passa o valor de TCN1L/H)
;     jmp TIMER1_OVF_ISR
.org 0x0020
main:
    ldi r20, 0xFF
    out DDRD, r20; setando PORTA D para output
    out DDRB, r20; setando PORTA B para output/controle display
    cbi DDRD, 2
    sbi PORTD,2 
    ldi counter2, 0
    ldi adc_high, 0
    ldi modo_atual, 1
iniciar_adc:
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16
    cbi DDRC, 0; setando A0 para input
    ldi temp_low, (1<<REFS0)  ; usa o Vcc do Arduino como referência de voltagem
    sts ADMUX, temp_low       ; e seleciona o canal 0 como padrao
    ldi temp_low, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)| (1<<ADSC) ; Liga o ADC (ADEN) e
    ; define o prescaler para 128
    sts ADCSRA, temp_low
iniciar_lcd:
    rcall delay_ms_display_ligar
    ldi   R16, 0x33         ;init LCD for 4-bit data
    rcall enviar_comando_lcd       ;send to command register
    rcall delay_ms_display_ligar
    ldi   R16, 0x32         ;init LCD for 4-bit data
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi   R16, 0x28         ;LCD 2 lines, 5x7 matrix
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi   R16, 0x0C         ;disp ON, cursor OFF
    rcall enviar_comando_lcd
    ldi   R16, 0x01         ;clear LCD
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ldi   R16, 0x06         ;shift cursor right
    rcall enviar_comando_lcd
inciar_int0:
    ; ldi     temp_low, (1<<PCIE1)
    ; sts     PCICR, temp_low
    ; ldi     temp_low, (1<<PCINT8)
    ; sts     PCMSK1, temp_low
    ldi r20, (1<<ISC01)       ; interrupção na borda de descida
    sts EICRA, r20

    ldi r20, (1<<INT0)        ; habilita a interrupção INT0
    out EIMSK, r20
    sei
iniciar_timer:
    ldi temp_low, low(0x10000)
    sts TCNT1L, temp_low
    ldi temp_low,high(0x10000)
    sts TCNT1H, temp_low

    ldi temp_low, 0
    sts TCCR1A, temp_low

    ldi     temp_low, (1<<CS12)|(1<<CS10)
    sts     TCCR1B, temp_low

    ldi     temp_low, (1<<TOIE1)
    sts     TIMSK1, temp_low
escrever_lcd:
    rjmp ler_adc
mensagem_seco:
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

    ;Segunda linha

    ldi R16, 0xC0        
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ret
mensagem_umido:
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
    ;Segunda linha

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

    ldi R16, 'm'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    
    ldi R16, 'e'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 'i'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 'o'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, '!'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem
    ;Segunda linha

    ldi R16, 0xC0        
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar
    ret
ler_adc:
    lds r20, ADCSRA
    ori r20, (1 << ADSC)     
    sts ADCSRA, r20
esperar_adc:
    lds r21, ADCSRA
    sbrs r21, 4
    rjmp esperar_adc
    ;desligar adc
    lds   r21, ADCSRA
    ori r21, (1 << ADIF)
    sts  ADCSRA, R21

    lds adc_low, ADCL
    lds adc_high, ADCH
    ldi seco, 0
eadc:    
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
    show_umido:
       rcall mensagem_umido
       rjmp fim_adc
    show_seco:
        ldi seco, 1
        rcall mensagem_seco
        rjmp fim_adc 

    ;divisão utilizando divisões sucessivas por potências de 10 para contar cada digíto
    ; div_1000:;milhar
    ;     ldi r26, 232
    ;     ldi r27, 3
    ;     cpc temp_high, r27
    ;     cp temp_low, r26
    ;     brlo div_100
    ;     sbc temp_low, r26
    ;     sub temp_high, r27
    ;     inc counter4
    ;     rjmp div_1000

    ; div_100:;centena
    ;     ldi r26, 100
    ;     ldi r27, 0
    ;     cpc temp_high, r27
    ;     cp temp_low, r26
    ;     brlo div_10
    ;     sbc temp_low, r26
    ;     sub temp_high, r27
    ;     inc adc_high
    ;     rjmp div_100
    ; div_10:;dezena
    ;     ldi r26, 10
    ;     ldi r27, 0
    ;     cpc temp_high, r27
    ;     cp temp_low, r26
    ;     brlo show
    ;     sbc temp_low, r26
    ;     sub temp_high, r27
    ;     inc counter2
    ;     rjmp div_10
    ; show:
    fim_adc:
        ldi R16, 0xC0        
        rcall enviar_comando_lcd
        rcall delay_ms_display_ligar
        ldi temp_high, 48

        mov r16, modo_atual   ; milhar
        add r16, temp_high
        rcall enviar_dado_lcd
        rcall delay_ms_display_ligar

    ;     ldi r16, ' '   ; milhar
    ;     ; add r16, temp_high
    ;     rcall enviar_dado_lcd
    ;     rcall delay_ms_display_ligar
    ;     mov r16, counter4   ; milhar
    ;     add r16, temp_high
    ;     rcall enviar_dado_lcd
    ;     rcall delay_ms_display_ligar

    ;     mov r16, adc_high  ;centena
    ;     add r16, temp_high
    ;     rcall enviar_dado_lcd
    ;     rcall delay_ms_display_ligar

    ;     mov r16, counter2   ;dezena   
    ;     add r16, temp_high
    ;     rcall enviar_dado_lcd
    ;     rcall delay_ms_display_ligar

    ;     mov r16, temp_low   ; o que ficou em temp_low é a unidade  
    ;     add r16, temp_high
    ;     rcall enviar_dado_lcd
    ;     rcall delay_ms_display_ligar
    ;     ;;escrever na segunda linha na próxima leitura
       
        rjmp ler_adc

enviar_comando_lcd:
    mov   R27, R16
    andi  R27, 0xF0         ;mask low nibble & keep high nibble
    in r20, PORTD
    andi r20, 0x0F
    or r27, r20
    out   PORTD, R27        ;o/p high nibble to port D
    cbi   PORTB, 1          ;RS = 0 for command
    sbi   PORTB, 0          ;EN = 1
    rcall delay_short       ;widen EN pulse
    cbi   PORTB, 0          ;EN = 0 for H-to-L pulse
    rcall delay_us          ;delay in micro seconds
    ;----------------------------------------------------
    mov   R27, R16
    SWAP  R27               ;swap nibbles
    andi  R27, 0xF0         ;mask low nibble & keep high nibble
    in r20, PORTD
    andi r20, 0x0F
    or r27, r20
    out   PORTD, R27        ;o/p high nibble to port D
    sbi   PORTB, 0          ;EN = 1
    rcall delay_short       ;widen EN pulse
    cbi   PORTB, 0          ;EN = 0 for H-to-L pulse
    rcall delay_us          ;delay in micro seconds
    ret
enviar_dado_lcd:
    mov   R27, R16
    andi  R27, 0xF0         ;mask low nibble & keep high nibble
    in r20, PORTD
    andi r20, 0x0F
    or r27, r20
    out   PORTD, R27        ;o/p high nibble to port D
    sbi   PORTB, 1          ;RS = 1 for data
    sbi   PORTB, 0          ;EN = 1
    rcall delay_short       ;make wide EN pulse
    cbi   PORTB, 0          ;EN = 0 for H-to-L pulse
    rcall delay_us          ;delay in micro seconds
    ;----------------------------------------------------
    mov   R27, R16
    SWAP  R27               ;swap nibbles
    andi  R27, 0xF0         ;mask low nibble & keep high nibble
    in r20, PORTD
    andi r20, 0x0F
    or r27, r20
    out   PORTD, R27        ;o/p high nibble to port D
    sbi   PORTB, 0          ;EN = 1
    rcall delay_short       ;widen EN pulse
    cbi   PORTB, 0          ;EN = 0 for H-to-L pulse
    rcall delay_us          ;delay in micro seconds
    ret
; PCINT1_ISR:
;     push r16
;     in   r16, SREG
;     push r16
;     ; in r16,PORTD
;     ; ori r16, 0b00000010
;     ; out PORTD, r16
   
;     sbi PORTB, 4
;   rcall delay_ms_display_ligar
;     cbi PORTB, 4
;     ; cbi PORTB, 4
;     ; rcall delay_ms_display_ligar
;     fim_pcint:
;         pop r16
;         out SREG, r16
;         pop r16
;         reti
INT0_ISR:
    push r16
    in   r16, SREG
    push r16
   
    sbi PORTB, 4 ;teste led
   
    ; ldi r16, 4
    ; inc  modo_atual ; Incrementa o modo atual
    ; cpse modo_atual, r16
    ; ldi  modo_atual, 1 ; Reseta para o modo 1 se passar do modo 3
    pop r16
    out SREG, r16
    pop r16
    reti
TIMER1_OVF_ISR:
    push r16
    in   r16, SREG
    push r16

    cpi seco, 1
    brlo nao_seco; seco é 0, não toca o buzzer
    inc counter_time

    cpi modo_atual, 1 ; Verifica se o modo atual é 1
    brne compare_dois
    jmp tocar_buzzer
    

    compare_dois:
    cpi modo_atual, 2
    brne compare_tres
    cpi counter_time, min
    brne final
    jmp tocar_buzzer
    
    compare_tres:
    cpi modo_atual, 3
    brne final
    cpi counter_time, cinco_min
    brne final
    jmp tocar_buzzer

    tocar_buzzer:
    sbi PORTB, 5
    rcall delay_segundos_mensagem
    cbi PORTB, 5
    jmp final

    nao_seco:
    ldi counter2, low(0x10000)
    sts TCNT1L, counter2
    ldi counter4,high(0x10000)
    sts TCNT1H, counter4
    ldi counter_time, 0

    final:
    pop r16
    out SREG, r16
    pop r16
    ; ldi counter1, 0
    reti
delay_short:
    nop
    nop
    ret
delay_us:
    ldi   R20, 90
loop1: rcall delay_short
    dec   R20
    brne  loop1
    ret    
delay_ms_display_ligar:
    ldi   R21, 40
loop2: rcall delay_us
    DEC   R21
    BRNE  loop2
    ret
delay_segundos_mensagem:   
    ldi   R20, 255    ;outer loop counter 
loop3: ldi   R21, 255    ;mid loop counter
loop4: ldi   R22, 20     ;inner loop counter to give 0.25s delay
loop5: DEC   R22         ;decrement inner loop
    BRNE  loop5          ;loop if not zero
    DEC   R21         ;decrement mid loop
    BRNE  loop4          ;loop if not zero
    DEC   R20         ;decrement outer loop
    BRNE  loop3          ;loop if not zero
    ret 