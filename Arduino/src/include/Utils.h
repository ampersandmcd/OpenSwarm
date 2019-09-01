#include "WiFiEsp.h"

String IPToString(IPAddress IP)
{
  return String(IP[0]) + "."
  + String(IP[1]) + "."
  + String(IP[2]) + "."
  + String(IP[3]);
}

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