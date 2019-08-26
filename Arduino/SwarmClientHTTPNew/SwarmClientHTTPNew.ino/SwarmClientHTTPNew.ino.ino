/*
 * Andrew McDonald
 * MSU D-CYPHER Lab
 * SwarmClientHTTP.ino
 * 
 */

#include "WiFiEsp.h"
#include "SoftwareSerial.h"

const String ID = "2";

SoftwareSerial esp(2, 3); // RX, TX

char ssid[] = "belkin.785";            // your network SSID (name)
char pass[] = "cyb2e9ce";        // your network password
int status = WL_IDLE_STATUS;     // the Wifi radio's status

char server[] = "10.10.10.5";

unsigned long last_http_request = 0L;         // last time you http requested the server, in milliseconds
const unsigned long wait = 10000L;             // delay between http updates, in milliseconds

const int num_robots = 2;
const int max_command_length = 100;
const int cmd_sz = num_robots * max_command_length + 10;
const unsigned long server_timeout = 1000L;

float command_ary[5]{};


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
  
  if (command.length() > 0 && !command.equals(old_command)) {
    // we received a *NEW* command
    Serial.println("Command received");
    Serial.println(command);
    if (has_command(command) == true) {
      Serial.println("Specific command recieved for ID " + ID);
      parse_command(command, command_ary);
      Serial.println("X: " + String(command_ary[0]));
      Serial.println("Y: " + String(command_ary[1]));
      Serial.println("X goto: " + String(command_ary[2]));
      Serial.println("Y goto: " + String(command_ary[3]));
      Serial.println("Angle: " + String(command_ary[4]));
    }
  }

  // request after wait period
  if (millis() - last_http_request > wait) {
    httpRequest();
  }

  // reset old_command to compare to future messages to see if command is new
  old_command = command;
}

// check to see if my ID has a command
bool has_command(String& command) {
  if(command.indexOf("<" + ID + ">") != -1 && command.indexOf("<start>") != -1 && command.indexOf("<end>") != -1) {
    return true;
  } else {
    return false;
  }
}

bool msg_complete(String command) {
  if (command.indexOf("<end>") > -1) {
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

  Serial.println("debug check; command:");
  Serial.println(command);
  Serial.println("start:");
  Serial.println(start);
  Serial.println("finish:");
  Serial.println(finish);
  Serial.println("My command:");
  Serial.println(my_command);

  
  int x_start = my_command.indexOf("<pos>") + 5;
  int x_finish = my_command.indexOf(",", x_start);
  String my_x = my_command.substring(x_start, x_finish);
  float x = my_x.toFloat();

  int y_start = x_finish + 1;
  int y_finish = my_command.indexOf("</pos>");
  String my_y = my_command.substring(y_start, y_finish);
  float y = my_y.toFloat();

  int x_goto_start = my_command.indexOf("<goto>") + 6;
  int x_goto_finish = my_command.indexOf(",", x_goto_start);
  String my_x_goto = my_command.substring(x_goto_start, x_goto_finish);
  float x_goto = my_x_goto.toFloat();

  int y_goto_start = x_goto_finish + 1;
  int y_goto_finish = my_command.indexOf("</goto>");
  String my_y_goto = my_command.substring(y_goto_start, y_goto_finish);
  float y_goto = my_y_goto.toFloat();

  int ang_start = my_command.indexOf("<ang>") + 5;
  int ang_finish = my_command.indexOf("</ang>");
  String my_ang = my_command.substring(ang_start, ang_finish);
  float ang = my_ang.toFloat();
  Serial.println("x debug: ");
  Serial.println(x);
  Serial.println("y debug: ");
  Serial.println(y);
  Serial.println("xgoto debug: ");
  Serial.println(x_goto);
  Serial.println("ygoto debug: ");
  Serial.println(y_goto);
  Serial.println("ang debug: ");

  
  ary[0] = x;
  ary[1] = y;
  ary[2] = x_goto;
  ary[3] = y_goto;
  ary[4] = ang;
}

// makes a HTTP connection to the server
void httpRequest()
{
  Serial.println();
    
  // close any connection before send a new request
  // this will free the socket on the WiFi shield
  client.stop();

  // if there's a successful connection
  if (client.connect(server, 80)) {
    Serial.println("Connecting...");
    
    // send the HTTP PUT request
    client.print("\r");
    // note the time that the connection was made
    last_http_request = millis();
  }
  else {
    // if you couldn't make a connection
    Serial.println("Connection failed");
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
