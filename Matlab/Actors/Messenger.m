classdef Messenger < handle
    %Messenger: 
    %   Object to encapsulate all messaging functionality between server
    %   (Matlab) and client (Arduino robots)
    
    properties
        % object dependencies
        Environment;            % Environment object dependency
        Plotter;                % Plotter object dependency
        
        % static configurations
        UDPTransmitterIP;       % IP over which to broadcast UDP commands
        UDPTransmitterPort;     % Port over which to broadcast UDP commands
                
        UDPReceiverIP;          % IP over which to receive UDP commands
        UDPReceiverRemotePort;  % Remote Port over which to receive UDP commands
        UDPReceiverLocalPort;   % Starting Local Port over which to receive
                                % commands; note that all ports in range
                                % [port, port + NumRobots]
                                % will be used to receive data
        
        % dynamic attributes
        UDPTransmitter; % udp object to broadcast commands
        UDPReceiver;    % struct of udp objects to receive commands
        
        Received        % boolean indicating if ALL robots received a message last iteration
        LastMessage;    % nRobots x 1 array of last message received from robots
    end
    
    methods
        function obj = Messenger(inputEnvironment, inputPlotter)
            %Messenger: 
            %   Construct and configure a messenger object
            
            % set dependencies
            obj.Environment = inputEnvironment;
            obj.Plotter = inputPlotter;
            
            % set configurations
            obj.UDPTransmitterIP = '10.10.10.255';
            obj.UDPTransmitterPort = 8080;
            
            obj.UDPReceiverIP = '10.10.10.255';
            obj.UDPReceiverRemotePort = 8080;
            obj.UDPReceiverLocalPort = 8000;
            
            obj.LastMessage = zeros(inputEnvironment.NumRobots, 1);
            obj.Received = false;
            
            if obj.Environment.UDPTransmission
                obj = obj.StartUDPTransmitter();
            end
            
            if obj.Environment.UDPReception
                obj = obj.StartUDPReceiver();
            end
        end
        
        function obj = StartUDPTransmitter(obj)
            %StartUDPTransmitter: 
            %   Set up and open UDP transmitter            
            
            obj.UDPTransmitter = udp(obj.UDPTransmitterIP, obj.UDPTransmitterPort);
            fopen(obj.UDPTransmitter);
        end
        
        function obj = StartUDPReceiver(obj)
            %StartUDPReceiver: 
            %   Create and open UDP listener struct
            
            obj.UDPReceiver = {};
            
            for i = 1:obj.Environment.NumRobots
                % configure a udp receiver object with port 800<ID_NUM>
                receiver = udp(obj.UDPReceiverIP, 'RemotePort', obj.UDPReceiverRemotePort, 'LocalPort', (obj.UDPReceiverLocalPort + i), 'Timeout', 0.01);
                fopen(receiver);
                obj.UDPReceiver{i} = receiver;
            end
        end
        
        function obj = SendDirections(obj, directions)
            %SendDirections:
            %   Given directions map<str(ID), Burst>, calls
            %   BuildDirectionsMessage and sends result with SendMessage
            message = obj.BuildDirectionsMessage(directions);
            obj.SendMessage(message);
        end
              
        function obj = SendMessage(obj, message)
            %SendMessage:
            %   Broadcast the string parameter 'message' over UDP
            fwrite(obj.UDPTransmitter, message);
        end
        
        function obj = ReadMessage(obj)
           %ReadMessage:
           %    Read all incoming messages in the UDPReciever cell array.
           %    Update LastMessage member array to contain last message
           %    from each robot.
           %    Set Received true if all messages in LastMessage were
           %    updated; else, set false.
           
           % Assume we have received all messages; set false if not
           obj.Received = true;
           
           % Iterate over all robots in field
           for i = 1:obj.Environment.NumRobots

               udpr = obj.UDPReceiver{i};
               length = udpr.BytesAvailable;

               if length > 0
                   % Message reception successful
                   message = fscanf(udpr);
                   number = str2double(message);
                   obj.LastMessage(i,1) = number;
               else
                    % Message reception unsuccessful
                    obj.Received = false;
                    warning("Robot %d did not send feedback", i);
               end

           end
           
        end
        
        function message = BuildDirectionsMessage(obj, directions)
            %BuildDirectionsMessage:
            %   Given directions map<str(ID), Burst>, constructs string to 
            %   send to each robot with directions towards next target 
            %   encoded as bursts (turn + speed)
            
            message = '<start>';
            for i = 1:obj.Environment.NumRobots
                % get burst for robot i from Directions map
                try
                    burst = directions(num2str(i));
                catch
                    burst.Angle = 0;
                    burst.Speed = 0;
                end
                % create submessage for robot i of the form
                % <IDnum>angle,speed</IDnum>%
                % where angle & speed are rounded to int
                submessage = sprintf('<%d>%0.0f,%0.0f</%d>', i, burst.Angle, burst.Speed, i);
                
                % concatenate submessage for robot i onto whole message
                message = strcat(message, submessage);
            end
            
            % concatenate ending tag onto message
            message = strcat(message, '<end>');
        end
    end
end

