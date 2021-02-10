function [outputArg1,outputArg2] = A_writeObjFile(actor,directoryname)
%A_WRITEOBJFILE Summary of this function goes here
%   Detailed explanation goes here
cd(directoryname)
[~, objectname,~] = fileparts(actor.Tag);
materialname = actor.Scene.Title;

%Make obj file
fname = [objectname,'.obj'];
fid = fopen(fname,'w+');
fprintf(fid,'# Arena - VisualDBSlab\n');
fprintf(fid,'# www.VisualDBSlab.com\n\n');

fprintf(fid,['mtllib ',materialname,'.mtl\n']);

%Make materials file

fname = [materialname,'.mtl'];
if ~exist(fname,'file')
    fidmtl = fopen(fname,'a+');
    fprintf(fidmtl,'# Arena - VisualDBSlab\n');
    fprintf(fidmtl,'# www.VisualDBSlab.com\n\n');
    
     fprintf(fidmtl,'newmtl leadbody\n');
        fprintf(fidmtl,'Ns 449.954088\n');
        
        fprintf(fidmtl,'Ka 1.000000 1.000000 1.000000\n');
        fprintf(fidmtl,'Kd 0.767762 0.767762 0.767762\n');
        fprintf(fidmtl,'Ks 0.979798 0.979798 0.979798\n');
        fprintf(fidmtl,'Ke 0.000000 0.000000 0.000000\n');
        fprintf(fidmtl,'Ni 1.450000\n');
        fprintf(fidmtl,'d 1.000000\n');
        fprintf(fidmtl,'illum 2\n');
        
             fprintf(fidmtl,'newmtl leadcontact\n');
        fprintf(fidmtl,'Ns 900\n');
        
        fprintf(fidmtl,'Ka 1.000000 1.000000 1.000000\n');
        fprintf(fidmtl,'Kd 0.800000 0.285131 0.053827\n');
        fprintf(fidmtl,'Ks 0.50000 0.50000 0.50000\n');
        fprintf(fidmtl,'Ke 0.000000 0.000000 0.000000\n');
        fprintf(fidmtl,'Ni 1.450000\n');
        fprintf(fidmtl,'d 1.000000\n');
        fprintf(fidmtl,'illum 3\n');
        
             fprintf(fidmtl,'newmtl leadcontact.cathode\n');
        fprintf(fidmtl,'Ns 225\n');
        
        fprintf(fidmtl,'Ka 1.000000 1.000000 1.000000\n');
        fprintf(fidmtl,'Kd 0 0.078 0.80\n');
        fprintf(fidmtl,'Ks 0.50000 0.50000 0.50000\n');
        fprintf(fidmtl,'Ke 0.000000 0.000000 0.000000\n');
        fprintf(fidmtl,'Ni 1.450000\n');
        fprintf(fidmtl,'d 1.000000\n');
        fprintf(fidmtl,'illum 2\n');
        
else
    fidmtl = fopen(fname,'a+');
end







