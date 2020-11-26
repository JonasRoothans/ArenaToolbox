function displayHighestResults(predictInformation)
 
showResultWindow=figure('units','normalized',...
                'outerposition',[xpos ypos xwidth yheight],...
                'menubar','none',...
                'name',obj.Title,...
                'numbertitle','off',...
                'resize','off',...
                'UserData',obj,...
                'CloseRequestFcn',@closePrediction,...
                'WindowKeyPressFcn',@kSnapshotPrediction,...
                'Color',[1 1 1]);
            
            function closePrediction(hObject,eventdata)
                request=questdlg('Are you sure you want to close the Prediction?','Confirmation',...
                    'Quit','Close','Close');
                switch request
                    case 'Quit'
                        return
                    case 'Close'
                        delete(gcf);
                end
            end
            
            function kSnapshotPrediction (hObject,eventdata)
                spaceBarPressed=eventdata.Key;
                if strcmpi(spaceBarPressed,'space')
                    h=getframe(gcf);
                    text=inputdlg('Type your number of the screenshot: ');
                    name='.png';
                    text=char(text);
                    imwrite(h.cdata,['screenshot',text,name]);
                end
            end

end

