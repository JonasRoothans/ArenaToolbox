classdef SuretuneTransformationTools
    %SURETUNETRANSFORMATIONTOOLS Summary of this class goes here
    %   Detailed explanation goes here

    methods (Static)
        function  [T,description]= universalCallbackRoutine(this,OPTIONAL_anatomy)
            [names,regs] = SuretuneTransformationTools.getRegistrationlink(this);
            if nargin == 1
                 [selection] = listdlg('PromptString','In which space do you want it?','ListString',names);
            else
                selection = SuretuneTransformationTools.findItAutomatically(this,names,OPTIONAL_anatomy);
            end
        
        %possibly abort?
        if isempty(selection);return;end
        if selection==1;return;end
        
        %first Transformation (registerable to reglink)
        reglink = regs{selection};
        Ttoreglink = this.session.gettransformfromto(this,reglink);
        
        %Second Transformation (reglink to arena)
        Tfromreglink = SuretuneTransformationTools.getSecondTransformation(reglink);
        
        T = round(Ttoreglink*Tfromreglink,6);
        description = names{selection};
         
        end
        
        function  Tfromreglink = getSecondTransformation(reglink)
            switch class(reglink)
            case 'Atlas'
                T = load('T2022.mat');
                atlasname = ['stu2mni_',lower(reglink.hemisphere),upper(reglink.group)];
                %Tatlas2fake = T.(atlasname);
                %Tfake2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
                Tfromreglink = T.(atlasname);
            case 'ACPCIH'
                Tlps2ras = diag([-1 -1 1 1]);
                MCP2AC = Vector3D(reglink.ac-reglink.pc).norm*-0.5;
                Tmcp2ac = [1 0 0 0;0 1 0 0;0 0 1 0;0 MCP2AC 0 1];
                Tfromreglink = Tlps2ras*Tmcp2ac;
            case 'Dataset'
                Tfromreglink= diag([-1 -1 1 1]); %lps2ras
            case 'ImageBasedStructureSegmentation'
                 Tfromreglink= diag([-1 -1 1 1]); %lps2ras
             case 'ManualStructureSegmentation'
                 Tfromreglink= diag([-1 -1 1 1]); %lps2ras
                 
            otherwise
                keyboard
            end
        end
            
         function [names,regs] = getRegistrationlink(suretuneRegisterable)
        session = suretuneRegisterable.session;
        [~,types] = session.listregisterables;
        atlas_indices = find(contains(types,'Atlas'));
        names = {};
        regs = {};
        
        for i = 1:numel(atlas_indices)
            thisAtlas = session.getregisterable(atlas_indices(i));
            names{i} = ['to MNI via ',thisAtlas.group,' ',thisAtlas.hemisphere];
            regs{i} = thisAtlas;
        end
        names = [{'--','Native / Scanner','Suretune patient space','ACPC'},names];
        regs = [{nan,suretuneRegisterable,session.getregisterable(1),session.getregisterable('acpcCoordinateSystem')},regs];
         end
         
              
    
         function selection = findItAutomatically(this,names,anatomy)
             anatomyFilter = contains(names,anatomy,'IgnoreCase',true);
             
             T_thisToACPC = this.session.gettransformfromto(this,'acpcCoordinateSystem');
             tipACPC = SDK_transform3d([0 0 0],T_thisToACPC);
             
             if tipACPC(1)<0
                 side = 'Right';
             else
                 side = 'Left';
             end
             
             sideFilter = contains(names,side,'IgnoreCase',true);
             selection = find(and(anatomyFilter,sideFilter));
             
             if numel(selection)>1
                 warn('Unclear which registration method should be used')
                 keyboard
             end
            
             
         end
    end
    
end
