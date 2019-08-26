#include <WiFiEsp.h>
#include <WiFiEspClient.h>
#include <WiFiEspServer.h>
#include <WiFiEspUdp.h>
#include <SoftwareSerial.h>
#include <String.h>

/*
 WiFiEsp example: WebClient
 This sketch connects to google website using an ESP8266 module to
 perform a simple web search.
 For more details see: http://yaab-arduino.blogspot.com/p/wifiesp-example-client.html
*/

#include "WiFiEsp.h"

// Emulate esp on pins 2/3 if not present
#ifndef HAVE_HWesp
#include "SoftwareSerial.h"
SoftwareSerial esp(2, 3); // RX, TX
#endif

char ssid[] = "belkin.785";      // your network SSID (name)
char pass[] = "cyb2e9ce";        // your network password
int status = WL_IDLE_STATUS;     // the Wifi radio's status

char server[] = "10.10.10.3";
String id = "abc";

// Initialize the Ethernet client object
WiFiEspClient client;

void setup()
{
  // initialize serial for debugging
  Serial.begin(115200);
  // initialize serial for ESP module
  esp.begin(9600);
  // initialize ESP module
  WiFi.init(&esp);

  // check for the presence of the shield
  if (WiFi.status() == WL_NO_SHIELD) {
    Serial.println("WiFi shield not present");
    // don't continue
    while (true);
  }

  // attempt to connect to WiFi network
  while ( status != WL_CONNECTED) {
    Serial.print("Attempting to connect to WPA SSID: ");
    Serial.println(ssid);
    // Connect to WPA/WPA2 network
    status = WiFi.begin(ssid, pass);
  }

  // you're connected now, so print out the data
  Serial.println("You're connected to the network");
  
  printWifiStatus();

  Serial.println();
  Serial.println("Starting connection to server...");
  // if you get a connection, report back via serial
  if (client.connect(server, 80)) {
    Serial.println("Connected to server");
    client.println(id);
  } else {
    Serial.println("Connection failed.");
  }
}

void loop()
{
  // if there are incoming bytes available
  // from the server, read them and print them
  while (client.connected()) {
    Serial.print("Available bytes: ");
    Serial.println(client.available());
    if (client.available()) {
      char c = client.read();
      Serial.println(c);
    }
  }

  // if the server's disconnected, stop the client
  if (!client.connected()) {
    Serial.println();
    Serial.println("Disconnecting from server...");
    client.stop();

    // do nothing forevermore
    while (true);
  }
}


void printWifiStatus()
{
  // print the SSID of the network you're attached to
  Serial.print("SSID: ");
  Serial.println(WiFi.SSID());

  // print your WiFi shield's IP address
  IPAddress ip = WiFi.localIP();
  Serial.print("IP Address: ");
  Serial.println(ip);

  // print the received signal strength
  long rssi = WiFi.RSSI();
  Serial.print("Signal strength (RSSI):");
  Serial.print(rssi);
  Serial.println(" dBm");
}

/*#include <Ethernet.h>
#include <SPI.h>
#include <WiFi.h>
#include <SoftwareSerial.h>
#include <SerialESP8266wifi.h>

#define ESP_ID 2

const char* wifi_ssid = "belkin.785";
const char* wifi_pass = "cyb2e9ce";
const char* esp_ssid = "esp_server_1";
const char* esp_pass = "gogreengowhite";
const char* port = "80";
const char* ip = "192.168.4.1";
const bool isSender = false;
const bool isListener = !isSender;

#define ledred 12
#define ledblue 13 
#define ledgreen 4
#define espRx 2
#define espTx 3
#define espReset 0

SoftwareSerial swSerial(espRx, espTx);
SerialESP8266wifi esp(swSerial, swSerial, espReset, Serial);

void setup() {
  swSerial.begin(9600);
  Serial.begin(115200);
  Serial.println("Starting wifi");

  esp.begin(); //resets ESP wifi module
  while(!(esp.isConnectedToAP())){
    esp.connectToAP(esp_ssid, esp_pass); //connects esp to wifi
    Serial.println("...");
  }
  if(esp.isConnectedToAP()){
    Serial.println("Wifi connection successful.");
  }
  swSerial.print("AT+CIFSR\r\n");
  
  Serial.println("Connecting to server");
  while(!esp.isConnectedToServer()){
     esp.connectToServer(ip, port);
     Serial.println("...");
  }
  if(esp.isConnectedToServer()){
    Serial.println("Server connection successful.");
  }
  
}

void loop() {

}
*/
