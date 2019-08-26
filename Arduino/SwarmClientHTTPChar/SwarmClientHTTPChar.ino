/*
 * Andrew McDonald
 * MSU D-CYPHER Lab
 * SwarmClientHTTP.ino
 * 
 */

#include "WiFiEsp.h"
#include "SoftwareSerial.h"

String id = "1";
const int id_sz = 1;

SoftwareSerial esp(2, 3); // RX, TX

char ssid[] = "belkin.785";            // your network SSID (name)
char pass[] = "cyb2e9ce";        // your network password
int status = WL_IDLE_STATUS;     // the Wifi radio's status

char server[] = "10.10.10.3";

unsigned long last_http_request = 0;         // last time you http requested the server, in milliseconds
const unsigned long wait = 2000L;             // delay between http updates, in milliseconds

const int  num_robots = 2;
const int max_cmd_length = 120;
const int cmd_arr_sz = num_robots + max_cmd_length + 10;

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

  Serial.println("You're connected to the network with ID " + id);
  
  printWifiStatus();
}

char cmd_arr[cmd_arr_sz];

void loop()
{
  //cmd_arr[0] = '!';
  int count = 0;
  
  // if there's incoming data from the net connection send it out the serial port
  // & concatenate to current command
  while (client.connected()) {
      while (client.available()) {
        char c = client.read();
        cmd_arr[count] = c;
        ++count;
        delay(10);
    }
  }

  if (cmd_arr[0] != '!') {
    // we received a command
    Serial.println("Command received");
    Serial.println(cmd_arr);
    if (has_command(cmd_arr, cmd_arr_sz) == true) {
      Serial.print("Specific command recieved for ID " + id);
      float my_command[5];
      parse_command(cmd_arr, cmd_arr_sz, my_command);
      Serial.println("X: " + String(my_command[0]));
      Serial.println("Y: " + String(my_command[1]));
      Serial.println("X goto: " + String(my_command[2]));
      Serial.println("Y goto: " + String(my_command[3]));
      Serial.println("Angle: " + String(my_command[4]));
    }
  }

  // request after wait period
  if (millis() - last_http_request > wait) {
    httpRequest();
  }
}

int find_str(char command[], int sz, String key, int start=0) {
  for (int i = start; i < sz - key.length(); ++i) {
    for (int j = 0; j < key.length(); ++j) {
      if (command[i + j] != key[j]) {
        break;
      }
      // if we get here, we found a match
      return i;
    }
  }
  return -1;
}

void sub_char(char command[], int sz, char my_command[], int my_cmd_sz, int start, int finish) {
  if (start < 0 || finish < 0 || start > sz || finish > sz || finish-start > my_cmd_sz) {
    return;
  } else {
    for (int i = start, j = 0; i < finish; ++i, ++j) {
      my_command[j] = command[i];
    }
    return;
  }
}

// check to see if my ID has a command
bool has_command(char command[], int sz) {
  if (find_str(command, sz, ("<" + id + ">")) > -1) {
    return true;
  } else {
    return false;
  }
}
/*bool msg_complete(String command) {
  if (find_str(command, sz, "<end>") > -1) {
    return true;
  } else {
    return false;
  }
}*/

// parses command for position and goto of robot
void parse_command(char command[], int sz, float ary[]) {
  char my_command[max_cmd_length];
  int start = find_str(command, sz, ("<" + id + ">")) + id_sz;
  int finish = find_str(command, sz, ("</" + id + ">"));
  sub_char(command, sz, my_command, max_cmd_length, start, finish);
  
  int x_start = find_str(command, sz, "<pos>") + 5;//my_command.indexOf("<pos>") + 5;
  int x_finish = find_str(command, sz, ",", x_start);//my_command.indexOf(",", x_start);
  int my_x_sz = x_finish - x_start;
  char my_x[my_x_sz];
  sub_char(my_command, max_cmd_length, my_x, my_x_sz, x_start, x_finish);
  //String my_x = my_command.substring(x_start, x_finish);
  float x = atof(my_x);

  int y_start = x_finish + 1;
  int y_finish = find_str(command, sz, "</pos>");//my_command.indexOf("</pos>");
  int my_y_sz = y_finish - y_start;
  char my_y[my_y_sz];
  sub_char(my_command, max_cmd_length, my_y, my_y_sz, y_start, y_finish);
  //String my_y = my_command.substring(y_start, y_finish);
  float y = atof(my_y);

  int x_goto_start = find_str(command, sz, "<goto>") + 6;//my_command.indexOf("<goto>") + 6;
  int x_goto_finish = find_str(command, sz, ",", x_goto_start);//my_command.indexOf(",", x_goto_start);
  int my_x_goto_sz = x_goto_start - x_goto_finish;
  char my_x_goto[my_x_goto_sz];
  sub_char(my_command, max_cmd_length, my_x_goto, my_x_goto_sz, x_goto_start, x_goto_finish);
  //String my_x_goto = my_command.substring(x_goto_start, x_goto_finish);
  float x_goto = atof(my_x_goto);

  int y_goto_start = x_goto_finish + 1;
  int y_goto_finish = find_str(command, sz, "</goto>");//my_command.indexOf("</goto>");
  int my_y_goto_sz = y_goto_finish - y_goto_start;
  char my_y_goto[my_y_goto_sz];
  sub_char(my_command, max_cmd_length, my_y_goto, my_y_goto_sz, y_goto_start, y_goto_finish);
  //String my_y_goto = my_command.substring(y_goto_start, y_goto_finish);
  float y_goto = atof(my_y_goto);

  int ang_start = find_str(command, sz, "<ang>") + 5;//my_command.indexOf("<ang>") + 5;
  int ang_finish = find_str(command, sz, "</ang>"); //my_command.indexOf("</ang>");
  int my_ang_sz = ang_finish - ang_start;
  char my_ang[my_ang_sz];
  sub_char(my_command, max_cmd_length, my_ang, my_ang_sz, ang_start, ang_finish);
  //String my_ang = my_command.substring(ang_start, ang_finish);
  float ang = atof(my_ang);

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
    client.print("GET / HTTP/1.1\r\n"
                 "Host: 10.10.10.3\r\n"
                 "\r\n");
    // note the time that the connection was made
    last_http_request = millis();
  }
  else {
    // if you couldn't make a connection
    Serial.println("Connection failed");
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
