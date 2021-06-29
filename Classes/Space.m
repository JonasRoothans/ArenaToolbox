classdef Space
    %SPACE Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        MNI2009b
        PatientNative
        Unknown
        Legacy
    end
    
    methods (Static)
        function enum = dialog(prompt)
            [~,membernames] = enumeration('Space');
            idx = listdlg('ListString',membernames,...
                           'SelectionMode','single',...
                          'PromptString',prompt);
                      if isempty(idx)
                          enum = [];
                      else
            enum = Space.(membernames{idx});
                      end
        end
    end

end

