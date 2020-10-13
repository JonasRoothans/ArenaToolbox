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
        
        %currently only checks for length
        if length(thisName) > 62
            thisName = thisName(1:62);
        end
        
    end
    output{i} = thisName;    
end

if length(output) ==1
    output = output{1};
end



end

