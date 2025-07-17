; ==============================================================================
;                                 INCLUSÕES E DEFINIÇÕES
; ==============================================================================
.nolist             ; Desativa a listagem do arquivo de inclusão no arquivo de saída
.include "m328Pdef.inc" ; Inclui o arquivo de definição padrão para o ATmega328P, que contém os nomes dos registradores e bits
.list               ; Reativa a listagem do código

; ==============================================================================
; Projeto:        Display de Emojis com ADC e Interrupções Internas
; Microcontrolador: ATmega328P
; Clock:          16 MHz
; Descrição:      Este programa lê um valor de um potenciômetro (ou outro sensor analógico)
;                 conectado ao pino ADC0. Com base no valor lido, ele exibe um emoji
;                 (triste, neutro ou feliz) em um display LCD 16x2.
;                 O loop principal lê o ADC e altera o estado de pinos de saída
;                 em PORTB. Uma interrupção de mudança de pino (Pin Change Interrupt)
;                 detecta essa alteração e chama a rotina para atualizar o display,
;                 desacoplando a leitura do sensor da escrita no LCD.
; ==============================================================================

; --- Definição de Nomes para Registradores (Aliases) ---
; Isso torna o código mais legível do que usar r16, r17, etc. diretamente.
.def temp_low       = r18 ; Registrador temporário de uso geral (parte baixa)
.def temp_high      = r19 ; Registrador temporário de uso geral (parte alta)
.def lcd_data_reg   = r20 ; Armazena o dado ou comando a ser enviado ao LCD
.def counter_reg    = r21 ; Usado como contador em loops
.def pin_state      = r22 ; Armazena o estado dos pinos de uma porta (ex: PINB)
.def general_temp   = r23 ; Registrador temporário de uso geral
.def delay_low      = r24 ; Usado em rotinas de delay (parte baixa de um contador de 16 bits)
.def delay_high     = r25 ; Usado em rotinas de delay (parte alta de um contador de 16 bits)
.def adc_low        = r16 ; Armazena a parte baixa do resultado do ADC (ADCL)
.def adc_high       = r17 ; Armazena a parte alta do resultado do ADC (ADCH)

; --- Constantes de Pinos de Sinalização Interna ---
; Estes pinos são configurados como SAÍDA. O programa principal os manipula
; para "sinalizar" um estado, e a ISR de interrupção reage à mudança de estado nestes pinos.
.equ TRIGGER_TRISTE_PIN = PB3 ; Pino que, ao ir para nível ALTO, sinaliza o estado "triste"
.equ TRIGGER_NEUTRA_PIN = PB4 ; Pino que, ao ir para nível ALTO, sinaliza o estado "neutro"
.equ TRIGGER_FELIZ_PIN  = PB5 ; Pino que, ao ir para nível ALTO, sinaliza o estado "feliz"

; --- Constantes de Pinos do LCD (modo de 4 bits) ---
.equ LCD_RS_PIN = PD0 ; Pino Register Select: 0 para comando, 1 para dados
.equ LCD_EN_PIN = PD1 ; Pino Enable: um pulso neste pino trava os dados no LCD
.equ LCD_D4_PIN = PD4 ; Pino de dados 4 do LCD
.equ LCD_D5_PIN = PD5 ; Pino de dados 5 do LCD
.equ LCD_D6_PIN = PD6 ; Pino de dados 6 do LCD
.equ LCD_D7_PIN = PD7 ; Pino de dados 7 do LCD

; --- Comandos Padrão do Display LCD (baseado no HD44780) ---
.equ LCD_CLEAR_DISPLAY  = 0b00000001 ; Limpa todo o display
.equ LCD_FUNCTION_SET   = 0b00101000 ; Modo 4 bits, 2 linhas, fonte 5x8
.equ LCD_DISPLAY_ON_OFF = 0b00001100 ; Display ligado, cursor desligado, sem piscar
.equ LCD_ENTRY_MODE_SET = 0b00000110 ; Incrementa o cursor para a direita, sem deslocar o display
.equ LCD_SET_CGRAM_ADDR = 0b01000000 ; Comando para definir o endereço da CGRAM (para criar caracteres customizados)
.equ LCD_SET_DDRAM_ADDR = 0b10000000 ; Comando para definir o endereço da DDRAM (para posicionar o cursor)

