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
.include "../m328Pdef.inc"
.list
.def adc_low  = r16 ; guarda a parte menos significativa do resultado do ADC
.def adc_high = r17 ; guarda a parte mais significativa do resultado do ADC
.def temp_low = r18 ; temporário
.def temp_high= r19 ; temporário

.org 0x0000
    rjmp main

.org INT0_addr
    rjmp INT0_ISR ; pula para rotina de serviço da INT0

.org PCINT0_addr
    rjmp PCINT0_ISR; pula para a nossa rotina de serviço do Grupo 0

.org PCINT2_addr 
    rjmp PCINT2_ISR; pula para a nossa rotina de serviço do Grupo 2


INT0_ISR:
    rcall rotina_carinha_triste ; chama a sub-rotina que desenha o emoji
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
    ;isso aqui é básicamente configurar a pilha de execução, mas não sei explicar muito bem como funciona
    ;eu só copiei e colei mas o que importa é funcionar (:

    ;configurar os pinos de saída
    sbi DDRD, PD2
    sbi DDRD, PD4
    sbi DDRB, PB0


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

rotina_carinha_triste:; rotina para mostrar o emoji triste

    ret

rotina_carinha_neutra:; rotina para mostrar o emoji neutro
    ret

rotina_carinha_feliz:; rotina para mostrar o emoji feliz
    ret
