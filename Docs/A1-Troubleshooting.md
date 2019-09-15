# OpenSwarm Documentation

## Troubleshooting

#### My Arduino isn't receiving commands from Matlab

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

#### Matlab isn't receiving response data from my Arduino

Ensure that `LDRMode` is set to `true` in `Configuration.h` to enable client -> server response messaging. Next, verify that the Arduino is in fact sending data over UDP by monitoring the network with a utility like Wireshark.

If response data is in fact being sent but is not received by the UDP object in Matlab, check the firewall settings of your machine to ensure UDP traffic is allowed through the ports being used for communication. If necessary, create a new rule allowing UDP traffic through the `TXPort` set in the Arduino's `Configuration.h` file; this is the port over which data is sent from the Arduino to the Matlab server.

<p style="text-align:left;">
    <a href=05-Demos.md>Previous: Demos</a>
    <span style="float:right;">
       <a href=A2-Contact.md>Next: Contact</a>
    </span>
</p>
