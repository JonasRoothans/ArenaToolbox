function scene = getScene(varargin)
    global arena 
        if not(isa(arena,'ArenaManager'))
            [arena,scene] = ArenaManager();
        else
            indx = [];
            txt = [];
            for iArgin = numel(varargin)
                thisargin = varargin{iArgin};
                if isnumeric(thisargin)
                    indx = thisargin;
                elseif ischar(thisargin)
                    txt = thisargin;
                end
                    
            end
            scene = arena.sceneselect(indx,txt);
        end
end