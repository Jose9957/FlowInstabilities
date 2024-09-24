function pdestruct = importFFdata(varargin)
%  function importFFdata
% NB the name of the function has changed ! 
% Please use now "SFcore_ImportData"

disp(' WARNING : importFFdata should be replaced by SFcore_ImportData');
pdestruct = SFcore_ImportData(varargin{:});

end