.cseg ; Inicia o segmento de código (memória de programa)
;-------------------------------------------------------------------------------
; VETORES DE INTERRUPÇÃO
;-------------------------------------------------------------------------------
.org 0x0000       ; Origem do vetor de reset do microcontrolador
    rjmp    main_entry ; Pula para o início do programa principal

.org PCI0addr      ; Origem do vetor de interrupção para PCINT7..0 (PORTB)
    rjmp    PCI_ISR    ; Pula para a Rotina de Serviço de Interrupção (ISR)

;-------------------------------------------------------------------------------
; ROTINA DE SERVIÇO DE INTERRUPÇÃO (ISR) - Pin Change Interrupt (PORTB)
;-------------------------------------------------------------------------------
PCI_ISR:
    ; --- Salva o Contexto ---
    ; É crucial salvar os registradores que serão usados na ISR para não corromper
    ; o estado do programa principal. O SREG também é salvo, pois as operações
    ; na ISR podem alterar os flags de estado (Z, C, N, etc.).
    push    temp_low       ; Salva r18 na pilha
    in      temp_low, SREG ; Copia o registrador de estado para temp_low
    push    temp_low       ; Salva o SREG na pilha
    push    pin_state      ; Salva r22 na pilha
    push    lcd_data_reg   ; Salva r20 na pilha
    push    general_temp   ; Salva r23 na pilha
    push    delay_low      ; Salva r24 na pilha
    push    delay_high     ; Salva r25 na pilha

    ; Pequeno delay para debounce. Como a mudança de pino é gerada pelo próprio software
    ; e não por um botão físico, este debounce pode não ser estritamente necessário.
    ldi     general_temp, 5
    rcall   delay_ms

    ; --- Lógica da ISR ---
    in      pin_state, PINB ; Lê o estado atual de todos os pinos de PORTB
    
    ; Verifica qual dos pinos de gatilho está em nível ALTO.
    ; A instrução 'sbrc' (Skip if Bit in Register is Clear) pula a próxima instrução
    ; se o bit especificado for 0 (nível BAIXO). Portanto, se o pino estiver em
    ; nível ALTO, a instrução 'rcall' será executada.
    sbrc    pin_state, TRIGGER_TRISTE_PIN  
    rcall   rotina_carinha_triste ; Se PB3 está ALTO, mostra a carinha triste

    sbrc    pin_state, TRIGGER_NEUTRA_PIN  
    rcall   rotina_carinha_neutra ; Se PB4 está ALTO, mostra a carinha neutra

    sbrc    pin_state, TRIGGER_FELIZ_PIN 
    rcall   rotina_carinha_feliz ; Se PB5 está ALTO, mostra a carinha feliz

isr_exit:
    ; --- Restaura o Contexto ---
    ; Os registradores são restaurados na ordem inversa em que foram salvos (LIFO - Last In, First Out).
    pop     delay_high     ; Restaura r25 da pilha
    pop     delay_low      ; Restaura r24 da pilha
    pop     general_temp   ; Restaura r23 da pilha
    pop     lcd_data_reg   ; Restaura r20 da pilha
    pop     pin_state      ; Restaura r22 da pilha
    pop     temp_low       ; Restaura o valor original do SREG para temp_low
    out     SREG, temp_low ; Escreve de volta para o registrador de estado
    pop     temp_low       ; Restaura r18 da pilha
    reti                   ; Retorna da interrupção e reabilita as interrupções globais

