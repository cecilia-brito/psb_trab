.nolist
.include "m328Pdef.inc"
.list
.def adc_low  = r16 ; guarda a parte menos significativa do resultado do ADC
.def adc_high = r17 ; guarda a parte mais significativa do resultado do ADC
.def temp_low = r18 ; temporário
.def temp_high= r19 ; temporário
.def pin_state= r20 ; temporário para a ISR

.org 0x0000
    rjmp main

;agora as interrupções estão todas no grupo PCINT1
.org PCI1addr      ; Vetor para interrupções da Porta C (PCINT8-14)
    rjmp PCINT1_ISR  ; Pula para a nova ISR unificada


; Nova ISR que verifica qual pino da Porta C causou a interrupção
PCINT1_ISR:
    in pin_state, PINC       ; Lê o estado dos pinos da Porta C
    sbrc pin_state, PC1      ; Se o pino PC1 (triste) estiver alto, chama a rotina
    rcall rotina_carinha_triste
    sbrc pin_state, PC2      ; Se o pino PC2 (neutra) estiver alto, chama a rotina
    rcall rotina_carinha_neutra
    sbrc pin_state, PC3      ; Se o pino PC3 (feliz) estiver alto, chama a rotina
    rcall rotina_carinha_feliz
    reti

main:
    ;configurar a stack
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16
    ;isso aqui é básicamente configurar a pilha de execução, mas não sei explicar muito bem como funciona
    ;eu só copiei e colei mas o que importa é funcionar (:

    ;configurar os pinos de saída na Porta C ---
    sbi DDRC, PC1 ; Define PC1 (triste) como saída
    sbi DDRC, PC2 ; Define PC2 (neutra) como saída
    sbi DDRC, PC3 ; Define PC3 (feliz) como saída


    ; configura o ADC
    ldi temp_low, (1<<REFS0)  ; usa o Vcc do Arduino como referência de voltagem
    sts ADMUX, temp_low       ; e seleciona o canal 0 como padrao
    ldi temp_low, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0) ; Liga o ADC (ADEN) e
    ; define o prescaler para 128
    sts ADCSRA, temp_low
    ;isso aqui eu tbm n sei muito bem como funciona nao mas básicamente ele seleciona 5v como 
    ;o máximo que vai vir no adc e define algo de velocidade
    ;ele configura o adc pra ler o pino PC0 que é o pino analógico 0 do Arduino

    
    ; Habilita o grupo de interrupção para a Porta C (PCIE1)
    ldi r16, (1<<PCIE1)
    sts PCICR, r16
    ; Habilita a checagem nos pinos PC1, PC2 e PC3 dentro do grupo
    ldi r16, (1<<PCINT9)|(1<<PCINT10)|(1<<PCINT11) ;PCINT9=PC1, PCINT10=PC2, PCINT11=PC3
    sts PCMSK1, r16

    ;ligar a chave geral das interrupções
    sei

main_loop:
    rcall ler_valor_adc

    ;compara com 341
    ldi temp_low, low(341)  ; carrega a parte baixa de 341
    ldi temp_high, high(341) ; carrega a parte alta de 341
    cp adc_low, temp_low    ; compara os bytes baixos
    cpc adc_high, temp_high   ; compara os bytes altos com carry
    brlo set_pins_for_low  

    ; compara com 682 e pula se for menor
    ldi temp_low, low(682)
    ldi temp_high, high(682)
    cp adc_low, temp_low
    cpc adc_high, temp_high
    brlo set_pins_for_medium  ; se for menor que 682 pula pra rotina de 'neutro'
    
;Lógica de pinos agora usa a Porta C ---
set_pins_for_high:;liga o feliz e desliga os outros
    sbi PORTC, PC3  ; liga o feliz (era PORTB, PB0)
    cbi PORTC, PC1  ; desliga o triste (era PORTD, PD2)
    cbi PORTC, PC2  ; desliga o neutro (era PORTD, PD4)
    rjmp main_loop

set_pins_for_low:;liga o triste e desliga os outros
    sbi PORTC, PC1  ; liga o triste (era PORTD, PD2)
    cbi PORTC, PC3  ; desliga o feliz (era PORTB, PB0)
    cbi PORTC, PC2  ; desliga o neutro (era PORTD, PD4)
    rjmp main_loop

set_pins_for_medium:;liga o neutro e desliga os outros
    sbi PORTC, PC2  ; liga o neutro (era PORTD, PD4) 
    cbi PORTC, PC1  ; desliga o triste (era PORTD, PD2)
    cbi PORTC, PC3  ; desliga o feliz (era PORTB, PB0)
    rjmp main_loop

ler_valor_adc: ; rotina para ler o valor do ADC

    ; Inicia a conversão do ADC (substituindo 'sbi ADCSRA, ADSC')
    lds temp_low, ADCSRA      ;Lê o valor atual de ADCSRA para um registrador temporário
    ori temp_low, (1<<ADSC)   ;Liga o bit ADSC no registrador temporário
    sts ADCSRA, temp_low      ;Escreve o novo valor de volta em ADCSRA

loop_espera_adc: ; loop para que a conversao dê tempo de ser feita
    ; Espera a conversão terminar (substituindo 'sbic ADCSRA, ADSC')
    lds temp_low, ADCSRA      ;Lê ADCSRA para verificar o bit ADSC
    sbrc temp_low, ADSC       ;Testa o bit no registrador temporário. Pula se estiver '0' (conversão concluída)
    rjmp loop_espera_adc      ;Se o bit ainda for '1', continua no loop

    lds adc_low, ADCL ; lê a parte menos significativa do resultado do ADC
    lds adc_high, ADCH ; lê a parte mais significativa
    
    ret
    
rotina_carinha_triste:; rotina para mostrar o emoji triste
    sbi PORTD , PC1
    ret

rotina_carinha_neutra:; rotina para mostrar o emoji neutro
    sbi PORTD , PC2
    ret

rotina_carinha_feliz:; rotina para mostrar o emoji feliz
    sbi PORTD , PC3
    ret