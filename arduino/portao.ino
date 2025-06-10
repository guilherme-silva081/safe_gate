// bibliotecas do cod 
#include <Servo.h>          // Para controlar o servomotor
#include <SoftwareSerial.h> // Para comunicação serial com Bluetooth
//__________________________

// Configuração do módulo Bluetooth (RX no pino 10, TX no pino 11)
const int rxPin = 10;
const int txPin = 11;
SoftwareSerial bluetoothSerial(rxPin, txPin);
//__________________________

// Objeto e pinos para o servo e LEDs
Servo servo_9;                  // Objeto para controlar o servo
const int servoPin = 9;         // Pino do servo
const int ledVerdePin = 8;      // Pino do LED verde
const int ledVermelhoPin = 7;   // Pino do LED vermelho
//__________________________

// Constantes de tempo 
const int TEMPO_ABERTURA = 20;   // Tempo entre passos na abertura (ms)
const int TEMPO_FECHAMENTO = 20; // Tempo entre passos no fechamento (ms)
const int TEMPO_PISCADA = 200;   // Tempo das piscadas dos LEDs (ms)
//__________________________

// Variáveis globais
int servoPos = 0;               // Posição atual do servo (0-120 graus)
bool emMovimento = false;       // Flag para controlar se o servo está em movimento
//__________________________

void setup() {
  // Inicializa comunicação serial (USB) a 9600 bauds
  Serial.begin(9600);
  while (!Serial); // Espera a serial estar pronta
  
  // Inicializa comunicação Bluetooth a 9600 bauds
  bluetoothSerial.begin(9600);
  delay(1000); // Delay inicial para estabilizar o Bluetooth

  // Configuração dos pinos dos LEDs
  pinMode(ledVerdePin, OUTPUT);
  pinMode(ledVermelhoPin, OUTPUT);
  digitalWrite(ledVerdePin, LOW);   // LED verde inicialmente desligado
  digitalWrite(ledVermelhoPin, LOW); // LED vermelho inicialmente desligado

  // Configuração do servo motor
  servo_9.attach(servoPin, 500, 2500); // Anexa o servo com range de pulso 500-2500μs
  servo_9.write(servoPos);             // Posição inicial 0 graus
  
  // Mensagem inicial de sistema pronto
  bluetoothSerial.println("Sistema iniciado");
  Serial.println("Sistema iniciado e pronto para comandos");
}
//__________________________

void enviarConfirmacao(const String &mensagem) {
  bluetoothSerial.println(mensagem);
  bluetoothSerial.flush(); // Força envio imediato
  delay(20); // Pequeno delay para estabilidade
}
//__________________________

void abrir() {
  emMovimento = true;
  // Ativa LED verde e desliga vermelho
  digitalWrite(ledVerdePin, HIGH);
  digitalWrite(ledVermelhoPin, LOW);
  
  // Movimento de abertura gradual
  while (servoPos < 120 && emMovimento) {
    servo_9.write(servoPos);
    servoPos += 1;
    delay(TEMPO_ABERTURA);
    
    // Verificação de comando de parada durante movimento
    if (bluetoothSerial.available()) {
      char cmd = bluetoothSerial.read();
      if (cmd == 'p') {
        parar(); // Chama função de parada completa
        return;
      }
    }
  }
  
  // Finalização da abertura
  if (servoPos >= 120) {
    digitalWrite(ledVerdePin, LOW);
    enviarConfirmacao("Aberto");
    Serial.println("Abertura concluída");
  }
  emMovimento = false;
}
//__________________________

void fechar() {
  emMovimento = true;
  // Ativa LED vermelho e desliga verde
  digitalWrite(ledVermelhoPin, HIGH);
  digitalWrite(ledVerdePin, LOW);
  
  // Movimento de fechamento gradual
  while (servoPos > 0 && emMovimento) {
    servo_9.write(servoPos);
    servoPos -= 1;
    delay(TEMPO_FECHAMENTO);
    
    // Verificação de comando de parada durante movimento
    if (bluetoothSerial.available()) {
      char cmd = bluetoothSerial.read();
      if (cmd == 'p') {
        parar(); // Chama função de parada completa
        return;
      }
    }
  }
  
  // Finalização do fechamento
  if (servoPos <= 0) {
    digitalWrite(ledVermelhoPin, LOW);
    enviarConfirmacao("Fechado");
    Serial.println("Fechamento concluído");
  }
  emMovimento = false;
}
//__________________________

void parar() {
  emMovimento = false; // Interrompe qualquer movimento
  
  // Feedback visual com piscada dos LEDs
  for (int i = 0; i < 5; i++) {
    digitalWrite(ledVerdePin, HIGH);
    digitalWrite(ledVermelhoPin, HIGH);
    delay(TEMPO_PISCADA);
    digitalWrite(ledVerdePin, LOW);
    digitalWrite(ledVermelhoPin, LOW);
    delay(TEMPO_PISCADA);
  }
  
  // Confirmação de parada
  enviarConfirmacao("Parado");
  Serial.println("Servo parado");
}
//__________________________

void loop() {
  // Verificação contínua de comandos Bluetooth
  if (bluetoothSerial.available()) {
    char command = bluetoothSerial.read();
    Serial.print("Comando recebido: ");
    Serial.println(command);

    // Processamento dos comandos
    switch(command) {
      case 'a': // Comando de abertura
        if (!emMovimento) abrir();
        break;
      case 'f': // Comando de fechamento
        if (!emMovimento) fechar();
        break;
      case 'p': // Comando de parada
        parar();
        break;
      default:  // Comando inválido
        enviarConfirmacao("Comando invalido");
        Serial.println("Comando inválido recebido");
    }
  }
  
  delay(10); // Pequeno delay para otimização
}