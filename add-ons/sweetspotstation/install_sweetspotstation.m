function install_sweetspotstation(menuhandle,eventdata,scene)

scene.addon_addmenuitem('sweetspotstation','Make recipe',str2func('@sweetspotstation_makerecipe'))
disp('Docking complete')

end