;-------------------------------------------------------------------------------
; PROGRAMA PRINCIPAL - INICIALIZAÇÃO
;-------------------------------------------------------------------------------
main_entry:
    ; --- Configura a Pilha (Stack Pointer) ---
    ; A pilha é usada para armazenar endereços de retorno (rcall) e para salvar
    ; registradores (push/pop). Ela cresce dos endereços mais altos para os mais baixos da RAM.
    ldi     temp_low, high(RAMEND) ; Carrega a parte alta do último endereço da RAM
    out     SPH, temp_low          ; Configura o Stack Pointer High
    ldi     temp_low, low(RAMEND)  ; Carrega a parte baixa do último endereço da RAM
    out     SPL, temp_low          ; Configura o Stack Pointer Low

    ; --- Inicializa o LCD e Caracteres Customizados ---
    rcall   lcd_init ; Chama a rotina de inicialização do LCD

    ; Carrega o endereço do padrão da carinha triste na memória de programa para os registradores Z (ZH:ZL)
    ldi     ZH, high(sad_face<<1)
    ldi     ZL, low(sad_face<<1)
    ldi     lcd_data_reg, 0         ; Define que este será o caractere customizado 0
    rcall   lcd_create_char         ; Chama a rotina para gravar o caractere na CGRAM do LCD

    ; Repete o processo para a carinha neutra (caractere 1)
    ldi     ZH, high(neutral_face<<1)
    ldi     ZL, low(neutral_face<<1)
    ldi     lcd_data_reg, 1
    rcall   lcd_create_char

    ; Repete o processo para a carinha feliz (caractere 2)
    ldi     ZH, high(happy_face<<1)
    ldi     ZL, low(happy_face<<1)
    ldi     lcd_data_reg, 2
    rcall   lcd_create_char

    ; --- Configura Pinos de Sinalização como SAÍDA ---
    ; O bit correspondente no registrador DDRB (Data Direction Register B) é setado para 1.
    sbi     DDRB, TRIGGER_TRISTE_PIN
    sbi     DDRB, TRIGGER_NEUTRA_PIN
    sbi     DDRB, TRIGGER_FELIZ_PIN

    ; --- Configura o ADC (Conversor Analógico-Digital) ---
    cbi     DDRC, PC0  ; Configura PC0 (pino do ADC) como ENTRADA (bit em DDRC = 0)
    ldi     temp_low, (1<<REFS0) ; Define a tensão de referência como AVCC (5V)
    sts     ADMUX, temp_low      ; Escreve a configuração no registrador ADMUX (ADC Multiplexer Selection)
    ; Habilita o ADC (ADEN) e define o prescaler para 128 (16MHz / 128 = 125KHz, dentro da faixa recomendada de 50-200KHz)
    ldi     temp_low, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
    sts     ADCSRA, temp_low     ; Escreve a configuração no registrador ADCSRA (ADC Control and Status Register A)

    ; --- Configura Interrupções de Mudança de Pino para PORTB ---
    ldi     temp_low, (1<<PCIE0) ; Habilita as interrupções de mudança de pino para o grupo 0 (PCINT7..0, que cobre PORTB)
    sts     PCICR, temp_low      ; Escreve no Pin Change Interrupt Control Register
    ldi     temp_low, (1<<PCINT3)|(1<<PCINT4)|(1<<PCINT5) ; Habilita as interrupções especificamente para os pinos PB3, PB4 e PB5
    sts     PCMSK0, temp_low     ; Escreve na máscara do grupo 0 (Pin Change Mask Register 0)

    ; --- Habilita Interrupções Globais ---
    sei ; Seta o bit 'I' no SREG, permitindo que as interrupções configuradas ocorram

    rcall   rotina_carinha_neutra ; Exibe a carinha neutra como estado inicial

;-------------------------------------------------------------------------------
; LOOP PRINCIPAL
;-------------------------------------------------------------------------------
main_loop:
    rcall   ler_valor_adc ; Chama a rotina para ler o valor do potenciômetro

    ; Compara o valor do ADC (adc_high:adc_low) com os limiares para decidir o estado.
    ; O valor do ADC vai de 0 a 1023. Os limiares são ~1/3 (341) e ~2/3 (682).
    
    ; Compara ADC com 341
    ldi     temp_low, low(341)   ; Carrega parte baixa do limiar
    ldi     temp_high, high(341) ; Carrega parte alta do limiar
    cp      adc_low, temp_low    ; Compara as partes baixas
    cpc     adc_high, temp_high  ; Compara as partes altas com carry da comparação anterior
    brlo    set_state_triste     ; Se ADC < 341, pula para a rotina do estado triste

    ; Compara ADC com 682
    ldi     temp_low, low(682)   ; Carrega parte baixa do limiar
    ldi     temp_high, high(682) ; Carrega parte alta do limiar
    cp      adc_low, temp_low
    cpc     adc_high, temp_high
    brlo    set_state_neutro     ; Se 341 <= ADC < 682, pula para a rotina do estado neutro

