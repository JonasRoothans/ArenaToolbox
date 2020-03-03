function [pValue, signedP] = A_PermTest2(sample1,sample2,p)
%JR_2SAMPLEPERMUTATIONTEST Summary of this function goes here
%   Detailed explanation goes here


if nargin==2
    p = 500000;
end
test_statistic = abs(mean(sample1) - mean(sample2));

mixed = [sample1(:);sample2(:)];
tslist = zeros(1,p);
tic
for iP = 1:p
    if iP==100
        t = toc;
        disp(['this will take approx. ',num2str(t/100*p),' seconds or ',num2str(t/100*p/60),' minutes'])
    end
    shuffle = mixed(randperm(length(mixed)));
    tslist(iP) = abs(mean(shuffle(1:numel(sample1))) - mean(shuffle(numel(sample1)+1:end)));
end

pValue = sum(tslist>test_statistic) / p;
signedP = (1-pValue) * sign(mean(sample1) - mean(sample2));
disp(['precision: ',num2str(1/p)])
disp('if signedP is positive, then sample A is bigger than sample B')
toc