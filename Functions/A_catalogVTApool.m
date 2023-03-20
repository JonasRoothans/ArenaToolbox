AClist = [1 0 0 0;0 1 0 0;0 0 1 0;0 0 0 1];
Amplist = 0.0:0.1:8;
PWlist = [60,90,120];
Vlist = {'True','False'};
Ltypes = {'Medtronic3389','Medtronic3387','stJudeMedical'}




%defaults
thisLeadType = 'Medtronic3389';
thisAmplitude = 2;

activecontact = [1 0 0 0];
groundedcontact = [0 0 0 0];


for i0 = 1:3
    outcome = [];
    thisLeadType = Ltypes{i0};
for i1 = 1:4
    activecontact = AClist(i1,:);
    
    for i2 = 1:numel(Amplist)
        thisAmplitude = Amplist(i2);
        
        for i3 = 1:numel(PWlist)
            thisPulseWidth = PWlist(i3);
            
            for i4 = 1:numel(Vlist)
                thisVoltageControlled = Vlist{i4};
                
                e = Electrode;
                
                VTAname = VTA.constructVTAname(...
                    thisLeadType,...
                    thisAmplitude,...
                    thisPulseWidth,...
                    activecontact,...
                    groundedcontact,...
                    thisVoltageControlled);
                try
                    vta1 = e.makeVTA(VTAname);
                    present = 1;
                catch
                    present = 0;
                end
                
                outcome(i1,i2,i3,i4) = present;
            end
        end
    end
end


%%
f = figure;
P1 = 3;
P2 = 2;

c = 0;
for p1 = 1:P1
    for p2 = 1:P2
        c = c+1;
        subplot(P1,P2,c) 
        imagesc(outcome(:,:,p1,p2))
        xtnew = 1:10:numel(Amplist);
        xtlbl = 0:1:8;
        set(gca, 'XTick',xtnew, 'XTickLabel',xtlbl)   
        title([num2str(PWlist(p1)),'us - Voltage: ',Vlist{p2}])
    end
end

f.Name = thisLeadType;
end