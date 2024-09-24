function SFcore_addParameter(p,baseflow,ParamName,Default,expectedtype)
% This function is used to bypass the "Addparameter" to tweak default values as follows :
% 1/ if the parameter is in the list of options in the arguments of the
%       function we use the corresponding value
% 2/ instead, if the parameter is a field of the "baseflow" we use this value 
% 3/ otherwise we use the default value.
global TweakedParameters % to be done better
if isempty(TweakedParameters)
    TweakedParameters.list = {};
    SF_core_log('l',' TweakedParameters is a very ugly trick to be fixed');
end
if (isfield(baseflow, ParamName)) 
    TheDefault = baseflow.(ParamName);
    TweakedParameters.list = [ TweakedParameters.list, ParamName];
else
    TheDefault = Default;
end
if (nargin==4)
    addParameter(p, ParamName, TheDefault); 
else
    addParameter(p, ParamName, TheDefault, expectedtype); 
end
end
