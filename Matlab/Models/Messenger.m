classdef Messenger
    %MESSENGER: Object to encapsulate all messaging functionality
    
    properties
        UDPTransmitter; % udp object to broadcast commands
        UDPReceiver;    % struct of udp objects to receive commands
        Environment;    % Environment object dependency
    end
    
    methods
        function obj = Messenger(inputEnvironment)
            %MESSENGER: Construct a messenger object
            obj.Environment = inputEnvironment;
            obj.UDPTransmitter = udp('10.10.10.255', 8080);
        end
        
        function obj = StartUDPTransmitter(obj)
            %StartUDPTransmitter: open udp broadcaster
            fopen(obj.UDPTransmitter);
        end
        
        function obj = StartUDPReceiver(obj)
            %StartUDPReceiver: create and open udp receiver struct
            obj.UDPReceiver = {};
            for i = 1:obj.NumRobots
                % configure a udp receiver object with port 800<ID_NUM>
                receiver = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', (8000 + i), 'Timeout', 0.01);
                fopen(receiver);
                obj.UDPReceiver{i} = receiver;
            end
        end
    end
end

