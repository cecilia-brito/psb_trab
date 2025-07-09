.nolist
.include "m328def.inc"

.def adc_low  = r15 ; guarda a parte menos significativa do resultado do ADC
.def adc_high = r17 ; guarda a parte mais significativa do resultado do ADC
.def temp_low = r18 ; temporário
.def temp_high = r19 ; temporário
.def counter1 = r23; counter 1 display
.def counter = r25; counter2 display

.ORG 0X0000
   rjmp main
main:
    ldi r20, 0xFF
    out DDRD, r20; setando PORTA D para output
    out DDRB, r20; setando PORTA B para output/controle display
    cbi PORTB, 0;

iniciar_lcd:
      RCALL delay_ms_display_ligar
      LDI   R16, 0x33         ;init LCD for 4-bit data
      RCALL command_wrt       ;send to command register
      RCALL delay_ms
      LDI   R16, 0x32         ;init LCD for 4-bit data
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x28         ;LCD 2 lines, 5x7 matrix
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x0C         ;disp ON, cursor OFF
      RCALL command_wrt
      LDI   R16, 0x01         ;clear LCD
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x06         ;shift cursor right
      RCALL command_wrt
escrever_lcd:
    RCALL mensagem
iniciar_adc:
    sbi DDRC, 0; setando A0 para input
    ldi temp_low, (1<<REFS0)  ; usa o Vcc do Arduino como referência de voltagem
    sts ADMUX, temp_low    
    ldi temp_low, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0) ; Liga o ADC (ADEN) e
    ; define o prescaler para 128
    sts ADCSRA, temp_low;
ler_adc:
    ldi r20, 0b11000111
    sts ADCSRA, r20
esperar_adc:
    lds r21, ADCSRA
    sbrs r21, 4
    rjmp esperar_adc
    ldi temp_low, 0b11010111
    sts ADCSRA, temp_low
    lds adc_low, ADCL
    lds adc_high, ADCH
    rjmp ler_adc
enviar_comando_lcd:
     MOV   R27, R16
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      CBI   PORTB, 1          ;RS = 0 for command
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      ;----------------------------------------------------
      MOV   R27, R16
      SWAP  R27               ;swap nibbles
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      RET
enviar_dado_lcd:
    MOV   R27, R16
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 1          ;RS = 1 for data
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;make wide EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      ;----------------------------------------------------
      MOV   R27, R16
      SWAP  R27               ;swap nibbles
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      RET
mensagem:
delay_short:
      NOP
      NOP
      RET
delay_us:
      LDI   R20, 90
      RCALL delay_short
      DEC   R20
      BRNE  l3
      RET    
delay_ms_display_ligar:
    LDI   R21, 40
    RCALL delay_us
    DEC   R21
    BRNE  l4
    RET
