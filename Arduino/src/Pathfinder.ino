/*
 * Andrew McDonald
 * MSU D-CYPHER Lab
 * Pathfinder.ino
 */

// include external libraries
#include "WiFiEsp.h"
#include "WiFiEspUdp.h"
#include "SoftwareSerial.h"
#include "MMEmotor.h"

// include user-defined code
#include "include/Configuration.h"
#include "include/Utils.h"
#include "include/Driver.h"

// create configuration object
Configuration Config = Configuration();

// initialize global objects
MMEmotor MotorB  = MMEmotor(Config.MotorBIN1, Config.MotorBIN2, Config.MotorPWMB, Config.MotorSTBY);
MMEmotor MotorA  = MMEmotor(Config.MotorAIN1, Config.MotorAIN2, Config.MotorPWMA, Config.MotorSTBY);
Driver Controller = Driver(MotorA, MotorB);

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

  if (packetSize > 0) 
  {
    // get length of incoming message
    int length = Udp.read(Buffer, 255);

    if (length > 0) 
    {
      // indicate end of incoming message in buffer
      Buffer[length] = 0;
    }
    
    // store message in string for parsing
    String message = String(Buffer);
    Debug("\tRaw message received: " + message);

    // parse message and see if it contains relevant command
    if (HasCommand(message)) 
    {
      // parse command to get angle and burst velocity for this ID
      float command[2];
      ParseCommand(message, command);

      float angle = command[0];
      float velocity = command[1];

      Debug("\tRobot ID: " + String(Config.ID));
      Debug("\t\tAngle: " + String(angle));
      Serial.println("\t\tVelocity: " + String(velocity));

      // execute command
      Controller.Drive(angle, velocity);
    }
  }
  delay(Config.DelayInterval);
}

////////// parsing helper methods //////////

// check to see if this ID has received a valid command of the form
// <start> . . . <ID>angle,velocity</ID> . . . <end>
bool HasCommand(String& command) {
  if(command.indexOf("<" + String(Config.ID) + ">") != -1 && command.indexOf("<start>") != -1 && command.indexOf("<end>") != -1) {
    return true;
  } else {
    return false;
  }
}

// parses command for turn angle and velocity to be executed by robot from command of the form
// <start> . . . <ID>angle,velocity</ID> . . . <end>
void ParseCommand(String& command, float ary[]) {
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

////////// Drive helper methods //////////



////////// networking helper methods //////////



///////////// Debug helper ///////////////

void Debug(String message)
{
  if (Config.Debug)
  {
    Serial.println(message);
  }
}
