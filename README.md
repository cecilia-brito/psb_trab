# Detector de Umidade de Solo

![Representação do Circuito no SimulIDE](/circuito.png "Representação do Circuito no SimulIDE")

OBS: *no arquivo do simulador de circuito, o sensor foi substituído por um potenciômetro para que não seja necessário baixar nenhum addon para o SimulIDE. O funcionamento é o mesmo, alterando apenas a estética.*

# Projeto: Monitor de Umidade com LCD e Buzzer - ATmega328P

## Visao Geral

Este projeto implementa um sistema de monitoramento de umidade do solo usando um sensor analogico, um display LCD 16x2 e um buzzer, tudo controlado por um microcontrolador ATmega328P. O objetivo e alertar o usuario quando o solo estiver seco atraves de mensagens no display e sinais sonoros. O usuario pode alternar entre tres modos de funcionamento, controlando a periodicidade do alerta sonoro.

## Componentes Utilizados

- **Microcontrolador**: ATmega328P (Arduino Uno-98)
- **Sensor de umidade**: LM393 (saida analogica)
- **Display LCD 16x2**: operando em modo 4 bits
- **Buzzer**: ativo
- **Botao**: conectado ao pino PD2 (INT0)
- **Software de simulacao**: [SimulIDE](https://www.simulide.com/)
- **Montador**: [AVRA](https://github.com/Ro5bert/avra)
- **Arquivo de simulacao**: `.sim` com circuito montado no SimulIDE (presente no repositorio)

## Funcionalidades

- Leitura da umidade do solo via ADC
- Exibicao da mensagem no display:
  - "Esta Molhado!" (umidade alta)
  - "Esta Umido!" (umidade moderada)
  - "Esta Seco!" (umidade baixa)
- Buzzer apita para alertar solo seco, com 3 modos de operacao
- Mudanca de modo atraves do botao (PD2 / INT0)
- LCD tambem exibe o numero do modo atual

## Modos de Operacao

| Modo | Comportamento do Buzzer                      |
|------|----------------------------------------------|
| 1    | Toca sempre que o solo estiver seco          |
| 2    | Toca apenas apos um tempo minimo de secura   |
| 3    | Toca apenas apos cinco minutos de secura     |

## Funcionamento do Codigo

O codigo foi escrito inteiramente em Assembly e segue uma estrutura baseada em inicializacoes, laço principal e interrupcoes.

### Inicializacao

- **Pinos**: configura as direcoes dos registradores para entrada e saida de dados (sensor, LCD, buzzer, botao)
- **Stack Pointer**: inicializado para o topo da RAM
- **ADC**: ativado e configurado para leitura no canal PC0 (ADC0)
- **LCD**: inicializado em modo 4 bits com comandos sequenciais para preparacao do display
- **Interrupcoes**:
  - **INT0** habilitada para detecao de borda de descida (botao no PD2)
  - **TIMER1** configurado com prescaler para gerar overflow em intervalos regulares

### Loop Principal

1. **Leitura do ADC**:
   - Inicia a conversao
   - Espera o fim da conversao
   - Le os valores de ADCL e ADCH
2. **Classificacao**:
   - Se o valor ADC >= 900: solo seco
   - Se 400 <= valor ADC < 900: solo umido
   - Se valor ADC < 400: solo molhado
3. **Mensagem**:
   - Exibe a mensagem correspondente no LCD, caractere por caractere
   - Atualiza a linha de modo no display (com o numero do modo atual)
4. **Retorna ao passo 1** (laço infinito)

### Interrupcao INT0

- Alteracao do modo de operacao (1 → 2 → 3 → 1)
- Cicla entre os modos de buzzer ao pressionar o botao

### Interrupcao TIMER1_OVF

- Executada periodicamente (dependendo da configuracao do timer)
- Se o solo estiver seco:
  - Modo 1: buzzer toca sempre
  - Modo 2: buzzer toca apenas se `counter_time >= min`
  - Modo 3: buzzer toca apenas se `counter_time >= cinco_min`
- Caso contrario, zera o contador de tempo seco

### Sub-rotinas

- `tocar_buzzer`: liga o buzzer por um tempo breve
- `enviar_comando_lcd`: envia comandos para o display LCD (como limpar, mudar cursor)
- `enviar_dado_lcd`: envia caracteres individuais para o display
- Delays para sincronizar a escrita e leitura

## Como Compilar

Utilize o AVRA para montar o codigo:

```bash
avra codigo.asm
```

Isso gerara o arquivo `codigo.hex` que pode ser utilizado tanto em simuladores quanto em programadores fisicos.

OBS:*Lembre-se de sempre ter o arquivo m328def.inc na pasta*

## Como Simular

1. Abra o SimulIDE
2. Carregue o arquivo `projeto.sim` que ja contem a montagem do circuito completo
3. Carregue o arquivo `codigo.hex` no microcontrolador ATmega328P
4. Acione o botao para alternar os modos
5. Acompanhe as mensagens no LCD e a ativacao do buzzer

## Pinos Utilizados

| Pino | Funcao                   |
|------|--------------------------|
| PC0  | Entrada analogica (sensor) |
| PD2  | Entrada INT0 (botao)     |
| PB0  | EN do LCD                |
| PB1  | RS do LCD                |
| PD4  | D4 do LCD                |
| PD5  | D5 do LCD                |
| PD6  | D6 do LCD                |
| PD7  | D7 do LCD                |
| PB5  | Saida para o buzzer      |

## Equipe

- Allan Barros Cruz  
- Caio Sereno  
- Cecilia Brito  
- Magno Macedo Miranda
- Rian Victor Ribeiro  

## Licenca

Este projeto foi desenvolvido com fins educacionais e pode ser livremente utilizado para estudo e aprendizado.
