%> @file SOURCES_MATLAB/SF_core_generateopts.m
%> @brief Matlab function helping the user generating an option file.
%>
%> Usage: SF_core_generateopts()
%>
%> Options are placed in a global variable "sfopts" and saved in a
%> stabfem.opts file.
%>
%> sfopts.verbosity: verbosity level
%> sfopts.platform: OS platform (pc, mac or linux)
%> sfopts.interpreter: 'matlab' or 'octave' 
%> sfopts.gitavailable: is git executable available?
%> sfopts.gitrepository: is current stabfem install a git repository?
%> sfopts.sfroot: path to stabfem root
%> sfopts.ffroot: path to freefem binaries
%> sfopts.sfplot: are plot by StabFem enabled?
%> sfopts.ffplot: are plot by FreeFem enabled? (requires ffglut)
%> sfopts.ffglut: path to ffglut
%> sfopts.workdir: path to workdir
%>
%> @author Maxime Pigou
%> @version 1.0
%> @date 25/10/2018 Start writing version 1.0
function SF_core_generateopts()
% Function assisting the user in the option file definition.
global sfopts

sfopts = struct();
sfopts.verbosity = uint8(3);
SF_core_log('n', 'Verbosity is set to Notice (3) during options generation.');

% -- Detecting platform --
if ispc
    sfopts.platform = 'pc';
elseif isunix && ismac
    sfopts.platform = 'mac';
elseif isunix
    sfopts.platform = 'linux';
end
SF_core_log('n', sprintf('Detected platform: %s', sfopts.platform));

% -- Detecting whether MATLAB or OCTAVE --
sfopts.isoctave = logical(exist('OCTAVE_VERSION', 'builtin'));

% -- Detecting GIT installation --
sfopts.gitavailable = false;
sfopts.gitrepository = false;

[s,~] = system('git --version');
if s==0
    SF_core_log('n', 'Git is available on this platform.');
    sfopts.gitavailable = true;
end

if sfopts.gitavailable
    [s,~] = system('git rev-parse --is-inside-work-tree');
    if s==0
        SF_core_log('n', 'StabFem installation is located in a Git repository.');
        sfopts.gitrepository = true;
    else
        SF_core_log('n', 'StabFem installation is not located in a git repository.');
    end
end

% -- Obtaining Stabfem root directory --
sfroot = '';
if sfopts.gitavailable
    [s,t] = system('git rev-parse --show-toplevel');
    if s==0
        sfroot = t(1:end-1);
    end
else
    sfroot = pwd;
end
sfopts.sfroot=[];
while isempty(sfopts.sfroot)
    t=input(sprintf('Please enter StabFem root folder [%s]: ',sfroot),'s');
    if isempty(t)
        t = sfroot;
    end
    if exist(t,'dir')==7
        sfopts.sfroot = t;
    else
        SF_core_log('w','Invalid directory');
    end
end

addpath([sfopts.sfroot '/SOURCES_MATLAB']); 
disp(['Adding directory ''' sfopts.sfroot '/SOURCES_MATLAB '' to path']);

disp('Do you want to add permanently this directory to Matlab/Octave path ?');
disp(' ( N.B. This is recommended for standart users but may lead to trouble ');
disp('   if you consider using several instalations of StabFem on a same system ) ');
t=input(sprintf('OK with this ? [%s]: ','yes'),'s');


