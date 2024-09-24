 function [] = SF_Start(varargin)

% Function SF_Start
% 
% This program us used to set the global variables needed by StabFem
% 
% This program belongs to the StabFem project




p = inputParser;
addParameter(p, 'workdir','./WORK/');
addParameter(p, 'ffdatadir',''); % specify eiher ffdatadir or workdir (synonymous ; legacy)
addParameter(p, 'verbosity',3);
addParameter(p, 'storagemode',2);
addParameter(p, 'ErrorIfDiverge',true);
addParameter(p, 'cleandir',false);
parse(p, varargin{:});
fullstart = false;

%try
%    SF_core_getopt('StabfemIsOperational'
%    SF_core_log('N','Welcome to StabFem !');
%catch
%    fullstart = true;
% end


 
 
if ~SF_core_isopt('StabfemIsOperational')
    SF_core_setopt('StabfemIsOperational',false);
end
if ~SF_core_getopt('StabfemIsOperational')
    disp(' Warning  : SF_core_start was not previously lanched ; launching right now');
    SF_core_start('verbose',(p.Results.verbosity>3));
else
%    SF_core_log('N','running post-startup tasks ');
%    SF_core_start('restart',true,'verbose',p.Results.verbosity>3)
    SF_core_log('N','Initialization already done');
end

PUBLISH = getenv('SF_PUBLISH');
SF_core_setopt('SF_PUBLISH',PUBLISH,'settable', true);

SF_core_setopt('verbosity',p.Results.verbosity);

if ~isempty(p.Results.ffdatadir)
  SF_core_setopt('ffdatadir',p.Results.ffdatadir);
else
  SF_core_setopt('ffdatadir',p.Results.workdir);
end

if p.Results.cleandir
    SF_core_log('N','Cleaning this arborescence ');
    SF_core_arborescence('cleanall')
end

SF_core_setopt('storagemode',p.Results.storagemode);

SF_core_setopt('ErrorIfDiverge',p.Results.ErrorIfDiverge);

SF_core_syscommand('rm','.stabfem_log.bash');

% a few settings for plots
set(0,'defaultAxesFontSize',18);
set (0, 'DefaultLineLineWidth', 2)

if (SF_core_getopt('verbosity')>4)
    SF_core_log('w',' End of Startup : here are the options') 
    SF_core_getopt
end


end
