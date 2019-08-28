/*
 * Andrew McDonald
 * MSU D-CYPHER Lab
 * SwarmClientHTTP.ino
 * 
 */

#include "WiFiEsp.h"
#include "WiFiEspUdp.h"
#include "SoftwareSerial.h"
#include "MMEmotor.h"
#include "ArduinoJson.h"

// define motor pins pins to control the motors: PWM
#define PWMA 5  // motor A
#define AIN1 7
#define AIN2 6
#define STBY 8  // Standby pin of TB6612. Shared by both channels
#define PWMB 11 // motor B
#define BIN1 9
#define BIN2 10

// initialize motor objects
MMEmotor motorb  = MMEmotor(BIN1, BIN2, PWMB, STBY);
MMEmotor motora  = MMEmotor(AIN1, AIN2, PWMA, STBY);

// assign unique ID to robot
const String ID = "1";
const unsigned long ID_NUM = 1;

// configure ESP, WiFi & UDP
SoftwareSerial esp(2, 3);        // (RX, TX); enables communication with ESP
char ssid[] = "belkin.785";      // your network SSID (name)
char pass[] = "cyb2e9ce";        // your network password
int status = WL_IDLE_STATUS;     // the Wifi radio's status
unsigned int localPort = 8080;   // local port to listen for UDP commands on
char packetBuffer[255];          // buffer to hold incoming packet
WiFiEspUDP Udp;

void setup() {
  // initialize serial for debugging
  Serial.begin(115200);
  // initialize serial for ESP module
  esp.begin(9600);
  // initialize ESP module
  WiFi.init(&esp);

  // check for the presence of the shield:
  if (WiFi.status() == WL_NO_SHIELD) {
    Serial.println("WiFi shield not present");
    // don't continue:
    while (true);
  }

  // attempt to connect to WiFi network
  while ( status != WL_CONNECTED) {
    Serial.print("Attempting to connect to WPA SSID: ");
    Serial.println(ssid);
    // connect to WPA/WPA2 network
    status = WiFi.begin(ssid, pass);
  }
  
  Serial.println("Connected to WiFi");
  printWifiStatus();

  // begin listening on localPort for UDP broadcasts
  Serial.println("\nStarting connection to server...");
  Udp.begin(localPort);
  Serial.print("Listening on port ");
  Serial.println(localPort);
}

void loop() {
  // if there's a UDP packet available, read it
  int packetSize = Udp.parsePacket();
  if (packetSize) {
    int len = Udp.read(packetBuffer, 255);
    if (len > 0) {
      packetBuffer[len] = 0;
    }
    // print out raw command received
    Serial.print("Raw command: ");
    Serial.println(packetBuffer);

    // parse raw command to see if this ID specifically received a command
    String command = String(packetBuffer);
    if (has_command(command) == true) {

      // print out specific command received for this ID
      Serial.println("Specific command recieved for ID " + ID);

      // parse command to get angle and burst velocity
      float my_command[2];
      parse_command(command, my_command);
      float ang = my_command[0];
      float velocity = my_command[1];
      Serial.println("ang: " + String(ang));
      Serial.println("v: " + String(velocity));

      // execute command
      drive(ang, velocity);
    }
  }
  delay(50);
}

////////// parsing helper methods //////////

// check to see if this ID has received a valid command of the form
// <start> . . . <ID>angle,velocity</ID> . . . <end>
bool has_command(String& command) {
  if(command.indexOf("<" + ID + ">") != -1 && command.indexOf("<start>") != -1 && command.indexOf("<end>") != -1) {
    return true;
  } else {
    return false;
  }
}

// parses command for turn angle and velocity to be executed by robot from command of the form
// <start> . . . <ID>angle,velocity</ID> . . . <end>
void parse_command(String& command, float ary[]) {
  String my_command = "";
  int start = command.indexOf("<" + ID + ">") + 2 + ID.length();
  int finish = command.indexOf("</" + ID + ">");
  my_command = command.substring(start, finish);
  
  int ang_start = 0;
  int ang_finish = my_command.indexOf(",", ang_start);
  String my_ang = my_command.substring(ang_start, ang_finish);
  float ang = my_ang.toFloat();

  int v_start = ang_finish + 1;
  String my_v = my_command.substring(v_start);
  float v = my_v.toFloat();

  ary[0] = ang;
  ary[1] = v;
}

////////// drive helper methods //////////

void drive(float ang, float velocity) {
  turn(ang);
  burst(velocity);
}

void turn(float deg) {
  float constant = 7;
  if (deg > 0) {
    // left turn (CCW = +)
    motora.backward(50);
    motorb.forward(50);
    delay(abs(int(deg * constant)));
    fullstop();
  } else {
    // right turn (CW = -)
    motora.forward(50);
    motorb.backward(50);
    delay(abs(int(deg * constant)));
    fullstop();
  }
}

void burst(float velocity) {
  int pwr = int(velocity);
  startup(pwr);
  slowdown(pwr);
}

void startup(int sped){
  for(int i = 0; i < sped; i++){
    motora.backward(i);
    motorb.backward(i);
    delay(5);
  }
}

void slowdown(int sped){
  for(int i = sped; i >= 0; i--){
    motora.backward(i);
    motorb.backward(i);
    delay(5);
  }
  fullstop();
}

void fullstop(){
  motora.brake();
  motorb.brake();
}

////////// networking helper methods //////////

void printWifiStatus() {
  // print the SSID of the network you're attached to:
  Serial.print("SSID: ");
  Serial.println(WiFi.SSID());

  // print your WiFi shield's IP address:
  IPAddress ip = WiFi.localIP();
  Serial.print("IP Address: ");
  Serial.println(ip);

  // print the received signal strength:
  long rssi = WiFi.RSSI();
  Serial.print("signal strength (RSSI):");
  Serial.print(rssi);
  Serial.println(" dBm");
}
