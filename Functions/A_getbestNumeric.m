function BestNumeric=A_getbestNumeric(varargin); 
% incomplete-non functional
if ispc
 
    CurrentMemory=memory;
    
    CurrentMemory=CurrentMemory.MemUsedMATLAB/1e6;
else 

CurrentMemory=memoryForMac(); %get current memory Status
end
     
sum=prod(varargin{:}); % get number of Array elements
     
numericValues={'double' 'single', 'int8'}

for i=1:numel(numericValues)
    
    type=numericValues{i};
    burden=[];
    condition=[];
    
    switch type
        
        case 'double'
            
            burden=(sum*8)/10e6;
            condition=1;
            
        case 'single'
            
            burden=(sum*4)/10e6;
            condition=2;
            
        case 'int8'
            
            burden=(sum*1)/10e6;
            condition=3;
            
    end
end
   
    if ((burden+CurrentMemory)/1000)>8 
        
        while condition<3
            
            condition=condition+1;
            
            if condition==2
                
                 burden=(sum*4)/10e6;
            else
                
                burden=(sum*1)/10e6;
            end
            
            warning(['using lower precision numeric Value:', numericValues{condition}])
        end
    end
    
    BestNumeric=numericValues{condition};
            
            
        
        
    
        
        
    
end
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function CurrentMemory=memoryForMac()
% This function will return the memory used by MATLAB on the MAC
%

%% First get the version of MATLAB

curVer = version('-release');

%% get the PID for MATLAB
sysStr = ['ps -o ppid,command |grep ',curVer,'.app'];
[status,verStr] = system(sysStr);

if (status ~= 0)
    error('MATLAB was not found: That is odd since you are in MATLAB');
end

%% Get where the string is located
% Format looks like: interested in PPID
%  PPID COMMAND
%  4151 /Applications/MATLAB_R2019b.app/bin/maci64/matlab_helper /dev/ttys000 yes
slash = findstr('/',verStr);
pidStr = verStr(1:slash(1)-1);

%% Now get the memory string
sysStr = ['top -pid ',pidStr,' -l 1 -stats MEM'];
[status,info] = system(sysStr);
if (status ~= 0)
    error('Invalid PID provided')
else
    % now parse out the memory
    memLoc = findstr(info,'MEM');
    MEM = info(memLoc+5:end-1);
    fprintf('Total memory used: %s\n',MEM);
    CurrentMemory=str2double(MEM); % add a loop to change to number format
end
% modified from Michael Burke, Mathworks- https://www.mathworks.com/matlabcentral/answers/78726-show-memory-options-in-matlab-working-on-mac-platform
end
