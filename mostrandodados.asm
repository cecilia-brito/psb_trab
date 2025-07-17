.nolist
.include "m328def.inc"

.def adc_low  = r16 ; guarda a parte menos significativa do resultado do ADC
.def adc_high = r17 ; guarda a parte mais significativa do resultado do ADC e é o counter de centenas
.def temp_low = r18 ; temporário
.def temp_high = r19 ; temporário
.def counter4 = r23; milhar
.def counter2 = r25; dezena
.def counter1 = r24; ascii

.ORG 0X0000
    ldi r20, 0xFF
    out DDRD, r20; setando PORTA D para output
    out DDRB, r20; setando PORTA B para output/controle display
    ; cbi PORTB, 0;
    ; ldi ascii, 48
    ldi counter1, 0
    ldi counter2, 0
    ldi adc_high, 0
    ; sbi PORTC, PC0; pull-down
    rjmp iniciar_adc
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
escrever_lcd:
    rcall mensagem
    rjmp ler_adc
mensagem:
    ;Mensagem
    ldi   R16, 0x01         ;clear LCD
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar

    ldi R16, 'A'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 'D'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 'C'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 'H'
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

    ldi R16, ' '
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 'A'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 'D'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 'C'
    rcall enviar_dado_lcd
    rcall delay_segundos_mensagem

    ldi R16, 'L'
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

    mov temp_low, adc_low
    mov temp_high, adc_high
    
    ldi counter4, 0
    ldi adc_high, 0   
    ldi counter2, 0   
    ldi counter1, 0        
; teste:
;     ldi counter1, 48

;     sbrc temp_high, 7
;     ldi r16, 1
;     sbrs temp_high, 7
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;     sbrc temp_high, 6
;     ldi r16, 1
;     sbrs temp_high, 6
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;     sbrc temp_high, 5
;     ldi r16, 1
;     sbrs temp_high, 5
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;      sbrc temp_high, 4
;     ldi r16, 1
;     sbrs temp_high, 4
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;     sbrc temp_high, 3
;     ldi r16, 1
;     sbrs temp_high, 3
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;     sbrc temp_high, 2
;     ldi r16, 1
;     sbrs temp_high, 2
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;     sbrc temp_high, 1
;     ldi r16, 1
;     sbrs temp_high, 1
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar

;     sbrc temp_high, 0
;     ldi r16, 1
;     sbrs temp_high, 0
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar

;     sbrc temp_low, 7
;     ldi r16, 1
;     sbrs temp_low, 7
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;     sbrc temp_low, 6
;     ldi r16, 1
;     sbrs temp_low, 6
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;     sbrc temp_low, 5
;     ldi r16, 1
;     sbrs temp_low, 5
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;      sbrc temp_low, 4
;     ldi r16, 1
;     sbrs temp_low, 4
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;     sbrc temp_low, 3
;     ldi r16, 1
;     sbrs temp_low, 3
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;     sbrc temp_low, 2
;     ldi r16, 1
;     sbrs temp_low, 2
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;     sbrc temp_low, 1
;     ldi r16, 1
;     sbrs temp_low, 1
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;     sbrc temp_low, 0
;     ldi r16, 1
;     sbrs temp_low, 0
;     ldi r16, 0
;     add r16, counter1
;     rcall enviar_dado_lcd
;     rcall delay_ms_display_ligar
;      ldi r16, 0xc0
;     rcall enviar_comando_lcd
;     rcall delay_segundos_mensagem
;     ldi counter1, 0     
;divisão utilizando divisões sucessivas por potências de 10 para contar cada digíto
div_1000:;milhar
    ldi r26, 232
    ldi r27, 3
    cpc temp_high, r27
    cp temp_low, r26
    brlo div_100
    sbc temp_low, r26
    sub temp_high, r27
    inc counter4
    rjmp div_1000

div_100:;centena
    ldi r26, 100
    ldi r27, 0
    cpc temp_high, r27
    cp temp_low, r26
    brlo div_10
    sbc temp_low, r26
    sub temp_high, r27
    inc adc_high
    rjmp div_100
div_10:;dezena
    ldi r26, 10
    ldi r27, 0
    cpc temp_high, r27
    cp temp_low, r26
    brlo show
    sbc temp_low, r26
    sub temp_high, r27
    inc counter2
    rjmp div_10
show:
    ldi temp_high, 48
    mov r16, counter4   ; milhar
    add r16, temp_high
    rcall enviar_dado_lcd
    rcall delay_ms_display_ligar

    mov r16, adc_high  ;centena
    add r16, temp_high
    rcall enviar_dado_lcd
    rcall delay_ms_display_ligar

    mov r16, counter2   ;dezena   
    add r16, temp_high
    rcall enviar_dado_lcd
    rcall delay_ms_display_ligar

    mov r16, temp_low   ; o que ficou em temp_low é a unidade  
    add r16, temp_high
    rcall enviar_dado_lcd
    rcall delay_ms_display_ligar
    ;;escrever na segunda linha na próxima leitura
    ldi R16, 0xC0        
    rcall enviar_comando_lcd
    rcall delay_ms_display_ligar

    ;;limpando os registradores para próxima leitura
    clr adc_high
    clr adc_low
    clr temp_high
    clr temp_low
    rjmp ler_adc
enviar_comando_lcd:
    mov   R27, R16
    andi  R27, 0xF0         ;mask low nibble & keep high nibble
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
    out   PORTD, R27        ;o/p high nibble to port D
    sbi   PORTB, 0          ;EN = 1
    rcall delay_short       ;widen EN pulse
    cbi   PORTB, 0          ;EN = 0 for H-to-L pulse
    rcall delay_us          ;delay in micro seconds
    ret
enviar_dado_lcd:
    mov   R27, R16
    andi  R27, 0xF0         ;mask low nibble & keep high nibble
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
    out   PORTD, R27        ;o/p high nibble to port D
    sbi   PORTB, 0          ;EN = 1
    rcall delay_short       ;widen EN pulse
    cbi   PORTB, 0          ;EN = 0 for H-to-L pulse
    rcall delay_us          ;delay in micro seconds
    ret
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