; Se ADC >= 682, executa o código a seguir (estado feliz)
set_state_feliz:
    sbi     PORTB, TRIGGER_FELIZ_PIN  ; Seta o pino de gatilho feliz (nível ALTO)
    cbi     PORTB, TRIGGER_TRISTE_PIN ; Limpa os outros pinos de gatilho (nível BAIXO)
    cbi     PORTB, TRIGGER_NEUTRA_PIN
    rjmp    main_loop                 ; Pula de volta para o início do loop principal

set_state_neutro:
    sbi     PORTB, TRIGGER_NEUTRA_PIN ; Seta o pino de gatilho neutro
    cbi     PORTB, TRIGGER_TRISTE_PIN ; Limpa os outros
    cbi     PORTB, TRIGGER_FELIZ_PIN
    rjmp    main_loop                 ; Pula de volta para o início do loop

set_state_triste:
    sbi     PORTB, TRIGGER_TRISTE_PIN ; Seta o pino de gatilho triste
    cbi     PORTB, TRIGGER_NEUTRA_PIN ; Limpa os outros
    cbi     PORTB, TRIGGER_FELIZ_PIN
    rjmp    main_loop                 ; Pula de volta para o início do loop

;-------------------------------------------------------------------------------
; ROTINAS DE EXIBIÇÃO E OUTRAS
;-------------------------------------------------------------------------------
lcd_posiciona_cursor_inicio:
    ; Posiciona o cursor na primeira posição da primeira linha (endereço 0x00)
    ldi     lcd_data_reg, LCD_SET_DDRAM_ADDR | 0x00
    rcall   lcd_send_command
    ret

rotina_carinha_triste:
    rcall   lcd_posiciona_cursor_inicio ; Move o cursor para o início
    ldi     lcd_data_reg, 0             ; Carrega o código do caractere customizado 'triste' (0)
    rcall   lcd_send_data               ; Envia o caractere para o LCD
    ret

rotina_carinha_neutra:
    rcall   lcd_posiciona_cursor_inicio ; Move o cursor para o início
    ldi     lcd_data_reg, 1             ; Carrega o código do caractere 'neutro' (1)
    rcall   lcd_send_data               ; Envia o caractere para o LCD
    ret

rotina_carinha_feliz:
    rcall   lcd_posiciona_cursor_inicio ; Move o cursor para o início
    ldi     lcd_data_reg, 2             ; Carrega o código do caractere 'feliz' (2)
    rcall   lcd_send_data               ; Envia o caractere para o LCD
    ret

ler_valor_adc:
    lds     temp_low, ADCSRA      ; Lê o registrador de controle do ADC
    ori     temp_low, (1<<ADSC)   ; Seta o bit ADSC (ADC Start Conversion) para iniciar uma nova conversão
    sts     ADCSRA, temp_low      ; Escreve de volta para iniciar
loop_espera_adc:
    lds     temp_low, ADCSRA      ; Lê o registrador de controle novamente
    sbrc    temp_low, ADSC        ; Pula a próxima instrução se o bit ADSC for 0 (conversão concluída)
    rjmp    loop_espera_adc       ; Se não terminou, continua no loop de espera
    lds     adc_low, ADCL         ; Lê o resultado baixo (8 bits) do ADC
    lds     adc_high, ADCH        ; Lê o resultado alto (2 bits) do ADC
    ret

;-------------------------------------------------------------------------------
; ROTINAS DE BAIXO NÍVEL (DELAYS E CONTROLE DO LCD)
;-------------------------------------------------------------------------------
delay_ms:
    ; Gera um delay de aproximadamente 'general_temp' milissegundos.
    push    delay_low
    push    delay_high
    push    general_temp
