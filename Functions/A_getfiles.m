function [dirinfo] = A_getfiles(mainfolder)

%A_GETSUBFOLDERS Same as "dir", but without hidden . and ..
%   Detailed explanation goes here
dirinfo = dir(mainfolder);

deletethese = zeros(1,numel(dirinfo));
for i = 1:numel(dirinfo)
    if strcmp(dirinfo(i).name(1),'.') %when something starts with a dot, ignore it!
        deletethese(i) = 1;
    end
    if dirinfo(i).isdir
        deletethese(i) = 1;
    end
end

dirinfo(deletethese>0) = [];

end



