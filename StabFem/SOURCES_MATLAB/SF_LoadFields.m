function ffdata = SF_LoadFields(ffdata)
%
% This function is used to load all fields from files (.txt and .ff2m) 
% for a dataset which was 'unloaded', i.e. only metadata were read from
% files.
%
% USAGE :
% ffdata = SF_LoadFields(ffdata)
%
% EXAMPLE :
% > [ev,em] = SF_Stability(bf,'nev',10,'shift',1i,[...]);
% > em(1)
%       -> struct containing empty fields ux = [], uy = [], ...
% > em(1) = SF_LoadFields(em(1))
%       -> fields ux, uy are now loaded and ready for postprocess
% NB if not loaded SF_Plot and SF_ExtractData will call internally SF_LoadField. However
% if several plots and extractions are to be done it is better do it
% once at all before post processing.



if isfield(ffdata,'status')&&strcmp(ffdata.status,'loaded')
    SF_core_log('n',' Dataset was already loaded ');
    return
else
    ffdata = SFcore_ImportData(ffdata.filename);
    ffdata.status = 'loaded';
end

end