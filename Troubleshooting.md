# Troubleshooting Common Errors

## My Arduino isn't receiving commands from Matlab.

First, verify that commands are in fact being sent over UDP by Matlab with a utility like Wireshark. If your host running Matlab is connected to multiple networks, it may be sending the UDP commands over the wrong network, in which case the client Arduinos will not receive the command. 

Next, verify that your Arduino is connecting to the network by setting the `Debug` setting in the `Configuration` object of `src/Pathfinder.ino` to `true`, and open the Serial Monitor. Verify that your Arduino successfully connects to your local network by reading the Serial output; after `Attempting to connect to WPA SSID: <your SSID>`, you should see

```
Connected to WiFi.
WiFi Status:
	SSID: <your SSID>
	IP Address: <IP>
	Signal strength (RSSI): <RSSI>
```

If you do not see this message, your Arduino is not connected to the network. Verify that your ESP module is initialized properly, and that you've entered your network SSID and Password correctly.