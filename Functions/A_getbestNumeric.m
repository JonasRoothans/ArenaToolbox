function BestNumeric=A_getbestNumeric(varargin); 
% incomplete-non functional
if ispc
 
    [CurrentMemory, Totalmemory]=memory;
    
    CurrentMemory=CurrentMemory.MemUsedMATLAB/1e6;
    Totalmemory=Totalmemory.PhysicalMemory/1e6;
else 
try
[CurrentMemory, memorybySystem,  Totalmemory]=memoryForMac();%get current memory Status
catch
    warning('you are using Linux no memory optimisation possible, choosing double format')
    BestNumeric='double';
    return
end
end
     
sum=prod(varargin{:}); % get number of Array elements
     
numericValues={'double' 'single', 'int8'}

for i=1:numel(numericValues)
    
    type=numericValues{i};
    burden=[];
    condition=[];
    
    switch type
        
        case 'double'
            
            burden=(sum*8)/1e6;
            condition=1;
            
        case 'single'
            
            burden=(sum*4)/1e6;
            condition=2;
            
        case 'int8'
            
            burden=(sum*1)/1e6;
            condition=3;
            
    end

   
    if (burden+CurrentMemory)>Totalmemory 
        
        if condition<3
            
            continue
        else
            error ('It looks like, memory requirement for array is larger than available on computer,try using on a computer with bigger RAM or close some of the running programs'); 
            
        end
        
    else
        if condition~=1
        warning(['using lower precision numeric Value:', numericValues{condition}])
        warning(['using lower precision numeric Value:', numericValues{condition},' may not be suitable for obligate continous data e.g functional MRI data '])
        end
        break
    end
            

end

    BestNumeric=numericValues{condition};
            
     
end
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function [memoryByMatlab, MemoryBysystem, totalMemory, unusedmem]=memoryForMac()
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
    memoryByMatlab=MEM(isstrprop(MEM,'digit')); % change to number format
    memoryByMatlab=str2double(memoryByMatlab);
    
    PhysmemLoc = findstr(info,'PhysMem');
    Physmem=info(PhysmemLoc+5:end-1);
    fprintf('Total memory used: %s\n',Physmem);
    %     totalMemory=Physmem(isstrprop(Physmem,'digit'));
    memoryinfo=isstrprop(Physmem,'digit');
    MemoryBysystem=Physmem(find(memoryinfo,4));
    MemoryBysystem=str2double(MemoryBysystem(isstrprop(MemoryBysystem,'digit')));
    unusedmem_position=strfind(Physmem,'M');
    unusedmem_position=unusedmem_position(3);
    unusedindex=(unusedmem_position-5):unusedmem_position;
    
    unusedmem=Physmem(unusedindex);
    unusedmem=str2double(unusedmem(isstrprop(unusedmem,'digit')));
    totalMemory=unusedmem+MemoryBysystem;
end
% modified from Michael Burke, Mathworks- https://www.mathworks.com/matlabcentral/answers/78726-show-memory-options-in-matlab-working-on-mac-platform
end
