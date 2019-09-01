/*
 * Andrew McDonald
 * MSU D-CYPHER Lab
 * Pathfinder.ino
 * 
 */

#include "WiFiEsp.h"
#include "WiFiEspUdp.h"
#include "SoftwareSerial.h"
#include "MMEmotor.h"

struct Configuration 
{
  // identifier configuration
  int ID = 1;

  // network configuration
  char SSID[64] = "belkin.785";
  char Password[64] = "cyb2e9ce";
  int RXPort = 8080;
  int TXPort = 8000 + ID;
  unsigned long SerialBaud = 115200;
  int ESPBaud = 9600;

  // preferences
  bool Debug = true;

  // pin configuration
  int MotorPWMA = 5;
  int MotorAIN1 = 7;
  int MotorAIN2 = 6;
  int MotorSTBY = 8;
  int MotorPWMB = 11;
  int MotorBIN1 = 9;
  int MotorBIN2 = 10;
  int SoftwareSerialRX = 2;
  int SoftwareSerialTX = 3;
};

// create configuration object
Configuration Config = *(new Configuration());

// initialize global objects
MMEmotor MotorB  = MMEmotor(Config.MotorBIN1, Config.MotorBIN2, Config.MotorPWMB, Config.MotorSTBY);
MMEmotor MotorA  = MMEmotor(Config.MotorAIN1, Config.MotorAIN2, Config.MotorPWMA, Config.MotorSTBY);

// enable communication with ESP
SoftwareSerial ESP(Config.SoftwareSerialRX, Config.SoftwareSerialTX);

// initialize buffer to store incoming message
char Buffer[255];          

// enable UDP communication over WiFi network
WiFiEspUDP Udp;

void setup() 
{

  // initialize communication between serial, ESP and wifi
  Serial.begin(Config.SerialBaud);
  ESP.begin(Config.ESPBaud);
  WiFi.init(&ESP);

  // check for the presence of the shield:
  /*int status = WiFi.status();
  if (WiFi.status() == WL_NO_SHIELD) {
    Serial.println("WiFi shield not present");
    // don't continue:
    while (true);
  }*/

  // attempt to connect to WiFi network
  int status = WiFi.status();

  while (status != WL_CONNECTED) 
  {
    Debug("Attempting to connect to WPA SSID: " + String(Config.SSID));
    status = WiFi.begin(Config.SSID, Config.Password);
  }
  
  Debug("Connected to WiFi.");
  if (Config.Debug)
  {
    PrintWifiStatus();
  }

  // begin listening on RXPort for UDP broadcasts
  Debug("Starting connection to server...");
  Udp.begin(Config.RXPort);
  Debug("Listening on port " + String(Config.RXPort));
}

void loop() {
  // if there's a UDP packet available, read it
  int packetSize = Udp.parsePacket();
  if (packetSize) {
    int len = Udp.read(Buffer, 255);
    if (len > 0) {
      Buffer[len] = 0;
    }
    // print out raw command received
    Serial.print("Raw command: ");
    Serial.println(Buffer);

    // parse raw command to see if this ID specifically received a command
    String command = String(Buffer);
    if (has_command(command) == true) {

      // print out specific command received for this ID
      Serial.println("Specific command recieved for ID " + String(Config.ID));

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
  if(command.indexOf("<" + String(Config.ID) + ">") != -1 && command.indexOf("<start>") != -1 && command.indexOf("<end>") != -1) {
    return true;
  } else {
    return false;
  }
}

// parses command for turn angle and velocity to be executed by robot from command of the form
// <start> . . . <ID>angle,velocity</ID> . . . <end>
void parse_command(String& command, float ary[]) {
  String my_command = "";
  int start = command.indexOf("<" + String(Config.ID) + ">") + 2 + String(Config.ID).length();
  int finish = command.indexOf("</" + String(Config.ID) + ">");
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
    MotorA.backward(50);
    MotorB.forward(50);
    delay(abs(int(deg * constant)));
    fullstop();
  } else {
    // right turn (CW = -)
    MotorA.forward(50);
    MotorB.backward(50);
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
    MotorA.backward(i);
    MotorB.backward(i);
    delay(5);
  }
}

void slowdown(int sped){
  for(int i = sped; i >= 0; i--){
    MotorA.backward(i);
    MotorB.backward(i);
    delay(5);
  }
  fullstop();
}

void fullstop(){
  MotorA.brake();
  MotorB.brake();
}

////////// networking helper methods //////////

void PrintWifiStatus()
{
  Serial.println("WiFi Status:");

  // Print SSID info
  String SSID = WiFi.SSID();
  Serial.println("\tSSID: " + SSID);

  // Print IP info
  String IP = IPToString(WiFi.localIP());
  Serial.println("\tIP Address: " + IP);

  // Print signal strength
  String RSSI = String(WiFi.RSSI());
  Serial.println("\tSignal strength (RSSI): " + RSSI + " dBm");
}

String IPToString(IPAddress IP)
{
  return String(IP[0]) + "."
  + String(IP[1]) + "."
  + String(IP[2]) + "."
  + String(IP[3]);
}

///////////// Debug helper ///////////////

void Debug(String message)
{
  if (Config.Debug)
  {
    Serial.println(message);
  }
}
