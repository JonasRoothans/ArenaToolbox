n=predictFuture
n.newPrediction

%%
%for DataPath
[filename,pathname]=uigetfile('*.dcm');
Data_In=fullfile(pathname,filename);
%% make it visible again
n.handles.figure.Visible='on';
