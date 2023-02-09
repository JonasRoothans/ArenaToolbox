function [outputArg1,outputArg2] = A_loadgraphml(scene,pathname)
%A_LOADGRAPHML Summary of this function goes here
%   Detailed explanation goes here
%pathname = '/Users/jonas/Downloads/repeated_10_scale_33/690152_repeated10_scale33.graphml';

[~,filename] = fileparts(pathname);

xml =  SDK_xml2struct(pathname);
dict = struct();
for i = numel(xml.graphml.key):-1:1
    a = xml.graphml.key{i}.Attributes;
    disp([a.id,' :',a.attr_dot_name,' (',a.attr_dot_type,') for ',a.for])
    dict.(a.id).name = a.attr_dot_name;
    dict.(a.id).type = a.attr_dot_type;
end



for i = 1:numel(xml.graphml.graph.node)
    thisnode = xml.graphml.graph.node{i};
    node = struct();
    for j = 1:numel(thisnode.data)
        try
            fname = dict.(thisnode.data{j}.Attributes.key).name;
            type = dict.(thisnode.data{j}.Attributes.key).type;
            switch type
                case 'double'
                    value = str2num(thisnode.data{j}.Text);
                otherwise
                    value = thisnode.data{j}.Text;
            end
        catch
            fname = thisnode.data{j}.Attributes.key;
            value = thisnode.data{j}.Text;
        end
        node.(fname) = value;
    end
    node.vector3D = Vector3D(node.dn_position_x,node.dn_position_y,node.dn_position_z);
    
    if i==1
        nodes = node;
    else
        nodes(i) = node;
    end
    
    
end

nodes_pc = PointCloud([[nodes(:).dn_position_x]',[nodes(:).dn_position_y]',[nodes(:).dn_position_z]']);
actor = nodes_pc.see(scene);
actor.changeName(['nodes: ',filename])

f1 = Fibers;
f2 = Fibers;
for i = 1:numel(xml.graphml.graph.edge)
    thisedge = xml.graphml.graph.edge{i};
    edge = struct();
    for j = 1:numel(thisedge.data)
        
        
        try
            fname = dict.(thisedge.data{j}.Attributes.key).name;
            type = dict.(thisedge.data{j}.Attributes.key).type;
            switch type
                case 'double'
                    value = str2num(thisedge.data{j}.Text);
                otherwise
                    value = thisedge.data{j}.Text;
            end
        catch
            fname = thisedge.data{j}.Attributes.key;
            value = thisedge.data{j}.Text;
        end
        edge.(fname) = value;
        
    end
    edge.source = str2num(thisedge.Attributes.source);
    edge.target = str2num(thisedge.Attributes.target);
    
    fiber = PointCloud;
    fiber.addVectors(nodes(edge.source).vector3D);
    fiber.addVectors(nodes(edge.target).vector3D);
    
    f1.addFiber(fiber,i,edge.FA_mean);
    f2.addFiber(fiber,i,edge.number_of_fibers);
    
    if i==1
        edges = edge;
    else
        edges(i) = edge;
    end
    
    
end

actor = f1.see(scene);
actor.changeSetting('numberOfFibers',numel(edges),'colorByWeight',1);
actor.changeName(['fibers FA_mean: ',filename]);

actor = f2.see(scene);
actor.changeSetting('numberOfFibers',numel(edges),'colorByWeight',1);
actor.changeName(['fibers Number: ',filename]);



%         try
%             fname = dict.(thisnode.data{j}.Attributes.key).name;
%             type = dict.(thisnode.data{j}.Attributes.key).type;
%             switch type
%                 case 'double'
%                     value = str2num(thisnode.data{j}.Text);
%                 otherwise
%                     value = thisnode.data{j}.Text;
%             end
%         catch
%             fname = thisnode.data{j}.Attributes.key;
%             value = thisnode.data{j}.Text;
%         end
%         node.(fname) = value;
%     end
%
%     if i==1
%         nodes = node;
%     else
%         nodes(i) = node;
%     end





end

