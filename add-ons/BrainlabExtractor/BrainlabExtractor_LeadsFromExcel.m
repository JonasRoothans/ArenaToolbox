function [outputArg1,outputArg2] = BrainlabExtractor_LeadsFromExcel(inputArg1,inputArg2)
%BRAINLABEXTRACTOR_LEADSFROMEXCEL Summary of this function goes here
%   Detailed explanation goes here

[filename,foldername] = uigetfile('*.xlsx');
sheet = readtable(fullfile(foldername,filename));

columnNames = sheet{1,:};
iName = find(contains(columnNames,'Patienntname'));
iL = find(contains(columnNames,'target L'));
iP = find(contains(columnNames,'target P'));
iS = find(contains(columnNames,'target S'));
iDL = find(contains(columnNames,'degrees left'));
iDA = find(contains(columnNames,'degrees anterior' ));

for i = 2:height(sheet)
    L = str2num(sheet{i,iL}{1});
    P = str2num(sheet{i,iP}{1});
    S = str2num(sheet{i,iS}{1});
    DL = str2num(sheet{i,iDL}{1});
    DA = str2num(sheet{i,iDA}{1});
    
    
Target = [L,P,S];

aL = -deg2rad(DL); % around Y towards left
aA = -deg2rad(DA); % around X towards Anterior

upVector = [0 0 1];

tL = [cos(aL) 0 sin(aL);...
       0    1   0;...
     -sin(aL) 0 cos(aL)];

tA = [1  0   0;...
     0 cos(aA) -sin(aA);...
     0 sin(aA) cos(aA)];
% 
% tL = [1  0   0;...
%     0 cos(aL) -sin(aL);...
%     0 sin(aL) cos(aL)]
    
T = tA*tL;
direction = round(upVector*T,4);

Entry = Target + direction*length;

e = Electrode;
e.C0 = Target;
e.PointOnLead(Entry)

out = [Target;Entry];

    
    
end




keyboard


end

