%> @file SOURCES_MATLAB/SF_core_getopt.m
%> @brief Matlab function getting an option value by its name.
%>
%> Usage: value = SF_core_getopt(optname)
%>
%> Options are placed in a global variable "sfoptsS" and saved in a
%> SF_core_getopt
%>
%> @author Maxime Pigou
%> @version 1.0
%> @date 02/07/2019 Start writing version 1.0
function value = SF_core_getopt(optname)
global sfopts sfoptsS

% no-argument mode (for debug only)
if (nargin==0)
    value = sfopts;
    return;
end

if ~isfield(sfopts,optname)
    SF_core_log('w',[' Calling SF_core_getopt with unknown variable : ',optname]);
    value = [];
    return
end

% Checking for inconsistencies between sfopts and sfoptsS
isLegacyField = isfield(sfopts,optname);
isNewField = any(strcmp(optname, {sfoptsS(:).name}));



if ~isLegacyField && ~isNewField
    SF_core_log('e', ['SF_core_getopt: option ' optname ' does not exist.']);
    return
elseif isLegacyField ~= isNewField
    SF_core_log('e', ['SF_core_getopt: option ' optname ' is defined but in an odd way. Are you sure you only used SF_core_setopt to change option values?!']);
    return
else
    legacyValue = sfopts.(optname);
    newValue = sfoptsS(strcmp(optname, {sfoptsS(:).name})).value;
    if ~isequal(legacyValue,newValue)
        SF_core_log('e', ['SF_core_getopt: option ' optname ' is defined but two different values exist for it. You have messed with sfopts manually, didn''t you?!']);
        return
    end
    
    value= newValue;
end

