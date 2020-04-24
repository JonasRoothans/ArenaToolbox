function [pValue, signedP] = A_PermTest2(sample1,sample2,p,discriminative_statistic,other)
%JR_2SAMPLEPERMUTATIONTEST Summary of this function goes here
%   Detailed explanation goes here


if nargin==2
    p = 500000;
end
if nargin==5
    switch other
        case 'silent'
            verbose = 0;
        otherwise
            verbose = 1;
    end
else
    verbose = 1;
end

if isempty(discriminative_statistic) || nargin==3
    discriminative_statistic = 'mean';
end


switch discriminative_statistic
    case 'mean'
        [h,ptest,ci,stats]=ttest2(sample2, sample1);
        test_statistic = abs(mean(sample1) - mean(sample2));
    otherwise
        error(['Discriminative method "',discriminative_statistic,'" does not exist.'])
end

end
if verbose
    disp (['p will approximate : ', num2str(ptest)])
end



mixed = [sample1(:);sample2(:)];
tslist = zeros(1,p);
if verbose
    tic
end
for iP = 1:p
    if iP==100
        
        if verbose
            t = toc;
            disp(['this will take approx. ',num2str(t/100*p),' seconds or ',num2str(t/100*p/60),' minutes'])
        end
    end
    shuffle = mixed(randperm(length(mixed)));
    
    switch discriminative_statistic
        case 'mean'
            tslist(iP) = abs(mean(shuffle(1:numel(sample1))) - mean(shuffle(numel(sample1)+1:end)));
    end
end

pValue = sum(tslist>test_statistic) / p;
signedP = (1-pValue) * sign(mean(sample1) - mean(sample2));
if verbose
    disp(['precision: ',num2str(1/p)])
    disp('if signedP is positive, then sample A is bigger than sample B')
    toc;
end
