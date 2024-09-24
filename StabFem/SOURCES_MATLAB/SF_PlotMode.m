

function [] = SF_PlotMode(emPLOT)
%>
%> This function is called internally in "Spectrum explorator" mode
%> (launched when clicking on an eigenvalue)
%> Added by DF on january 22,2020 after IMFT seminar...
%> 

    SF_core_log('d',' ... Ploting an eigenmode ... ' ); 
    SF_core_log('n',[ ' Plotting eigenmode , filename : ', emPLOT.filename]);

    if isempty(SF_core_getopt('PlotModeOptions'))
               THEPlotModeOptions = {};
               SF_PlotMode_Legacy(emPLOT);
               return
    end
    
    THEPlotModeOptions = SF_core_getopt('PlotModeOptions');
    gc = size(THEPlotModeOptions);
    if gc(1)==1
        THEPlotModeOptions = {THEPlotModeOptions};
    end
    
 for i = 1:gc(1)
    PlotModeOptions = THEPlotModeOptions{i,:};
    if ischar(PlotModeOptions{1})&&strcmpi(PlotModeOptions{1},'SF_Plot_ETA')
        SF_core_log('d',['in SF_Plot_Mode : layer ',num2str(i),' using SF_Plot_ETA with options']);
        PlotModeOptions =  {PlotModeOptions{2:end}};
        if SF_core_getopt('verbosity')>5 
            PlotModeOptions
         end
        SF_Plot_ETA(emPLOT,PlotModeOptions{:});  
    else
        % using SF_Plot
    % tweak the title
    test = 0;
    for ii=1:length(PlotModeOptions)
        if ischar(PlotModeOptions{ii})&&strcmp(PlotModeOptions{ii},'title')
            test=1;
            break;
        end
    end
    if ~test
        [plottitle1,plottitle2] = SFcore_generateplottitle(emPLOT);
        plottitle = { plottitle1, plottitle2}; 
        PlotModeOptions= {PlotModeOptions{:},'title',plottitle};
    end
    % plot
     SF_core_log('d',['in SF_Plot_Mode : layer ',num2str(i),' using SF_Plot with options']);
     if SF_core_getopt('verbosity')>5 
         PlotModeOptions
     end
     SF_Plot(emPLOT,PlotModeOptions{:});  
    end
    hold on; 
 end
 hold off;
end