switch class(actor.Data)
    case 'Electrode'
        Vcounter = 0;
        objectnames = {'body','c0','c1','c2','c3'};
        materialnames = {'leadbody','leadcontact','leadcontact','leadcontact','leadcontact'};
        for iPatch = 1:numel(actor.Visualisation.handle)
            
            Vertices = actor.Visualisation.handle(iPatch).Vertices;
            Faces = actor.Visualisation.handle(iPatch).Faces+Vcounter;
            
            fprintf(fid,['o ',objectnames{iPatch},'\n']);
            for i=1:size(Vertices,1)
                fprintf(fid,'v %f %f %f\n',Vertices(i,1),Vertices(i,2),Vertices(i,3));
            end
            fprintf(fid,['usemtl ',materialnames{iPatch},'\n']);
            fprintf(fid,'s on\n');
            for i=1:size(Faces,1)
                fprintf(fid,'f %d %d %d\n',Faces(i,1),Faces(i,2),Faces(i,3));
            end
            Vcounter = Vcounter+size(Vertices,1);
        end
        
    case 'Slicei'
        leftcorner = [actor.Visualisation.handle.XData(1,1),actor.Visualisation.handle.YData(1,1), actor.Visualisation.handle.ZData(1,1)];
        inbetween1 = [actor.Visualisation.handle.XData(1,end),actor.Visualisation.handle.YData(1,end), actor.Visualisation.handle.ZData(1,end)];
        inbetween2 = [actor.Visualisation.handle.XData(end,1),actor.Visualisation.handle.YData(end,1), actor.Visualisation.handle.ZData(end,1)];
        rightcorner = [actor.Visualisation.handle.XData(end,end),actor.Visualisation.handle.YData(end,end), actor.Visualisation.handle.ZData(end,end)];
        [~,~] = mkdir('textures');
        imwrite(actor.Visualisation.handle.CData,fullfile('textures',[objectname,'.jpg']))
        Vertices = [leftcorner;inbetween1;inbetween2;rightcorner];
        Faces = [1 2 3; 2 4 3];
        VerticesTexture = [0 0; 1 0; 0 1; 1 1];
        
        materialname = [objectname,'.001'];
        
        fprintf(fid,['o ',objectname,'\n']);
        for i=1:size(Vertices,1)
            fprintf(fid,'v %f %f %f\n',Vertices(i,1),Vertices(i,2),Vertices(i,3));
        end
        for i=1:size(VerticesTexture,1)
            fprintf(fid,'vt %f %f\n',VerticesTexture(i,1),VerticesTexture(i,2));
        end
        fprintf(fid,['usemtl ',materialname,'\n']);
        fprintf(fid,'s off\n');
        for i=1:size(Faces,1)
            fprintf(fid,'f %d/%d %d/%d %d/%d\n',Faces(i,1),Faces(i,1),Faces(i,2),Faces(i,2),Faces(i,3),Faces(i,3));
        end
        
        %update materials file
        fprintf(fidmtl,['newmtl ',materialname,'\n']);
        fprintf(fidmtl,'Ns 96.078431\n');
        
        fprintf(fidmtl,'Ka 1.000000 1.000000 1.000000\n');
        fprintf(fidmtl,'Kd 0.640000 0.640000 0.640000\n');
        fprintf(fidmtl,'Ks 0.550000 0.550000 0.550000\n');
        fprintf(fidmtl,'Ke 0.000000 0.000000 0.000000\n');
        fprintf(fidmtl,'Ni 1.000000\n');
        fprintf(fidmtl,'d 1.000000\n');
        fprintf(fidmtl,'illum 2\n');
        fprintf(fidmtl,['map_Kd textures\\',objectname,'.jpg\n']);
        fprintf(fidmtl,['map_Ke textures\\\\',objectname,'.jpg\n']);
        fprintf(fidmtl,['map_d textures\\\\',objectname,'.jpg\n']);
        
    case 'ObjFile'
        Vertices = actor.Data.Vertices;
        Faces = actor.Data.Faces;
        color = actor.Visualisation.settings.colorFace;
        alpha = actor.Visualisation.settings.faceOpacity;
        materialname = strrep(strrep(strrep(actor.Tag,' ',''),']',''),'[','');
        
        
        %add to obj
        fprintf(fid,['o ',materialname,'\n']);
            for i=1:size(Vertices,1)
                fprintf(fid,'v %f %f %f\n',Vertices(i,1),Vertices(i,2),Vertices(i,3));
            end
            fprintf(fid,['usemtl ',materialname,'\n']);
            fprintf(fid,'s on\n');
            for i=1:size(Faces,1)
                fprintf(fid,'f %d %d %d\n',Faces(i,1),Faces(i,2),Faces(i,3));
            end
            
        %update materials file
        fprintf(fidmtl,['newmtl ',materialname,'\n']);
        fprintf(fidmtl,'Ns 135.934392\n');
        fprintf(fidmtl,'Ka 1.000000 1.000000 1.000000\n');
        fprintf(fidmtl,['Kd ',num2str(color),'\n']);
        fprintf(fidmtl,'Ks 0.422700 0.4227000 0.422700\n');
        fprintf(fidmtl,'Ke 0.000000 0.000000 0.000000\n');
        fprintf(fidmtl,'Ni 1.450000\n');
        fprintf(fidmtl,['d ',num2str(alpha),'\n']);
        fprintf(fidmtl,'illum 9\n');

            
        
        
    otherwise
        keyboard
end



fclose(fid);
fclose(fidmtl);

end



