function [outputArg1,outputArg2] = BrainlabExtractor_LeadsFromExcel(menu,eventdata,scene)
%BRAINLABEXTRACTOR_LEADSFROMEXCEL Summary of this function goes here
%   Detailed explanation goes here

[filename,foldername] = uigetfile('*.xlsx');
sheet = readtable(fullfile(foldername,filename));

columnNames = sheet.Properties.VariableNames;
iName = find(contains(columnNames,'Patientname'));
iSide = find(contains(columnNames,'Side'));
iL = find(contains(columnNames,'targetL'));
iP = find(contains(columnNames,'targetP'));
iS = find(contains(columnNames,'targetS'));
iDL = find(contains(columnNames,'degreesLeft'));
iDA = find(contains(columnNames,'degreesAnterior' ));

for i = 2:height(sheet)
    L = sheet{i,iL}(1);
    P = sheet{i,iP}(1);
    S = sheet{i,iS}(1);
    DL = sheet{i,iDL}(1);
    DA = sheet{i,iDA}(1);
    Name = sheet{i,iName}(1);
    Side = sheet{i,iSide}(1);
    
    
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

Entry = Target + direction;

e = Electrode;
e.C0 = Target;
e.PointOnLead(Entry)
actor  = e.see(scene);
actor.changeName([Name,'_',Side]);

actor.transform(scene,'lps2ras')





    
    
end



end

