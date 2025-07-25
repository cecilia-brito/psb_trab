# Projeto: Monitor de Umidade com LCD e Buzzer - ATmega328P

## Visão Geral

Este projeto implementa um sistema de monitoramento de umidade do solo usando um sensor analógico, um display LCD 16x2 e um buzzer, tudo controlado por um microcontrolador ATmega328P (presente na placa Arduino Uno-98). O objetivo é alertar o usuário quando o solo estiver seco através de mensagens no display e sinais sonoros. O usuário pode alternar entre três modos de funcionamento, controlando a periodicidade do alerta sonoro.

## Componentes Utilizados

- **Microcontrolador**: ATmega328P (Arduino Uno-98)
- **Sensor de umidade**: LM393 (saída analógica)
- **Display LCD 16x2**: operando em modo 4 bits
- **Buzzer**: ativo
- **Botão**: conectado ao pino PD2 (INT0)
- **Software de simulação**: [SimulIDE](https://www.simulide.com/)
- **Montador**: [AVRA](https://github.com/Ro5bert/avra)
- **Arquivo de simulação**: `.sim1` com circuito montado no SimulIDE (presente no repositório)

## Funcionalidades

- **Leitura analógica de umidade**: o sensor LM393 fornece uma tensão proporcional ao nível de umidade do solo. O conversor ADC do ATmega328P interpreta este valor para determinar a condição do solo.
- **Classificação de umidade**: baseado no valor lido, o solo é classificado como "Molhado", "Úmido" ou "Seco".
- **Exibição no LCD**: mensagens correspondentes são exibidas no display LCD 16x2, com o texto "Está Molhado!", "Está Úmido!" ou "Está Seco!".
- **Controle de modos de alerta**: através de um botão, o usuário alterna entre três modos de funcionamento que definem a frequência com que o buzzer é acionado.
- **Alerta sonoro com buzzer**: quando o solo está seco, o buzzer é ativado com base no modo de operação atual.
- **Display do modo atual**: o número do modo atual (1, 2 ou 3) é mostrado na segunda linha do LCD.

## Modos de Operação

| Modo | Comportamento do Buzzer                      |
|------|----------------------------------------------|
| 1    | Toca sempre que o solo estiver seco          |
| 2    | Toca apenas após um tempo mínimo de secura   |
| 3    | Toca apenas após cinco minutos de secura     |

## Funcionamento do Código

O código foi escrito inteiramente em Assembly e segue uma estrutura baseada em inicializações, laço principal e interrupções.

### Inicialização

- **Pinos**: configura as direções dos registradores para entrada e saída de dados (sensor, LCD, buzzer, botão)
- **Stack Pointer**: inicializado para o topo da RAM
- **ADC**: ativado e configurado para leitura no canal PC0 (ADC0)
- **LCD**: inicializado em modo 4 bits com comandos sequenciais para preparação do display
- **Interrupções**:
  - **INT0** habilitada para detecção de borda de descida (botão no PD2)
  - **TIMER1** configurado com prescaler para gerar overflow em intervalos regulares

### Loop Principal

1. **Leitura do ADC**:
   - Inicia a conversão
   - Espera o fim da conversão
   - Lê os valores de ADCL e ADCH
2. **Classificação**:
   - Se o valor ADC >= 900: solo seco
   - Se 400 <= valor ADC < 900: solo úmido
   - Se valor ADC < 400: solo molhado
3. **Mensagem**:
   - Exibe a mensagem correspondente no LCD, caractere por caractere
   - Atualiza a linha de modo no display (com o número do modo atual)
4. **Retorna ao passo 1** (laço infinito)

### Interrupção INT0

- Alteração do modo de operação (1 → 2 → 3 → 1)
- Cicla entre os modos de buzzer ao pressionar o botão

### Interrupção TIMER1_OVF

- Executada periodicamente (dependendo da configuração do timer)
- Se o solo estiver seco:
  - Modo 1: buzzer toca sempre
  - Modo 2: buzzer toca apenas se `counter_time >= min`
  - Modo 3: buzzer toca apenas se `counter_time >= cinco_min`
- Caso contrário, zera o contador de tempo seco

### Sub-rotinas

- `tocar_buzzer`: liga o buzzer por um tempo breve
- `enviar_comando_lcd`: envia comandos para o display LCD (como limpar, mudar cursor)
- `enviar_dado_lcd`: envia caracteres individuais para o display
- Delays para sincronizar a escrita e leitura

## Como Compilar

Utilize o AVRA para montar o código:

```bash
avra -fI codigo.asm
```

Isso gerará o arquivo `codigo.hex` que pode ser utilizado tanto em simuladores quanto em programadores físicos.

## Como Simular

1. Abra o SimulIDE
2. Carregue o arquivo `projeto.sim1` que já contém a montagem do circuito completo
3. Carregue o arquivo `codigo.hex` no microcontrolador ATmega328P
4. Acione o botão para alternar os modos
5. Acompanhe as mensagens no LCD e a ativação do buzzer

## Pinos Utilizados

| Pino | Função                   |
|------|--------------------------|
| PC0  | Entrada analógica (sensor) |
| PD2  | Entrada INT0 (botão)     |
| PB0  | EN do LCD                |
| PB1  | RS do LCD                |
| PD4  | D4 do LCD                |
| PD5  | D5 do LCD                |
| PD6  | D6 do LCD                |
| PD7  | D7 do LCD                |
| PB5  | Saída para o buzzer      |

## Equipe

- Allan Barros Cruz  
- Caio Sereno  
- Cecília Brito  
- Magno Macedo  
- Rian Victor Ribeiro  

## Licença

Este projeto foi desenvolvido com fins educacionais e pode ser livremente utilizado para estudo e aprendizado.
