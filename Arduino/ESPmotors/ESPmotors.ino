#include <SoftwareSerial.h>
#include <MMEmotor.h>
SoftwareSerial esp8266(2,3); //Pin 2 & 3 of Arduino as RX and TX. Connect TX and RX of ESP8266 respectively.
#define DEBUG true
#define led_pin1 12
#define led_pin2 13 //LED is connected to Pin 11 of Arduino

// Logic pins to control the motors: PWMA and PWMB must be pins capable of PWM output
// User needs to correctly wire these pins to corresponding contacts on TB6612 breakout
#define PWMA 5  // Motor A
#define AIN1 7
#define AIN2 6

#define STBY 8   // Standby pin of TB6612. Shared by both channels

#define PWMB 11   // Motor B
#define BIN1 9
#define BIN2 10

// -- Initialize a Motor object to control the motor on the paper roller
MMEmotor motorb  = MMEmotor(BIN1, BIN2, PWMB, STBY);
MMEmotor motora  = MMEmotor(AIN1, AIN2, PWMA, STBY);

void setup()
  {
    pinMode(led_pin1, OUTPUT);
    pinMode(led_pin2, OUTPUT);
    pinMode(4,OUTPUT);
    digitalWrite(4,LOW);
    digitalWrite(led_pin1, LOW);
    digitalWrite(led_pin2, LOW);
    
    digitalWrite(13, HIGH);
    Serial.begin(115200);
    Serial.println("Connected.");
    esp8266.begin(115200); //Baud rate for communicating with ESP8266. Your's might be different.
    esp8266Serial("AT+UART_DEF=9600,8,1,0,0\r\n", 500, DEBUG); // Reset the ESP8266 baudrate to 9600bps
    esp8266.end();
    esp8266.begin(9600);
    wificonnect();
  }

void loop()
  {
    if (esp8266.available())
      {
        if (esp8266.find("+IPD,"))
          {
            esp8266.find("?");
            String msg = esp8266.readStringUntil(' ');
            Serial.println(msg);
            String command1 = msg.substring(0, 4);
            Serial.println(command1);
            String command2 = msg.substring(5);
            Serial.println(command2);
            Serial.println(msg);
                        
            if (DEBUG) 
              {
                //Serial.println(command1);//Must print "led"
                Serial.println(command2);//Must print "ON" or "OFF"
              }
            delay(100);

              if (command2 == "FWD") 
                    {
                      blinkled(13,500);
                      drivefwd(300,255);
                      fullstop();
                      blinkled(4,300);
                      delay(500);
                    
                    }
                    else if(command2 == "BACK") 
                     {
                       blinkled(13,500);
                       driveback(800,255);
                       fullstop();
                       blinkled(4,300);
                       delay(1000);
                     }
                    else if(command2 == "LEFT") 
                     {
                       blinkled(13,500);
                       turnleft(500);
                       fullstop();
                       blinkled(4,300);
                       delay(1000);
                     }
                   else if(command2 == "RIGHT") 
                     {
                       blinkled(13,500);
                       turnright(500);
                       fullstop();
                       blinkled(4,300);
                       delay(1000);
                     }
                    else
                     {
                      blinkled(4,500);
                     }
          }
      }
  }
void startup(int sped){
  for(int i = 0; i < sped; i++){
    motora.forward(i);
    motorb.forward(i);
    delay(5);
  }
}
void slowdown(int sped){
  for(int i = sped; i >= 0; i--){
    motora.backward(i);
    motorb.backward(i);
    delay(5);
  }
}
void drivefwd(int times, int speds){
  startup(speds);
  motora.forward(speds);
  motorb.forward(speds);
  delay(times);
}   
void driveback(int times, int speds){
  motora.backward(speds);
  motorb.backward(speds);
  slowdown(speds);
  delay(times);
} 
void turnleft(int times){
  motora.backward(50);
  motorb.forward(50);
  delay(times);
}
void turnright(int times){
  motora.forward(50);
  motorb.backward(50);
  delay(times);
}
void fullstop(){
  motora.brake();
  motorb.brake();
}
void blinkled(int pin,int times){
  digitalWrite(pin, HIGH);
  delay(times);
  digitalWrite(pin, LOW);
}
String esp8266Serial(String command, const int timeout, boolean debug)
  {
    String response = "";
    esp8266.print(command);
    long int time = millis();
    while ( (time + timeout) > millis())
      {
        while (esp8266.available())
          {
            char c = esp8266.read();
            response += c;
          }
      }
    if (debug)
      {
        Serial.print("SENT: " + response + "\n");
      }
    return response;
}
void wificonnect(){
    esp8266Serial("AT+RST\r\n", 500, DEBUG); // Reset the ESP8266
    esp8266Serial("AT+CWMODE=1\r\n", 500, DEBUG); //Set station mode Operation
    esp8266Serial("AT+CWJAP=\"belkin.785\",\"cyb2e9ce\"\r\n", 500, DEBUG);//Enter your WiFi network's SSID and Password.
    
    digitalWrite(13, LOW); //status indicator LED lighting
    blinkled(12,500);
    digitalWrite(13, HIGH);
                                   
    while(!esp8266.find("OK")) 
    {
      }
    esp8266Serial("AT+CIFSR\r\n", 500, DEBUG);//You will get the IP Address of the ESP8266 from this command.
   
    digitalWrite(13, LOW); //status indicator LED lighting
    blinkled(12,500);
    digitalWrite(13, HIGH);
    
    esp8266Serial("AT+CIPMUX=1\r\n", 500, DEBUG);
    esp8266Serial("AT+CIPSERVER=1,80\r\n", 500, DEBUG);

    digitalWrite(13, LOW); //status indicator LED lighting
    blinkled(12,300);
    blinkled(13,500);
    digitalWrite(12, HIGH);
}