if strcmpi(t,'yes')
    % first check in 'pathdef.m' if StabFem is already present 
    if(sfopts.isoctave)
        PATHDEF = which('.octaverc');
        if isempty(PATHDEF)
          PATHDEF = '~/.octaverc';
        end
    else
        PATHDEF = which('pathdef.m');
    end
    fHdl = fopen(PATHDEF);
    if fHdl==-1
       fHdl = fopen(PATHDEF,'w');
    end
    fline = fgets(fHdl);
    foundStabFem = 0;
    while ~isequal(fline,-1)
         foundStabFem = foundStabFem+length(strfind(path,'StabFem'));
        fline = fgets(fHdl);
    end
    if foundStabFem
        SF_core_log('w', ' WARNING : there seems to be already a StabFem folder in your path !');
        SF_core_log('w', ' It is not recommended to have several StabFem installation on a same system');
        %SF_core_log('w', ' The installation program will stop here');
        SF_core_log('w', ' If you want to start a new installation please remove the line containing "StabFem"')
        SF_core_log('w', ' from the file pathdef.m (Matlab) or .octaverc (Octave); then relaunch SF_core_start');
        %SF_core_log('e', ' STOP HERE');
    else
        test = savepath;
        if (test==1)&&(sfopts.isoctave==0)
            SF_core_log('w', ' WARNING : unable to save the file pathdef.m in the starting path ! (may need administrator rights)');
            SF_core_log('w', ' Possible solutions : ');
            SF_core_log('w', '  1. Edit file pathdef.m with administrator rights');
            SF_core_log('w', '  2. Change the starting folder of Matlab');
            SF_core_log('w', '  3. Start Matlab from shell terminal instead of application launcher');
            SF_core_log('w', ['  4. Otherwise you will have to type "addpath(''',sfopts.sfroot, '/SOURCES_MATLAB'');" each time you start matlab ']);
            t=input('OK to continue and agree for 4 ? [yes] or do you prefer to first try solutions (1,2,3) and restart later [no]? ','s');
            if strcmpi(t,'no')
                error('Stop here');
                return;
            end
        elseif (test==1)&&(sfopts.isoctave==0)         
            SF_core_log('w', ' WARNING : unable to save the file .octaverc in the starting path ! (may need administrator rights)');
            SF_core_log('w', ' Possible solutions : ');
            SF_core_log('w', '  1. Edit file .octaverc with administrator rights');
            SF_core_log('w', '  2. Change the starting folder of Octave');
            SF_core_log('w', '  3. Start Octave from shell terminal instead of application launcher');
            SF_core_log('w', ['  4. Otherwise you will have to type "addpath(''',sfopts.sfroot, '/SOURCES_MATLAB'');" each time you start matlab ']);
            t=input('OK to continue ? [yes] or do you prefer to first try solutions (1,2,3) and restart later [no]? ','s');
            if strcmpi(t,'no')
                error('Stop here');
                return;
            end
        end
    end
end

% -- Locating FreeFem++ --
ffroot = '';
[s,t] = SF_core_syscommand('which', 'FreeFem++');
if s==0
    [ffroot,~,~] = fileparts(t);
%    if strcmp(ffroot(end-3:end),'/bin')
%        ffroot = ffroot(1:end-4);
%    else
%        ffroot = [ffroot '/../'];
%    end
% David : removing the  assumption that FreeFem++ is in a 'bin' subfolder 
end
if isempty(ffroot)
    disp('### You now need to enter the name of the folder containing the FreeFem++ executable');
    disp('### If you are using linux/unix/mac, please open a shell terminal and type "which FreeFem++" to know it');
    disp('### If you are using windows, please contact the developers');
end
sfopts.ffroot = [];
while isempty(sfopts.ffroot)
    t=input(sprintf('Please enter the folder containing the FreeFem++ executable [%s]: ',ffroot),'s');
    if isempty(t)
        t = ffroot;
    end
    if strcmp(t(end),'/')
       t = t(1:end-1);
    end
    if exist(t,'dir')==7
        sfopts.ffroot = t;
    else
        SF_core_log('w','Invalid directory');
    end
end

% -- Detecting advanced configuration elements --
% Detect FFglut and ask for usage => question about plots
% (Auto?) detect whether PETSc was used for freefem++ compilation?

% these ones are now displaced in SF_Start
sfopts.ffdir = [sfopts.sfroot '/SOURCES_FREEFEM/']; 
sfopts.ffarg = '-nw -v 0'; 
sfopts.ffargDEBUG = '-v 1';


%TODO: improve setting these arguments
%sfopts.ffdatadir = './WORK/';
% -- Locating working directory --
% Default: './WORK' or '.\WORK'
