fclose(instrfindall)

udpr = {};
udpr{1} = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', 8001, 'Timeout', 0.01);
udpr{2} = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', 8002, 'Timeout', 0.01);
udpr{3} = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', 8003, 'Timeout', 0.01);
udpr{4} = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', 8004, 'Timeout', 0.01);
udpr{5} = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', 8005, 'Timeout', 0.01);

% setup - only need to open address once
for i = 1:size(udpr,2)
    fopen(udpr{i});
end

% read loop
recent = {"", "", "", "", ""};
while true
    for i = 1:size(udpr, 2)
        if udpr{i}.BytesAvailable > 0
            level = fgetl(udpr{i});
            disp(sprintf("Robot %d light level : %s", i, level));
            recent{i} = level; 
            flushinput(udpr{i});            
        else
            disp(sprintf("Robot %d light level : %s", i, recent{i}));
        end
    end
    disp(newline);
    
    % convert to numeric from cell array
    S = sprintf('%s ', recent{:});
    values = sscanf(S, '%f');
    % do things with numbers here
    
    
    pause(1);
end

for i = 1:size(udpr,2)
    fclose(udpr{i});
end
