function [table] = cleanTable(file,varargin)
% cleanTable - loads exel sheet in original dimensions, numbers which are
% loaded as text become numbers
%file - path to the excel file
% varagin-sheets you want

if numel(varargin)<1
    
    error('You have to specify your sheets')
    
end

%% load all sheets into one structure and clean them

for ii=1:numel(varargin)
    
    [~,~,table.sheets{ii}]=xlsread(file,varargin{ii});
    table.sheets{ii}=clean(table.sheets{ii});
    table.labels{ii}=varargin{ii};
    
end
    
    




%% clean the sheets from strings
    function Y=clean(X)
        
        [x,y]=size(X);
        for iColumns=1:y
            for iRows=1:x
                
                if ischar(X{iRows,iColumns})
                    a=textscan(X{iRows,iColumns},'%f');
                    if ~isempty(a{1,1})
                    
                        
                        X(iRows,iColumns)=textscan(X{iRows,iColumns},'%f');
                    end
                end
                
            end
        end
        
        Y=X;
        
    end
            
         
                    
                 
                    

end

