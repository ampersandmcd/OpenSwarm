/*
 * Andrew McDonald
 * Michigan State University D-CYPHER Lab
 * Pathfinder.ino
 * 9.1.19
 * 
 * Parses and executes navigation commands of the form '<ROBOT_ID>angle,velocity</ROBOT_ID>' sent via UDP broadcast from a Matlab server
 * in order to guide the convergence of a swarm of client robots on a set of target positions.
 * 
 * These navigation commands are generated on the server-side by analyzing an overhead image of each client robot's current position and comparing it against
 * a matrix of target positions; then, a string of commands is generated indicating to each robot to turn a certain angle and burst a certain speed to approach its target.
 * 
 * These commands are broadcast iteratively over UDP, ultimately leading to the convergence of a swarm on a set of targets specified in a target matrix.
 */

// include external libraries
#include "WiFiEspUdp.h"
#include "SoftwareSerial.h"
#include "MMEmotor.h"

// include user-defined code
#include "include/Configuration.h"
#include "include/Utilities.h"
#include "include/Driver.h"
#include "include/Parser.h"

// create configuration object
Configuration CONFIG = Configuration();

// initialize global objects
MMEmotor MOTORB = MMEmotor(CONFIG.MotorBIN1, CONFIG.MotorBIN2, CONFIG.MotorPWMB, CONFIG.MotorSTBY);
MMEmotor MOTORA = MMEmotor(CONFIG.MotorAIN1, CONFIG.MotorAIN2, CONFIG.MotorPWMA, CONFIG.MotorSTBY);
Utilities UTILS = Utilities(CONFIG);
Driver DRIVER = Driver(MOTORA, MOTORB, CONFIG, UTILS);
Parser PARSER = Parser(CONFIG);

// enable communication with ESP
SoftwareSerial ESP(CONFIG.SoftwareSerialRX, CONFIG.SoftwareSerialTX);

// initialize buffer to store incoming message
char RxBuffer[255];

// initialize buffer to store outgoing message
char TxBuffer[4];

// enable UDP communication over WiFi network
WiFiEspUDP UDP;

void setup()
{
    // initialize communication between serial, ESP and wifi
    Serial.begin(CONFIG.SerialBaud);
    ESP.begin(CONFIG.ESPBaud);
    WiFi.init(&ESP);

    // attempt to connect to WiFi network
    int status = WiFi.status();

    while (status != WL_CONNECTED)
    {
        UTILS.Debug("Attempting to connect to WPA SSID: " + String(CONFIG.SSID));
        status = WiFi.begin(CONFIG.SSID, CONFIG.Password);
    }

    UTILS.Debug(String("Connected to WiFi."));
    UTILS.DebugWifiStatus();

    // begin listening on RXPort for UDP broadcasts
    UTILS.Debug(String("Starting connection to server..."));
    UDP.begin(CONFIG.RXPort);
    UTILS.Debug("Listening on port " + String(CONFIG.RXPort));
}

void loop()
{
    // if there's a UDP packet available, read it
    int packetSize = UDP.parsePacket();

    if (packetSize > 0)
    {
        // get length of incoming message
        int length = UDP.read(RxBuffer, 255);

        if (length > 0)
        {
            // indicate end of incoming message in buffer
            RxBuffer[length] = 0;
        }

        // store message in string for parsing
        String message = String(RxBuffer);
        UTILS.Debug("\tRaw message received: " + message);

        // parse message and see if it contains relevant command
        if (PARSER.HasCommand(message))
        {
            // send back light level data
            if (CONFIG.LDRMode)
            {
                // read light level
                UTILS.GetLightLevel(TxBuffer);

                // write light level over UDP
                UTILS.Debug("\t\tSending to: " + UTILS.IPToString(CONFIG.TXIP) + ":" + String(CONFIG.TXPort));
                UDP.beginPacket(CONFIG.TXIP, CONFIG.TXPort);
                UDP.write(TxBuffer);
                UDP.endPacket();
            }

            // parse command to get angle and burst velocity for this ID
            int command[2];
            PARSER.ParseCommand(message, command);

            int angle = command[0];
            int velocity = command[1];

            UTILS.Debug("\tCommand for Robot ID: " + String(CONFIG.ID));
            UTILS.Debug("\t\tAngle: " + String(angle));
            UTILS.Debug("\t\tVelocity: " + String(velocity));

            // execute drive command
            DRIVER.Drive(angle, velocity);
        }
    }

    delay(CONFIG.DelayInterval);
}