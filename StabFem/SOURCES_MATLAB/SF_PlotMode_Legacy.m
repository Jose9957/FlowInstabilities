

function [] = SF_PlotMode_Legacy(emPLOT)
%>
%> This function is called internally in "Spectrum explorator" mode
%> (launched when clicking on an eigenvalue)
%> Added by DF on january 22,2020 after IMFT seminar...
%> 

SF_core_log('w',' Using obsolete SF_PlotMode_Legacy.'); 
SF_core_log('w',' You should now use SF_PlotMode and define a global variable PlotModeOptions (see manual)')

 if SF_core_isopt('PlotModeOptionsLEG')&&~isempty(SF_core_getopt('PlotModeOptionsLEG'))
      PlotModeOptions = SF_core_getopt('PlotModeOptionsLEG');
 else
       PlotModeOptions = {};
 end
    
    if mod(length(PlotModeOptions),2)==1
            thefield = PlotModeOptions{1};
            PlotModeOptions = {PlotModeOptions{2:end}};
        else
            
        if ~SF_core_isopt('PlotSpectrumField')
                if isfield(emPLOT,'ux')
                    thefield = 'ux';
                elseif isfield(emPLOT,'uz')
                    thefield = 'uz';
                elseif isfield(emPLOT,'p')
                      thefield = 'p';  
                else
                    SF_core_log('w',' You need to precise a fieldname using ''PlotSpectrumField'' ');
                end    
            else
                thefield = SF_core_getopt('PlotSpectrumField');
        end
    end
     SF_core_log('n',[' ... Plot field ',thefield] ); 
    
    [plottitle1,plottitle2] = SFcore_generateplottitle(emPLOT);
    plottitle = { plottitle1, plottitle2}; 
    figure; 

    SF_Plot(emPLOT,thefield,'title',plottitle,PlotModeOptions{:});  
    
    
    if isfield(emPLOT,'eta')
        SF_core_log('n','adding plotting eta on plot');
        [~,posmax] = max(abs(emPLOT.eta));
       % E=0.2/emPLOT.eta(posmax);
       E = 0.1;
        hold on;SF_Plot_ETA(emPLOT,'Amp',E,'style','r');
    end
    
 %   if isfield(emPLOT,'Xplate')&&isfield(emPLOT,'ksi')
 %       SF_core_log('n','adding plotting ksi on plot');
 %       hold on; plot(emPLOT.Xplate,real(emPLOT.ksi),'r-');
 %   end
 % end
 hold off;
end

% function str = mycell2str(cell)
% % This function will convert a cell array into a string 
% % (for interactive spectrum explorer with option 'plotspectrum'='yes')
% %
% str = '';
% for i = 1:length(cell)
%     str = [str ','];
%     if(ischar(cell{i}))
%         str = [ str, '''' cell{i}  '''' ];
%     end
%     if(isnumeric(cell{i}))
%         str = [ str, '[' num2str(cell{i}) ']' ];
%     end
% end
% str = [str ''];
% end
% 
