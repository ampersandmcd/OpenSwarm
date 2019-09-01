/*
 * Andrew McDonald
 * Michigan State University D-CYPHER Lab
 * Utilities.h
 * 9.1.19
 * 
 * Provides helper functions to convert data and debug memory contents at runtime.
 */

#include "Configuration.h"
#include "WiFiEsp.h"

#ifndef util
#define util

class Utilities
{
private:
    Configuration &Config;

public:
    Utilities(Configuration &config) : Config(config){};

    // Purpose:     Convert IPAddress format to string for debugging purposes
    // Params:      (IPAddress IP) the IP address to be converted to string
    // Returns:     String of IP address
    String IPToString(IPAddress IP)
    {
        return String(IP[0]) + "." + String(IP[1]) + "." + String(IP[2]) + "." + String(IP[3]);
    }

    // Purpose:     Debug WiFi connection status
    // Params:      none
    // Returns:     void; prints directly to Serial in place of return string to conserve memory
    void DebugWifiStatus()
    {
        if (Config.Debug)
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
    }

    // Purpose:     Prints debug command if Config.Debug argument is set to True
    // Params:      (String message) the message to be debugged
    // Returns:     void; prints directly to Serial
    void Debug(String message)
    {
        if (Config.Debug)
        {
            Serial.println(message);
        }
    }
};

#endif