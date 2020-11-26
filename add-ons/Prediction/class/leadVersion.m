classdef leadVersion<handle
    %In this class all possible electrodes and therefor needed settings are
    %created for the Transformation of the VTA themself.
    
    properties
        config
    end
    
    methods
        function obj = leadConnected()
           %First linking of class to variable
        end
        
        function config=getConfiguration(thisSession)
        
        valueOfContactLetters=str2num(thisSession.therapyPlanStorage{1, 1}.activeRings);
        contacts=numel(valueOfContactLetters);
        contacts = 0:contacts;
        amplitudes = 1:5;
        [contacts2d,amplitudes2d] = meshgrid(contacts,amplitudes); %maybe a new way of getting the same values but without this meshgrid crazyness
        config.contacts_vector = reshape(contacts2d,1,[]);         %gets the 0123 in row to follow in column
        config.amplitudes_vector = reshape(amplitudes2d,1,[]);     %gets the 12345 in row to follow in column
        valueOfContactLetters(valueOfContactLetters~=0)=0;
        config.activevector=valueOfContactLetters;      
        
        end
    end
end

