function ffargument = SF_CreateArgumentString(p,TweakedParameters)
%
% This function assembles the argument string for parameters to be
% transmitted to FreeFem though getARGV
%
% beta version, june 15 2020

ffargument = '';
for pp = p.Parameters
 param=pp{1};
 if (~ismember(param,p.UsingDefaults)||ismember(param,TweakedParameters.list))&&~strcmp(param,'shift')
   if isnumeric(p.Results.(param))&&~isempty(p.Results.(param))
      if imag(p.Results.(param))==0
        ffargument = [ffargument, ' -',param,' ', num2str(p.Results.(param)), ' '];
      else
        ffargument = [ffargument, ' -',param,'_r ', num2str(real(p.Results.(param))), ' '];
        ffargument = [ffargument, ' -',param,'_i ', num2str(imag(p.Results.(param))), ' '];
      end
   elseif ischar(p.Results.(param))
       if ~strcmp(param,'solver')
          ffargument = [ffargument, ' -',param,' ', p.Results.(param), ' '];
       end
   else
       SF_core_log('l',['CANNOT USE SF_CreateArguùentString ; argument ',param, ' is not of a recognized type ! use only string or numeric']); 
   end
 end
end
if isfield(TweakedParameters,'shift')&&isfield(p.Results,'shift')
    ffargument = [ffargument, ' -shift_r ', num2str(real(TweakedParameters.shift))];
    ffargument = [ffargument, ' -shift_i ', num2str(imag(TweakedParameters.shift))];
end
end