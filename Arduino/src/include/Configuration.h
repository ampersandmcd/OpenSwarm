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
  int DelayInterval = 50;

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