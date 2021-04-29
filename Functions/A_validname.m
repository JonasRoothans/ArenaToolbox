function [output,bool] = A_validname(StringOrCellArray)

if isa(StringOrCellArray,'char')
    input = {StringOrCellArray};
else
    input = StringOrCellArray;
end

output = {};
bool = [];
for i = 1:numel(input)
    thisName = input{i};
    
    bool(i) = isvarname(thisName);
    if not(bool(i))
        
        %check for length
        if length(thisName) > 62
            thisName = thisName(1:62);
        end
        
        %first one is a number
        if not(isnan(str2double(thisName(1)))) 
            thisName = ['x_',thisName];
        end
        
        thisName = strrep(thisName,' ','_');
        %
        
    end
    output{i} = thisName;    
end

if length(output) ==1
    output = output{1};
end



end

