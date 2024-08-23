function [outputArg1,outputArg2] = Noodles_checkifready(workflow,scene)
%NOODLES_CHECKIFREADY Summary of this function goes here
%   Detailed explanation goes here

load('NoodlesConfig')
switch lower(workflow)
    case 'basic'
        if all([not(isempty(NoodlesConfig.fibers)),...
                not(isempty(NoodlesConfig.Cohort1)),...
                not(isempty(NoodlesConfig.Cohort2))])
            set(NoodlesConfig.handles.run,'Enable','on')
            answer = questdlg('Your preparations are admirable','Huzzah!','Proceed with vigour','I beg your forgiveness, I must demure','Proceed with vigour');
            switch answer
                case 'Proceed with vigour'
                    Noodles_runbasic(nan,nan,scene)
            end
                    
        end
end
end
