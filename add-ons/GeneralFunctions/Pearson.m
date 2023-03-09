function [rho,p] = Pearson(X,Y)
%get rid of NaNs to calculate Pearson
Z=[X,Y];
Z(any(isnan(Z),2),:)=[];
X=Z(:,1:size(X,2));
Y=Z(:,(size(X,2)+1):end);
[rho,p]=corr(X,Y,'type','Pearson');
end