delay_ms_outer_loop:
    ldi     delay_high, 5  ; Valores calculados para gerar ~1ms de delay
    ldi     delay_low, 249 ; em um clock de 16MHz.
delay_ms_inner_loop:
    sbiw    delay_low, 1   ; Subtrai 1 do par de registradores de 16 bits (delay_high:delay_low)
    brne    delay_ms_inner_loop ; Loop interno
    dec     general_temp   ; Decrementa o contador de milissegundos
    brne    delay_ms_outer_loop ; Loop externo
    pop     general_temp
    pop     delay_high
    pop     delay_low
    ret

delay_2ms:
    ; Gera um delay de ~2ms, usado após comandos do LCD.
    push    delay_low
    push    delay_high
    ldi     delay_high, high(8000) ; Valor aproximado para 2ms a 16MHz
    ldi     delay_low, low(8000)
delay_2ms_loop:
    sbiw    delay_low, 1
    brne    delay_2ms_loop
    pop     delay_high
    pop     delay_low
    ret

delay_100us:
    ; Gera um delay de ~100us, usado para o pulso do pino 'Enable' do LCD.
    ldi     general_temp, 228 ; Valor calculado para 100us a 16MHz
delay_100us_loop:
    nop                 ; 1 ciclo
    nop                 ; 1 ciclo
    nop                 ; 1 ciclo
    nop                 ; 1 ciclo
    dec     general_temp    ; 1 ciclo
    brne    delay_100us_loop ; 2 ciclos (Total: 7 ciclos * 228 = 1596 ciclos ~= 100us)
    ret

lcd_toggle_enable:
    ; Gera o pulso no pino 'Enable' para que o LCD leia os dados nos pinos D4-D7.
    sbi     PORTD, LCD_EN_PIN ; Seta EN para nível ALTO
    rcall   delay_100us       ; Pequeno delay
    cbi     PORTD, LCD_EN_PIN ; Seta EN para nível BAIXO
    rcall   delay_100us       ; Pequeno delay
    ret

lcd_write_nibble:
    ; Envia 4 bits (um nibble) para os pinos D4-D7 do LCD.
    in      temp_low, PORTD         ; Lê o estado atual de PORTD para não alterar os pinos de controle (RS, EN)
    andi    temp_low, 0x0F          ; Limpa os 4 bits mais significativos (PD4-PD7), mantendo os 4 menos significativos (PD0-PD3)
    or      temp_low, general_temp  ; Combina (OU lógico) com o nibble de dados (que deve estar nos 4 bits mais significativos de general_temp)
    out     PORTD, temp_low         ; Envia o valor combinado para a Porta D
    rcall   lcd_toggle_enable       ; Pulsa o pino 'Enable' para travar os dados
    ret

lcd_send_byte:
    ; Envia um byte completo (8 bits) em duas etapas (modo de 4 bits).
    mov     general_temp, lcd_data_reg  ; Copia o byte a ser enviado para um registrador temporário
    andi    general_temp, 0xF0          ; Isola o nibble mais significativo (ex: 0b10101111 -> 0b10100000)
    rcall   lcd_write_nibble            ; Envia este nibble
    
    mov     general_temp, lcd_data_reg  ; Pega o byte original novamente
    swap    general_temp                ; Troca os nibbles (ex: 0b10101111 -> 0b11111010)
    andi    general_temp, 0xF0          ; Isola o novo nibble mais significativo (que era o nibble baixo original)
    rcall   lcd_write_nibble            ; Envia este segundo nibble
    ret

lcd_send_command:
    ; Envia um byte de comando para o LCD.
    cbi     PORTD, LCD_RS_PIN ; Coloca o pino RS em nível BAIXO para indicar que é um comando
    rcall   lcd_send_byte     ; Envia o byte
    rcall   delay_2ms         ; Espera um tempo para o LCD processar o comando
    ret

lcd_send_data:
    ; Envia um byte de dados (caractere) para o LCD.
    sbi     PORTD, LCD_RS_PIN ; Coloca o pino RS em nível ALTO para indicar que são dados
    rcall   lcd_send_byte     ; Envia o byte
    ret

