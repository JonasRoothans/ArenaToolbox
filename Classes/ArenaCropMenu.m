classdef ArenaCropMenu < ArenaScene
    %ARENACROPMENU Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        boundingbox
        sliders
        flags
    end
    
    methods
        
        function obj = CustomizeSceneToBeACropMenu(obj)
              
             xpadding = 0.02;
            ypadding = 0.02;
%              obj.handles.boundingboxpanel = uipanel('units','normalized',...
%                 'position',[xpadding 0.4 0.4 0.3],...
%                 'Title','Bounding box');
            
            obj.handles.axes.Position = [0.38 0.3 0.6 0.7];
            
            obj.handles.histogramaxes = axes('units','normalized',...
                'position',[0.05 0.78 0.35 0.20],...
                'fontsize',8,...
                'nextplot','add',...
                'box','off');
            
            obj.handles.figure.Color = [0 0 0];
            
                        %sliders
            jRangeSliderx = com.jidesoft.swing.RangeSlider(0,100,0,100);  % min,max,low,high
            jRangeSliderx = javacomponent(jRangeSliderx, [40,490,400,80], obj.handles.figure );
            set(jRangeSliderx, 'MajorTickSpacing',25, 'MinorTickSpacing',5, 'PaintTicks',true, 'PaintLabels',true, ...
            'Background',java.awt.Color.black, 'StateChangedCallback',@myCallbackFunc);
        
        jRangeSlidery = com.jidesoft.swing.RangeSlider(0,100,0,100);  % min,max,low,high
            jRangeSlidery = javacomponent(jRangeSlidery, [40,410,400,80], obj.handles.figure );
            set(jRangeSlidery, 'MajorTickSpacing',25, 'MinorTickSpacing',5, 'PaintTicks',true, 'PaintLabels',true, ...
            'Background',java.awt.Color.black, 'StateChangedCallback',@myCallbackFunc);
        
        jRangeSliderz = com.jidesoft.swing.RangeSlider(0,100,0,100);  % min,max,low,high
            jRangeSliderz = javacomponent(jRangeSliderz, [40,330,400,80], obj.handles.figure );
            set(jRangeSliderz, 'MajorTickSpacing',25, 'MinorTickSpacing',5, 'PaintTicks',true, 'PaintLabels',true, ...
            'Background',java.awt.Color.black, 'StateChangedCallback',@myCallbackFunc);
          
            obj.sliders.x = jRangeSliderx;
            obj.sliders.y = jRangeSlidery;
            obj.sliders.z = jRangeSliderz;
            
            function myCallbackFunc(varargin)
                    ld = Vector3D([get(obj.sliders.x,'LowValue'),...
                        get(obj.sliders.y,'LowValue'),...
                        get(obj.sliders.z,'LowValue')]);
                    
                    ru = Vector3D([get(obj.sliders.x,'HighValue'),...
                        get(obj.sliders.y,'HighValue'),...
                        get(obj.sliders.z,'HighValue')]);
               
                   updateBoundingBox(obj,ld,ru)
            end
             
        end
        
        function obj = MakeACube(obj)
            %bounding box
                ld = Vector3D([-1 -1 -1]);
                ru = Vector3D([1 1 1]);
                axes(obj.handles.axes)
                obj.boundingbox = plot3([ld.x,ru.x,ru.x,ld.x,ld.x,ld.x,ru.x,ru.x,ld.x,ld.x,ru.x,ru.x,ru.x,ld.x,ld.x,ru.x,ru.x],...
          [ld.y,ld.y,ru.y,ru.y,ld.y,ld.y,ld.y,ru.y,ru.y,ld.y,ld.y,ld.y,ru.y,ru.y,ru.y,ru.y,ru.y],...
          [ld.z,ld.z,ld.z,ld.z,ld.z,ru.z,ru.z,ru.z,ru.z,ru.z,ru.z,ld.z,ld.z,ld.z,ru.z,ru.z,ld.z]);
        end
        
        function obj = ArenaCropMenu()
            obj.flags.loading = 0; %triggered by the load function
            obj.flags.startup = 1;
            
            obj = create(obj,'CROP MENU');
            obj = CustomizeSceneToBeACropMenu(obj);
            obj = MakeACube(obj);
            
            obj.flags.startup = 0;
             


        end
        
        
        function obj = load(obj, newActor)
            obj.flags.loading = 1;
            switch class(newActor.Data.Source)
                case 'CroppedVoxelData'
                    slice = newActor.Data.Source.parent.getslice.see(obj);

                    updateBoundingBox(obj,newActor.Data.Source.LeftDown,newActor.Data.Source.RightUp)
                    
                    parent_ld = Vector3D([newActor.Data.Source.parent.R.XWorldLimits(1),...
                        newActor.Data.Source.parent.R.YWorldLimits(1),...
                        newActor.Data.Source.parent.R.ZWorldLimits(1)]);
                    
                     parent_ru = Vector3D([newActor.Data.Source.parent.R.XWorldLimits(2),...
                        newActor.Data.Source.parent.R.YWorldLimits(2),...
                        newActor.Data.Source.parent.R.ZWorldLimits(2)]);
                    
                    
                    crop_ld = Vector3D(min([newActor.Data.Source.LeftDown.x,newActor.Data.Source.RightUp.x]),...
                        min([newActor.Data.Source.LeftDown.y,newActor.Data.Source.RightUp.y]),...
                        min([newActor.Data.Source.LeftDown.z,newActor.Data.Source.RightUp.z]));
                        
                    crop_ru = Vector3D(max([newActor.Data.Source.LeftDown.x,newActor.Data.Source.RightUp.x]),...
                        max([newActor.Data.Source.LeftDown.y,newActor.Data.Source.RightUp.y]),...
                        max([newActor.Data.Source.LeftDown.z,newActor.Data.Source.RightUp.z]));
                    
                otherwise
                    keyboard
            end
            
            %setsliders
            set(obj.sliders.x,'Minimum',parent_ld.x);
            set(obj.sliders.y,'Minimum',parent_ld.y);
            set(obj.sliders.z,'Minimum',parent_ld.z);
            set(obj.sliders.x,'Maximum',parent_ru.x);
            set(obj.sliders.y,'Maximum',parent_ru.y);
            set(obj.sliders.z,'Maximum',parent_ru.z);
            
            set(obj.sliders.x,'LowValue',crop_ld.x);
            set(obj.sliders.y,'LowValue',crop_ld.y);
            set(obj.sliders.z,'LowValue',crop_ld.z);
            set(obj.sliders.x,'HighValue',crop_ru.x);
            set(obj.sliders.y,'HighValue',crop_ru.y);
            set(obj.sliders.z,'HighValue',crop_ru.z);
            
            
            
            newActor.Data.Source.getmesh(newActor.Data.Settings.T).see(obj);
            
            axes(obj.handles.histogramaxes)
            obj.handles.histogram = histogram(newActor.Data.Source.Voxels(:),50);
            obj.handles.histogram.HitTest = 'off';
            obj.handles.histogram.FaceColor = obj.Actors(2).Visualisation.settings.colorFace;
            obj.handles.histogramaxes.XColor = 'w';
            obj.handles.histogramaxes.YColor = 'w';
            obj.handles.histogramaxes.Color = 'none';
            set(obj.handles.histogramaxes,'ButtondownFcn',@chooseThreshold);
            set(gca, 'YScale', 'log')
            xlabel('voxel value')
            ylabel('occurrence')
                    hold on
                obj.handles.histogramline = line([newActor.Data.Settings.T newActor.Data.Settings.T],obj.handles.histogramaxes.YLim);
                obj.handles.histogramline.LineWidth = 3;
                obj.handles.histogramline.Color = [1 1 1];
                
                
            %disableDefaultInteractivity(obj.handles.histogramaxes)
            axes(obj.handles.axes)
            
            obj.flags.loading =0 ;
            
            function chooseThreshold(varargin)
                hit = varargin{2};
                location = hit.IntersectionPoint(1);
                varargin{2}.Source.Parent.UserData.Actors(2).Visualisation.settings.threshold = location;
                
                currentsettings = varargin{2}.Source.Parent.UserData.Actors(2).Visualisation.settings;
                delete(varargin{2}.Source.Parent.UserData.Actors(2).Visualisation.handle)
                visualize(varargin{2}.Source.Parent.UserData.Actors(2),currentsettings,varargin{2}.Source.Parent.UserData.Actors(2).Data,varargin{2}.Source.Parent.UserData);
                
                axes(obj.handles.histogramaxes)
                obj.handles.histogramline.XData = [location location];
                axes(obj.handles.axes)
              
            end
                
            
        end
       
        
        
        function updateBoundingBox(obj,ld,ru)
     
            if not(obj.flags.startup)
            
                obj.boundingbox.XData = [ld.x,ru.x,ru.x,ld.x,ld.x,ld.x,ru.x,ru.x,ld.x,ld.x,ru.x,ru.x,ru.x,ld.x,ld.x,ru.x,ru.x];
               obj.boundingbox.YData = [ld.y,ld.y,ru.y,ru.y,ld.y,ld.y,ld.y,ru.y,ru.y,ld.y,ld.y,ld.y,ru.y,ru.y,ru.y,ru.y,ru.y];
               obj.boundingbox.ZData = [ld.z,ld.z,ld.z,ld.z,ld.z,ru.z,ru.z,ru.z,ru.z,ru.z,ru.z,ld.z,ld.z,ld.z,ru.z,ru.z,ld.z];
        
                cropped = obj.Actors(1).Data.parent.crop(ld,ru);
                cropped.smooth;
               

                %update histogram
                [~,BinEdges] = histcounts(cropped.Voxels(:),50);
                BinLimits = [min(BinEdges),max(BinEdges)];
                obj.handles.histogram.Data= cropped.Voxels(:);
                obj.handles.histogram.BinEdges= BinEdges;
                obj.handles.histogram.BinLimits= BinLimits;
                
                if not(obj.flags.loading)
                if not(any([getValueIsAdjusting(obj.sliders.x),...
                        getValueIsAdjusting(obj.sliders.y),...
                        getValueIsAdjusting(obj.sliders.z)]))
                %update mesh
                obj.Actors(2).Data.Source = cropped;
                delete(obj.Actors(2).Visualisation.handle)
                
                currentsettings = obj.Actors(2).Visualisation.settings;
                visualize(obj.Actors(2),currentsettings,obj.Actors(2).Data,obj);
                end
                end
        
            end
        
       
        end
        
        
            
    end
end

