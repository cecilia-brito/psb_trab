# Detector de Umidade de Solo

![Representação do Circuito no SimulIDE](/circuito.png "Representação do Circuito no SimulIDE")

## Funcionalidades
O nosso circuito é composto por um sensor lm393, um Arduino Uno-98, um display LCD 16x2 e um buzzer. Com o sensor inserido no solo e o programa em funcionamento, o display irá avisar quando o solo estiver abaixo ou acima dos parâmetros adequados de umidade. Além disso, o buzzer irá apitar por um período configurável para chamar a atenção do usuário caso o solo esteja seco. 

## Funcionamento do Código
O código, assim como requisitado pelas especificações do trabalho, foi escrito em Assembly compatível com o ATMega328P e inclui duas interrupções: uma de tempo e outra de Int0, ambas servindo para controlar as funcionalidades do buzzer. 

A interrupção de tempo faz com que o buzzer seja periodicamente acionado em casos de baixa umidade. Por outro lado, a interrupção de Int0 seleciona qual será a periodicidade que o buzzer será acionado. 

Além das configurações padrão (diretivas, definições, vetores de interrupção, pinos, etc), o código também é responsável por inicializar o conversor analógico-digital (ADC), o Display LCD e as interrupções. 

A lógica principal consiste de um loop infinito que inicia a conversão do ADC (esperando até que a leitura fique pronta) e de uma lógica de decisão que recebe os dados já convertidos para chamar as rotinas de secura e de umidade. É nessa etapa que as interrupções são executadas. 

Por fim, são chamadas as sub-rotinas de apoio para enviar os dados ao Display e realizar os atrasos, e o programa retorna ao loop principal. 

## Integrantes da Equipe
Allan Barros Cruz
Caio Sereno
Cecília Brito
Magno Macedo
Rian Victor Ribeiro
