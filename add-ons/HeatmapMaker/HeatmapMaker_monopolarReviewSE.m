function mdl = HeatmapMaker_monopolarReviewSE(menu,eventdata,scene)



%ask for the model
vds = VoxelDataStack;
[vds,filename] = vds.loadStudyDataFromRecipe;

nPatients = vds.length;
nVTAs = vds.depth;
%Build a list with all (bilateral) therapies.
therapyList = Therapy.empty();
for iPatient = 1:nPatients
    thisTherapy = Therapy();
    thisTherapy.Tag = vds.LayerLabels{iPatient}{1};
    for iVTA = 1:nVTAs
            thisVTA  = VTA;
            thisVTA.Electrode = vds.Electrodes(iPatient,iVTA);
            thisVTA.Volume = vds.getVoxelDataAtPosition(iPatient,iVTA);
            
            %the electrode object might contain more info. This is
            %recaptured.
            try
            thisVTA.Source = thisVTA.Electrode.VTA.Source;
            thisVTA.Space = thisVTA.Electrode.VTA.Space;
            thisVTA.Tag = thisVTA.Electrode.VTA.Tag;
            thisVTA.SuretuneStimplan = thisVTA.Electrode.VTA.SuretuneStimplan;
            catch
                thisVTA.Space = thisVTA.Electrode.Space;
                %no suretune electrode apparently
            end

            thisTherapy.VTAs(end+1) = thisVTA;

            
            
           
    end
    thisTherapy.connectTo(scene)
    therapyList(iPatient) = thisTherapy;
end

data = createPopup(therapyList,filename);

for therapy = 1:vds.length
    

end

