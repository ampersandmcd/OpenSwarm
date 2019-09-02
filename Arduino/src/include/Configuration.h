/*
 * Andrew McDonald
 * Michigan State University D-CYPHER Lab
 * Configuration.h
 * 9.1.19
 * 
 * Provides configuration settings for the client robot.
 */

#ifndef cfg
#define cfg

class Configuration
{
public:
    // identifier configuration
    int ID = 1; // unique identifier for this robot

    // network configuration
    char SSID[11] = "belkin.785";                // network SSID
    char Password[9] = "cyb2e9ce";               // network password
    int RXPort = 8080;                           // network port to listen for UDP broadcast commands
    IPAddress TXIP = IPAddress(10, 10, 10, 255); // broadcast ip to send UDP info over
    int TXPort = 8000 + ID;                      // network port to send data back to Matlab server; systematically encodes ID in port
    unsigned long SerialBaud = 115200;           // baudrate for Serial monitor connection (must differ from ESPBaud)
    int ESPBaud = 9600;                          // baudrate for ESP connection (must differ from SerialBaud)

    // preferences
    bool Debug = true;         // output debugging statements?
    bool LDRMode = true;       // send light dependent resistor data back to Matlab server?
    int DelayInterval = 50;    // interval between main while loop iterations in ms
    int DelayAcceleration = 3; // interval between acceleration and deceleration loop iterations in Driver.h in ms

    // pin configuration
    int LDRPin = 5;    // light-dependent resistor analog connection
    int MotorPWMA = 5; // motor connection
    int MotorAIN1 = 7;
    int MotorAIN2 = 6;
    int MotorSTBY = 8;
    int MotorPWMB = 11;
    int MotorBIN1 = 9;
    int MotorBIN2 = 10;
    int SoftwareSerialRX = 2; // RX pin to connect with ESP via SoftwareSerial
    int SoftwareSerialTX = 3; // TX pin to connect with ESP via SoftwareSerial
};

#endif