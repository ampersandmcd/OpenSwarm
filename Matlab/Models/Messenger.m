classdef Messenger
    %MESSENGER: Object to encapsulate all messaging functionality
    
    properties
        Environment;    % Environment object dependency
        UDPTransmitter; % udp object to broadcast commands
        UDPReceiver;    % struct of udp objects to receive commands
    end
    
    methods
        function obj = Messenger(inputEnvironment)
            %MESSENGER: Construct and configure a messenger object
            
            obj.Environment = inputEnvironment;
            
            if obj.Environment.UDPTransmission
                obj = obj.StartUDPTransmitter();
            end
            
            if obj.Environment.UDPReception
                obj = obj.StartUDPReceiver();
            end
        end
        
        function obj = StartUDPTransmitter(obj)
            %StartUDPTransmitter: set up and open udp broadcaster            
            
            obj.UDPTransmitter = udp('10.10.10.255', 8080);
            fopen(obj.UDPTransmitter);
        end
        
        function obj = StartUDPReceiver(obj)
            %StartUDPReceiver: create and open udp receiver struct
            
            obj.UDPReceiver = {};
            
            for i = 1:obj.Environment.NumRobots
                % configure a udp receiver object with port 800<ID_NUM>
                receiver = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', (8000 + i), 'Timeout', 0.01);
                fopen(receiver);
                obj.UDPReceiver{i} = receiver;
            end
        end
    end
end

