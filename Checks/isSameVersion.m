function answer = isSameVersion(Scene,showOrHide)
%ISSAMEVERSION compares Git reference of toolbox and data.
%   Detailed explanation goes here

answer = 1;
try 
    gitinfo_thisversion = getGitInfo;
    gitinfo_loadeddata = Scene.gitref;
    if not(strcmp(gitinfo_thisversion.hash,...
            gitinfo_loadeddata.hash))
            answer = 0;
        switch showOrHide
            case'show'
                msgbox('The loaded scene may not be compatible with the current version. Use newScene, Import scene, to upgrade data' ,'Arena version','warn')
            case 'hide'
                disp('The loaded scene may not be compatible with the current version. Use newScene, Import scene, to upgrade data')
        end
    end
catch
        answer = NaN;
        disp('No version control. Loaded version might not be compatible')
end


end

