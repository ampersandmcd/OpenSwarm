/*
 * Andrew McDonald
 * MSU D-CYPHER Lab
 * SwarmClientHTTP.ino
 * 
 */

#include "WiFiEsp.h"
#include "SoftwareSerial.h"
#include <MMEmotor.h>

// define motor pins pins to control the motors: PWM
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

const String ID = "3";
const unsigned long ID_NUM = 3;


SoftwareSerial esp(2, 3); // RX, TX

char ssid[] = "belkin.785";            // your network SSID (name)
char pass[] = "cyb2e9ce";        // your network password
int status = WL_IDLE_STATUS;     // the Wifi radio's status

const char server[] = "10.10.10.3";

unsigned long last_http_request = 0L;                         // last time you http requested the server, in milliseconds
const unsigned long wait = 100L;             // delay between http updates, in milliseconds

const int num_robots = 2;
const int max_command_length = 100;
const int cmd_sz = num_robots * max_command_length + 10;
const unsigned long server_timeout = 100L;

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
  while (status != WL_CONNECTED) {
    Serial.print("Attempting to connect to WPA SSID: ");
    Serial.println(ssid);
    // Connect to WPA/WPA2 network
    status = WiFi.begin(ssid, pass);
  }

  Serial.println("You're connected to the network with ID " + ID);
  
  printWifiStatus();
}

String command = "";
String old_command = command;

void loop()
{
  // if there's incoming data from the net connection send it out the serial port
  // & concatenate to current command
  //get_command();
  //client.stop();
  
  if (command.length() > 0 && !command.equals(old_command)) {
    Serial.println("Command received");
    Serial.println(command);
    if (has_command(command) == true) {
      Serial.println("Specific command recieved for ID " + ID);
      float my_command[2];
      parse_command(command, my_command);
      Serial.println("ang: " + String(my_command[0]));
      Serial.println("v: " + String(my_command[1]));
      drive(my_command);
      old_command = command;
    } else {
      get_command();
    }
  } else {
    get_command();
  }

  // request after wait period
  if (millis() - last_http_request > wait) {
    httpRequest();
  }

  // reset old_command to compare to future messages to see if command is new
  //old_command = command;
}

void get_command() {
  if (client.connected()) {
    if (client.available()) {
      command = "";
      command.reserve(cmd_sz);
      unsigned long start_time = millis();
      while (millis() - start_time < server_timeout) {
        if (client.available()) {
          char c = client.read();
          command += String(c);
        }
      }
    }
  }
}

// check to see if my ID has a command
bool has_command(String& command) {
  if(command.indexOf("<" + ID + ">") != -1 && command.indexOf("<start>") != -1 && command.indexOf("<end>") != -1) {
    return true;
  } else {
    return false;
  }
}

// parses command for position and goto of robot
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

// makes a HTTP connection to the server
void httpRequest()
{
  client.stop();
  Serial.println();
  // if there's a successful connection
  if (client.connect(server, 80)) {
    Serial.println("Connected.");
    client.print("\r\n");
    last_http_request = millis();
  } else {
    // if you couldn't make a connection
    Serial.println("failed");
    client.connect(server, 80);
    delay(500);
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

void drive(float my_command[2]) {
  float ang = my_command[0];
  float velocity = my_command[1];
  turn(ang);
  burst(velocity);
}

void turn(float deg) {
  float constant = 7;
  if (deg > 0) {
    //right turn
    motora.forward(50);
    motorb.backward(50);
    delay(int(deg * constant));
    fullstop();
  } else {
    //left turn
    motora.backward(50);
    motorb.forward(50);
    delay(abs(int(deg * constant)));
    fullstop();
  }
}

void burst(float velocity) {
  int pwr = int(velocity);
  startup(pwr);
  get_command(); //serves as delay!
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