lcd_init:
    ; Sequência de inicialização para o display LCD em modo de 4 bits.
    sbi     DDRD, LCD_RS_PIN ; Configura todos os pinos do LCD como SAÍDA
    sbi     DDRD, LCD_EN_PIN
    sbi     DDRD, LCD_D4_PIN
    sbi     DDRD, LCD_D5_PIN
    sbi     DDRD, LCD_D6_PIN
    sbi     DDRD, LCD_D7_PIN

    ldi     general_temp, 50 ; Espera >40ms após Vcc atingir 4.5V
    rcall   delay_ms

    ; A sequência de inicialização em 4 bits é um pouco complexa e exige
    ; o envio de comandos específicos para garantir a sincronização.
    ldi     lcd_data_reg, 0b00110000 ; Envia o comando 0x30 (em formato de nibble)
    rcall   lcd_write_nibble
    ldi     general_temp, 5         ; Espera >4.1ms
    rcall   delay_ms

    rcall   lcd_write_nibble        ; Envia 0x30 novamente
    rcall   delay_100us             ; Espera >100us

    rcall   lcd_write_nibble        ; Envia 0x30 uma terceira vez
    rcall   delay_100us

    ldi     lcd_data_reg, 0b00100000 ; Agora, define o modo de 4 bits
    rcall   lcd_write_nibble
    rcall   delay_2ms

    ; A partir daqui, o LCD está em modo de 4 bits e podemos enviar comandos completos.
    ldi     lcd_data_reg, LCD_FUNCTION_SET   ; Configura: 4 bits, 2 linhas, fonte 5x8
    rcall   lcd_send_command
    ldi     lcd_data_reg, LCD_DISPLAY_ON_OFF ; Liga o display, desliga o cursor
    rcall   lcd_send_command
    ldi     lcd_data_reg, LCD_CLEAR_DISPLAY  ; Limpa o display
    rcall   lcd_send_command
    ldi     lcd_data_reg, LCD_ENTRY_MODE_SET ; Define o modo de entrada (cursor move para a direita)
    rcall   lcd_send_command
    ret

lcd_create_char:
    ; Grava um padrão de 8 bytes (lido da memória de programa) na CGRAM do LCD.
    push    general_temp
    push    lcd_data_reg
    lsl     lcd_data_reg ; Multiplica o endereço do caractere (0, 1 ou 2) por 8
    lsl     lcd_data_reg ; para encontrar o endereço inicial na CGRAM (0, 8, 16, etc.)
    lsl     lcd_data_reg
    ori     lcd_data_reg, LCD_SET_CGRAM_ADDR ; Combina com o comando de escrita na CGRAM
    rcall   lcd_send_command                 ; Envia o comando de posicionamento na CGRAM
    ldi     counter_reg, 8                   ; Haverá 8 linhas (bytes) por caractere
load_char_loop:
    lpm     temp_low, Z+   ; Carrega um byte da memória de programa (apontada por Z) para temp_low e incrementa Z
    mov     lcd_data_reg, temp_low
    rcall   lcd_send_data  ; Envia o byte do padrão do caractere para o LCD
    dec     counter_reg    ; Decrementa o contador de linhas
    brne    load_char_loop ; Continua até que todas as 8 linhas sejam gravadas
    pop     lcd_data_reg
    pop     general_temp
    ret

;-------------------------------------------------------------------------------
; DADOS (ARMAZENADOS NA MEMÓRIA DE PROGRAMA - FLASH)
;-------------------------------------------------------------------------------
; Cada caractere é definido por 8 bytes. Cada byte representa uma linha de 5 pixels.
; Os 3 bits mais significativos de cada byte são ignorados pelo LCD.
sad_face:
    .db 0b00000, 0b01010, 0b01010, 0b00000, 0b00000, 0b01110, 0b10001, 0b00000
neutral_face:
    .db 0b00000, 0b01010, 0b01010, 0b00000, 0b01110, 0b00000, 0b00000, 0b00000
happy_face:
    .db 0b00000, 0b01010, 0b01010, 0b00000, 0b00000, 0b10001, 0b01110, 0b00000