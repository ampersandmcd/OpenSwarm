#include <SoftwareSerial.h>
SoftwareSerial esp8266(2,3); //Pin 2 & 3 of Arduino as RX and TX. Connect TX and RX of ESP8266 respectively.
#define DEBUG true
#define ledred 12
#define ledblue 13 
#define ledgreen 4

void setup()
  {
    pinMode(12, OUTPUT);
    pinMode(13, OUTPUT);
    pinMode(4,OUTPUT);
    digitalWrite(4,LOW);
    digitalWrite(12, LOW);
    digitalWrite(13, HIGH);
    
    Serial.begin(38400);
    //esp8266.begin(115200);
    //esp8266Serial("AT+UART_DEF=9600,8,1,0,0", 1000, DEBUG);
    //esp8266.end();
    esp8266.begin(9600); //Baud rate for communicating with ESP8266. Your's might be different.
    wificonnect();

    Serial.println("connecting to server...");
    bool cond = 0;
    String rawmsg1 = esp8266Serial("AT+CIPSTART=\"TCP\",\"10.10.10.3\",80\r\n", 5000, DEBUG);
    Serial.println(rawmsg1);
    if(rawmsg1.indexOf("OK") > 0){
      cond = 1;
      Serial.println("server connected");
      esp8266Serial("AT+CIPSEND=3\r\n", 500, DEBUG);
      delay(300);
      esp8266Serial("2",1000,DEBUG);
      Serial.println("done sending"); 
    }else{
      Serial.println("Server Failure");
    }
    Serial.println("about to close server");
    String closemsg = esp8266Serial("AT+CIPCLOSE\r\n", 1000, DEBUG);
    Serial.println("\n CLOSING MESSAGE:" + closemsg);
    Serial.println("closed server");
    if(cond){
      String sig1 = closemsg.substring(60,87);
      String sig2 = closemsg.substring(72,75);
      String sig3 = closemsg.substring(84,87);
      Serial.println("\n ACTUAL DATA 1:" + sig1);
      Serial.println("\n ACTUAL DATA 2:" + sig2);
      Serial.println("\n ACTUAL DATA 3:" + sig3);
      Serial.println("\n RESULT 1:" + String(sig1.indexOf("aaa")));
      Serial.println("\n RESULT 2:" + String(sig1.indexOf("bbb")));
      
      if(sig1.indexOf("aaa") >= 0){
        Serial.println("PERFORMING AAA");
        blinkled(13,500);
      }else if(sig1.indexOf("bbb") >= 0){
        Serial.println("PERFORMING BBB");
        blinkled(13,300);
        delay(200);
        blinkled(13,300);
      }
      else{
        Serial.println("NOT PERFORMING");
        blinkled(4,500);
      }
    }
  }

void loop()
  {
    
  
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
    while ( millis() - time < timeout)
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
    delay(100);
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
