function [dirinfo] = A_getsubfolders(mainfolder)

%GETSUBFOLDERS Summary of this function goes here
%   Detailed explanation goes here
dirinfo = dir(mainfolder);

deletethese = zeros(1,numel(dirinfo));
for i = 1:numel(dirinfo)
    if contains(dirinfo(i).name,'.') %when something starts with a dot, ignore it!
        deletethese(i) = 1;
    end
    if not(dirinfo(i).isdir)
        deletethese(i) = 1;
    end
end

dirinfo(deletethese>0) = [];

end



