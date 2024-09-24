function handle = SF_PlotBF(bf,opts)
%
% Function to plot a base flow, with options from global variable
% PlotBFOptions
%

%PlotBFOptions1 = {'vort','boundary','on','xlim',[-1.5 6],'ylim',[0 0.577],'colorrange',[-10 10],'colormap','parula'};
%PlotBFOptions2 = {'ux','xlim',[-1.5 6],'ylim',[0 0.577],'contour','only'};
%PlotBFOptions = {PlotBFOptions1,PlotBFOptions2};
%SF_core_setopt('PlotBFOptions',PlotBFOptions);


if isempty(SF_core_isopt('PlotBFOptions'))
    SF_core_log('e','To use SF_PlotBF one must define a global variable PlotBFOptions (see manual)');
    return
end
 
PlotBFOptions = SF_core_getopt('PlotBFOptions');
gc = size(PlotBFOptions);
if gc(1)==1
    PlotBFOptions = {PlotBFOptions};
end

for i = 1:gc(1)
    if i==1&&nargin>1
        SF_core_log('n','SF_PlotBF : using default options + custom ones');
        Opts = [PlotBFOptions{i,:},opts];
    else
        Opts = PlotBFOptions{i,:};
    end
    handle = SF_Plot(bf,Opts{:});
    hold on;
end
hold off;

end
