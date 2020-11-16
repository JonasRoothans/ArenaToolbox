function scene = newScene(OPTIONALname)
%NEWSCENE Opens a new scene. Optional input: scene name
    global arena 
        if not(isa(arena,'ArenaManager'))
            [arena,scene] = ArenaManager();
        else
        
            if nargin==1
                scene = arena.new(OPTIONALname);    %does not work?
            else
                scene = arena.new();
            end
        end


end