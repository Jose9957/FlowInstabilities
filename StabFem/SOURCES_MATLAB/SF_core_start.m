function SF_core_start(varargin)
% Starting process:
%  1 - Checking the path to MATLAB_SOURCES is correctly defined
%  2 - If Octave, adding the path to OCTAVE_SOURCES
%  3 - Loading live opts
%  4 - Loading static opts
%  5 - Post-startup

% ============================
% == Reading user arguments ==
% ============================
numvarargs = length(varargin);
optsnames = {'matlabpath','octavepath','liveopts', 'staticopts', 'poststartup','freefemtests', 'forcemode','verbose','restart'};
vararginval = {@check_matlab_sources_path;
    @check_octave_sources_path;
    @load_live_opts;
    @load_static_opts;
    @poststartup_tasks;
    @freefemtests;
    false;
    true;
    false};
optstest = {@isfcthandle, @isfcthandle, @isfcthandle, @isfcthandle, @isfcthandle, @isfcthandle, @islogical, @islogical, @islogical};

if (numvarargs>0)
    if (~mod(numvarargs,2))
        for i=1:2:(numvarargs-1)
            pos=find(strcmpi(optsnames,varargin(i)));
            if ~isempty(pos)
                if ~feval(optstest{pos},varargin{i+1})
                    error(['Incorrect value for ' varargin{i} ]);
                else
                    vararginval(pos)=varargin(i+1);
                end
            else
                fprintf('%s\n',char(varargin(i)));
                error('unknown input parameter');
            end
        end
    else
        error('wrong number arguments');
    end
end

% setting logical-valuated options
[forcemode,verbose,restart] = vararginval{7:9};

if verbose
    verbosity=3;
else
    verbosity=2;
end
SF_core_setopt('verbosity', verbosity, 'sanitizer', @uint8, 'live', true, 'settable', true,'watcher',@verbosityWatcher);
% ==============================
% == Executing start-up steps ==
% ==============================
%TODO: handle the "force" mode from David.
%TODO: each function should return a boolean, if true, startup may continue.
%TODO: add a pre-startup
headers = {'Startup 01: Checking MATLABPATH';
    'Startup 02: Checking Octave Path';
    'Startup 03: Loading live options';
    'Startup 04: Loading static options';
    'Startup 05: Post-startup tasks';
    'Startup 06: FreeFem tests '
    };

if restart
    steps = 5:6;
else
    steps = 1:6;
end
for i=steps
    if(verbose)
        disp(headers{i});
    end
    if nargout(vararginval{i})==0
        feval(vararginval{i});
    else
        r = feval(vararginval{i});
        if ~r
            error(['Error triggered by ' func2str(varargin{i}) ' in SF_core_start_new.']);
        end
    end
end

SF_core_log('n',' Startup ENDED ; StabFem is now ready for use !');

SF_core_setopt('StabfemIsOperational', true, 'live', true, 'settable', true);

end

% ======================
% == SUB-FUNCTIONS ==
% ======================
function r = isfcthandle(a)
r = isa(a,'function_handle');
end
function check_matlab_sources_path()
% We are currently executing Sf_core_start() so currently
% SOURCES_MATLAB is either in the path or is the working directory.
%
% Just in case, we (re?)add it to the path
curFilePath = mfilename('fullpath');
[curDirPath, ~, ~] = fileparts(curFilePath);
addpath(curDirPath);
end

function check_octave_sources_path()
isoctave = (exist('OCTAVE_VERSION', 'builtin')~=0);
if ~isoctave
    SF_core_log('dd', 'No need to check for Octave PATH, we are in MATLAB.');
else
    %TODO: check that inputParser exists
end
end

function load_live_opts()

% -- Reseting options --
verbosity = SF_core_getopt('verbosity');
SF_core_opts('reset');

% -- Set verbosity --
SF_core_setopt('verbosity', verbosity, 'sanitizer', @uint8, 'live', true, 'settable', true,'watcher',@verbosityWatcher);
SF_core_setopt('StabfemIsOperational', false, 'live', true, 'settable', true);

% -- Detecting platform --
if ispc
    platform = 'pc';
elseif ismac
    platform = 'mac';
elseif isunix
    platform = 'linux';
end
SF_core_setopt('platform', platform, 'live', true);

% -- detect if we are in publish mode
PUBLISH = getenv('SF_PUBLISH');
SF_core_setopt('SF_PUBLISH',PUBLISH,'settable', true);

% -- Detecting environment (MATLAB/OCTAVE) --
SF_core_setopt('isoctave', exist('OCTAVE_VERSION', 'builtin')~=0, 'live', true);

% -- Detecting whether GIT is available --
[s,~] = system('git --version');
if s==0
    SF_core_log('n', 'Git is available on this platform.');
end
SF_core_setopt('gitavailable',s==0, 'live', true, 'tester', @islogical);

% -- Detecting whether we are in git repository --
if SF_core_getopt('gitavailable')
    [s,~] = system('git rev-parse --is-inside-work-tree');
    gitrepository = s==0;
else
    gitrepository = false;
end
SF_core_setopt('gitrepository', gitrepository, 'live', true, 'tester', @islogical);

% -- If we are in git repository, set sfroot as live --
if SF_core_getopt('gitrepository')
    try
        [s, t] = system('git rev-parse --show-toplevel');
    catch
        s = 1;
    end
    if s==0
        %            sfroot = SF_core_path(t,strcmp(SF_core_getopt('platform'),'pc'),false);
        %            if isstring(sfroot)&&strcmp(t(end),char(10))
        %               sfroot = t(1:end-1);
        %               SF_core_log('w',' sfroot transmitted as a string ; bug identified and rectified');
        %            end
        %            SF_core_setopt('sfroot', sfroot, 'live', true)
        if strcmp(t(end),char(10))
            t = t(1:end-1);
        end
        SF_core_setopt('sfroot', t, 'live', true)
    end
end

% -- If sfroot not set previously, trying fetching it from env var --
if ~SF_core_isopt('sfroot') && ~isempty(getenv('SF_PROJECT_ROOT'))
    sfroot = getenv('SF_PROJECT_ROOT');
    if exist(sfroot,'dir')==7
        SF_core_setopt('sfroot', sfroot, 'live', true);
    end
end

% -- If sfroot not set previously, trying to detect it by going up two steps
if ~SF_core_isopt('sfroot')
    SF_core_log('n',' variable sfroot is detected but not in the expected way')
    SF_core_log('n',' It is recommended to create an environement variable for this')
    SF_core_log('n',' Put  the following line in your .bashrc file : ')
    SF_core_log('n','      export SF_PROJECT_ROOT="/home/StabFem"  (or relevant directory)  ')
    
    sfroot = fileparts(fileparts(pwd));
    if exist([sfroot, '/SOURCES_MATLAB'],'dir')
        SF_core_setopt('sfroot', sfroot, 'live', true);
        SF_core_log('n',[' sfroot detected as ',sfroot]);
    end
end

% -- If sfroot not set previously, trying to detect it by going up two steps
if ~SF_core_isopt('sfroot')
    sfroot = fileparts(pwd);
    if exist([sfroot, '/SOURCES_MATLAB'],'dir')
        SF_core_setopt('sfroot', sfroot, 'live', true);
        SF_core_log('n',[' sfroot detected as ',sfroot]);
    end
end

% -- Detecting FreeFem++ ; simplified method

% a/ checking with 'where', 'which', 'locate'

if ispc
    t = 'FreeFem++-mpi';
else
    
    [s,t] = system('locate FreeFem++-mpi');
    if s~=0||contains(t,'locate')||contains(t,'NOT')
        [s,t] = system('which FreeFem++-mpi');
        if s~=0||contains(t,'which')||contains(t,'NOT')
            [s,t] = system('where FreeFem++-mpi');
            if s~=0||contains(t,'where')||contains(t,'NOT')
                t = [];
            end
        end
    end
end

% Remove possible char(10) and char(13) at end
if ~isempty(t)
    if strcmp(t(end),char(10))||strcmp(t(end),char(13))
        t = t(1:end-1);
        SF_core_log('d','removing char(10) or char(13) at end')
    end
    if strcmp(t(end),char(10))||strcmp(t(end),char(13))
        t = t(1:end-1);
        SF_core_log('d','removing char(10) or char(13) at end')
    end
    
    if contains(t,' ')
        t = ['"',t,'"'];
    end
    
    SF_core_log('n','Successfully detected FreeFem++-mpi')
    SF_core_setopt('freefemexecutable',t,'settable', true);
    sfroot = fileparts(t);
    SF_core_setopt('ffroot',sfroot);
    
else
    SF_core_log('w',' Could not detect FreeFem++-mpi using "which" ; looking for an environment variable')
    
    ffroot = [];
    
    % b/ check environment variables
    ffrootEnvVars = {'EBROOTFREEFEMPLUSPLUS' 'SF_FREEFEM_ROOT' 'FFBASEDIR'};
    for I=1:numel(ffrootEnvVars)
        if ~isempty(getenv(ffrootEnvVars{I}))
            ffrootTmp = getenv(ffrootEnvVars{I});
            if exist(ffrootTmp, 'dir')==7
                % either ffrootTmp already refers to the bin folder
                if exist([ffrootTmp filesep 'FreeFem++'], 'file')==2
                    ffroot = ffrootTmp;
                    break;
                    % or it refers to the root of freefem++ installation
                elseif exist([ffrootTmp filesep 'bin' filesep 'FreeFem++'], 'file')==2
                    ffroot = [ffrootTmp filesep 'bin'];
                    break;
                end
            end
        end
    end
    
    if ~isempty(ffroot)
        SF_core_log('n',' FreeFem++ path was detected from an environment variable ')
        
    else
        % c/ checking some classic locations (OLD METHOD TO BE RATIONALIZED)
        PossibleLocations = { '/usr/local/bin/FreeFem++-mpi', '/usr/local/bin/FreeFem++-mpi', ...
            '/usr/local/ff++/mpich3/bin/FreeFem++-mpi','/usr/bin/FreeFem++-mpi' };
        for I=1:numel(ffrootEnvVars)
            if exist(PossibleLocations{I},'file')
                ffroot = fileparts(PossibleLocations{I});
                break
            end
        end
        
        %     if isempty(ffroot)
        %         % Attempt some classic locations
        %         if exist('/usr/local/bin/FreeFem++', 'file')
        %               ffroot='/usr/local/bin';
        %         elseif isunix && exist('/usr/local/bin/FreeFem++', 'file')
        %             ffroot='/usr/local/bin';
        %         elseif isunix && exist('/usr/local/ff++/mpich3/bin/FreeFem++-mpi', 'file')
        %             ffroot='/usr/local/ff++/mpich3/bin/';
        %         elseif exist('/usr/bin/FreeFem++', 'file')
        %             ffroot='/usr/bin';
        %         elseif ispc && (exist('C:\msys64\mingw64\bin\FreeFem++', 'file')||exist('C:\msys64\mingw64\bin\FreeFem++.exe', 'file'))
        %             ffroot='C:\msys64\mingw64\bin';
        %         elseif ispc && (exist('C:\msys32\mingw32\bin\FreeFem++', 'file')||exist('C:\msys32\mingw32\bin\FreeFem++.exe', 'file'))
        %             ffroot='C:\msys32\mingw32\bin';
        %         end
        SF_core_log('n',' FreeFem++ path was detected by exploring classical locations in your system ')
        SF_core_log('n',' StabFem should run but to prevent any problem it is highly recommended to create an environement variable')
        SF_core_log('n',' Please put the following line in your .bashrc file : ')
        SF_core_log('n',['      export SF_FREEFEM_ROOT="',ffroot,'" '])
    end
    if ~isempty(ffroot)
        SF_core_setopt('ffroot', ffroot, 'live', true);
    else
        SF_core_log('w',' FreeFem++ path could not detected  ')
        SF_core_log('w',' Three solutions to this problem :  ')
        SF_core_log('w',' 1/ Please check the path containing the FreeFem executables and create an environment variable for this : ')
        SF_core_log('w','      you should put a line like the following one in your .bashrc file ')
        SF_core_log('w','      export SF_FREEFEM_ROOT="/usr/local/bin/"  (or relevant directory) ')
        SF_core_log('w','      or direclty setenv(''SF_FREEFEM_ROOT'',''/usr/local/bin/'' ) ')
        SF_core_log('w',' 2/ run manually "SF_core_setopt(''freefemexecutable'',''/usr/local/bin/FreeFem++-mpi'');  (or relevant directory) ')
        SF_core_log('w',' 3/ if you don''t have FreeFem++ on your computer you can still use StabFem in postprocess mode (SF_Status/SF_Load) ')
        
        
        
    end
    
    % Adding the ffroot path to the path
    setenv('PATH',[getenv('PATH'),':',ffroot])
    
    % NB this command shoud allow to remove all next stuff  (???)
    
    
    % seting the default FreeFem++ exexutable
    if ~ispc&&~isempty(ffroot)
        if exist([ ffroot, '/FreeFem++-mpi'],'file')
            freefemexecutable = [ ffroot,'/FreeFem++-mpi'];
        elseif exist([fileparts(fileparts(ffroot)),'/mpi/FreeFem++-mpi'],'file')
            freefemexecutable = [fileparts(fileparts(ffroot)),'/mpi/FreeFem++-mpi'];
            setenv('PATH',[getenv('PATH'),':',fileparts(fileparts(ffroot)),'/mpi/']);
        elseif exist([fileparts(ffroot),'/mpi/FreeFem++-mpi'],'file')
            freefemexecutable = [fileparts(ffroot),'/mpi/FreeFem++-mpi'];
            setenv('PATH',[getenv('PATH'),':',fileparts(ffroot),'/mpi/'])
        else
            freefemexecutable = [ ffroot,'/FreeFem++'];
            SF_core_log('w', 'FreFem++-mpi does not seem available ! assuming FreeFem++');
        end
    else
        freefemexecutable = 'FreeFem++-mpi';
    end
    SF_core_setopt('freefemexecutable',freefemexecutable, 'settable', true); % options for this one ?
    %%%% END OLD METHOD TO BE RATIONALIZED
end



% -- Setting a few more options --

SF_core_setopt('ffversion',1e4,'settable', true); % trick for compatibility
SF_core_setopt('ffmpiversion',1e4,'settable', true); % trick for compatibility

SF_core_setopt('ffarg', '-nw -v 0', 'live', true, 'settable', true);
SF_core_setopt('ffargDEBUG', '-v 1', 'live', true, 'settable', true);

SF_core_setopt('solver', 'default','settable', true);


SF_core_setopt('BFSolver', [], 'live', true, 'settable', true,'watcher',@BFsolverWatcher);
SF_core_setopt('StabSolver', [], 'live', true, 'settable', true,'watcher',@StabsolverWatcher);
SF_core_setopt('PlotBFOptions', [], 'live', true, 'settable', true,'watcher',@PlotOptionsWatcher);
SF_core_setopt('PlotModeOptions', [], 'live', true, 'settable', true,'watcher',@StabPlotOptionsWatcher);


%   disp('settinhg here');


end

%%
function load_static_opts()
% First, attempt to read option file
SF_core_opts('read');

% Then, ask missing options to user
while ~SF_core_isopt('sfroot')
    SF_core_log('w','The root of your current StabFem installation could not be detected.')
    t=input(sprintf('Please enter the path to the root of StabFem: '),'s');
    if isempty(t)
        disp('Please enter a value');
        continue
    end
    if ~exist(t,'dir')==7
        disp('This folder does not exist.')
        continue
    end
    sfroot = t;
    if strfind(t,'(') % strfind instead of contains for octave
        SF_core_log('e',' The name of the path where you have installed StabFem contains parentheses : this will not operate properly. please fix ');
    end
    if strfind(t,' ') % idem
        SF_core_log('w',' The name of the path where you have installed StabFem contains blank spaces : this may not work correctly ');
    end
    SF_core_setopt('sfroot', sfroot);
end

while ~SF_core_isopt('ffroot')
    SF_core_log('w','FreeFem++ could not be automatically located on your system.');
    t=input(sprintf('Please enter the folder containing the FreeFem++ executable: '),'s');
    if isempty(t)
        disp('Please enter the folder name ');
        continue
    end
    if strcmp(t,'skip')
        ffroot = './';
        SF_core_log('w','FreeFem++ detection was skipped manually');
        continue
    elseif ~exist(t,'dir')==7
        disp('This folder does not exist.')
        F_core_log('n','type "skip" to skip this step (and continue at your own risks...');
        continue
    end
    if exist([t filesep 'FreeFem++'],'file')==2
        ffroot = SF_core_path(t);
    elseif exist([t filesep 'bin' filesep 'FreeFem++'],'file')==2
        ffroot = SF_core_path([t filesep 'bin']);
    else
        SF_core_log('w','FreeFem++ could not be found in this folder.');
        SF_core_log('w','type "skip" to skip this step (and continue at your own risks...');
        continue
    end
    SF_core_setopt('ffroot', ffroot);
end

if ~SF_core_isopt('ffroot')||isempty(SF_core_isopt('ffroot'))
    SF_core_log('w',' FreeFem++ could not be detected on your system !')
    SF_core_log('w',' you will be able to use StabFem in post-process mode only')
    SF_core_setopt('ffroot', '');
end


if ~SF_core_getopt('gitrepository')
    SF_core_log('n','writing file for future uses')
    SF_core_opts('write');
end
end


function r = poststartup_tasks()
% Load a few missing options
ffdir = [SF_core_getopt('sfroot') filesep 'SOURCES_FREEFEM' filesep];
ffdirPRIVATE = [SF_core_getopt('sfroot') filesep 'SOURCES_FREEFEM_PRIVATE' filesep];
SF_core_setopt('ffdir', {ffdir,ffdirPRIVATE},'settable', true);

ffincludedir = [SF_core_getopt('sfroot') filesep 'SOURCES_FREEFEM' filesep 'INCLUDE' filesep];
ffinclidedirPRIVATE = [SF_core_getopt('sfroot') filesep 'SOURCES_FREEFEM_PRIVATE' filesep 'INCLUDE' filesep];
SF_core_setopt('ffincludedir',{ffincludedir,ffinclidedirPRIVATE},'settable', true);

SF_core_setopt('ffdirPRIVATE', ffdirPRIVATE,'settable', true);    % keep this one temporarily for HBN
SF_core_setopt('ffloaddir', [ffdir 'LOAD' filesep],'settable', true);

% Set a few more:
SF_core_setopt('ffdatadir', './', 'live', true, ...
    'settable', true, 'sanitizer', @ffdatadirSanitizer, ...
    'watcher', @ffdatadirWatcher);
SF_core_setopt('storagemode', 2, 'live', true, 'settable', true);

SF_core_setopt('ErrorIfDiverge',true,'live', true, 'settable', true);

SF_core_setopt('VhList','','live', true, 'settable', true);


% checking FreeFem++ version
if isempty(SF_core_getopt('ffroot'))
    SF_core_log('nnn','Skipping last part of poststartup_tasks');
    r=[];
    return
end

ffroot = SF_core_getopt('ffroot');

% Checking FreeFem++ version
% try
%     [code,z] = system(['"', ffroot, '/FreeFem++" -nw']);
%     if (code>1)
%         SF_core_log('w',' Problem when running Freefem executable (maybe a Library is not correctly linked ; check FreeFem++ outside of StabFem)');
%     end
%     w = strsplit(z);
%     ind = 2;
%     while (isempty(str2num(w{ind}))||(~isempty(str2num(w{ind}))&&str2num(w{ind})==0))&&ind<20
%         ind = ind+1;
%     end
%     ffversion = str2num(w{ind});
%     SF_core_log('n',['Detected FreeFem++ version ',num2str(ffversion)]);
%     if isempty(ffversion)
%         SF_core_log('w',' Problem when detecting FreeFem++ version');
%         ffversion = 1e4
%     end
% catch
%     SF_core_log('w','Could not detect FreeFem++ version.')
%     ffversion = 1e4;
% end
%try
    % Checking FreeFem++-mpi version
    [~,z] = system(SF_core_getopt('freefemexecutable'));
    if contains(z,'command not found')
        error('FreeFem++-mpi not found ')
    end
    w = strsplit(z);
    ind = 2;
    while (isempty(str2num(w{ind}))||(~isempty(str2num(w{ind}))&&str2num(w{ind})==0))&&ind<20
        ind = ind+1;
    end
    ffmpiversion = str2num(w{ind});
%    if isempty(ffmpiversion)
%        ffmpiversion = 10;
%        SF_core_log('w','Could not detect correcly FreeFem version')
%    end
    SF_core_log('n',['Detected FreeFem++-mpi version ',num2str(ffmpiversion)]);
    if isempty(ffmpiversion)
        SF_core_log('w',' Problem when detecting FreeFem++-mpi version');
        ffmpiversion = 1e4;
    end
%catch
%    SF_core_log('w','Could not detect FreeFem++-mpi version : using FreeFem++ instead')
%    ffmpiversion = 1e4;
%    ffexe =  SF_core_getopt('freefemexecutable');
%    if strcmp(ffexe(end-3:end),'-mpi')
%        SF_core_setopt('freefemexecutable',ffexe(1:end-4),'settable', true)
%    end
%    
%end

SF_core_setopt('ffmpiversion',ffmpiversion,'settable', true);
SF_core_setopt('ffversion',ffmpiversion,'settable', true); % to be removed someday


% Check that all required options are available
r = true; %Return false if some options are missing.

% file .stabfem_log.bash
fidlog = fopen('.stabfem_log.bash','w');
if (fidlog>0)
    fprintf(fidlog, '# \n');
    fprintf(fidlog, '#  This file is summary of all bash commands used when running you StabFem case \n');
    fprintf(fidlog, '# \n');
    fclose(fidlog);
end

end



function r = freefemtests()

SF_core_setopt('solver', '', 'live', true, 'settable', true,'watcher',@solverWatcher); % temporary but required ; this will be redefined afer the tests.

if isempty(SF_core_getopt('ffroot'))
    SF_core_log('n','Skipping freefemtests');
    r=[];
    return
end

try
    ffroot = SF_core_getopt('ffroot');
    
    
    % Checking which librairies are installed
    librairies = { 'SuperLu','MUMPS','PETSc','SLEPc'};
    for i = 1:length(librairies)
        lib = librairies{i};
        if SF_core_detectlib(lib)
            SF_core_log('n',['librairy ',lib,' is available']);
        else
            SF_core_log('w',['librairy ',lib,' NOT available']);
        end
    end
    
     % Checking which eigenvalue solvers are installed
    librairies = { 'SLEPc-complex','ARPACK'};librairiesinclude = { 'SLEPC','ARPACK'};
    for i = 1:length(librairies)
        lib = librairies{i};
        if SF_core_detectlib(lib)
            SF_core_log('n',['librairy ',lib,' is available']);
            if ~SF_core_isopt('eigensolver')
                SF_core_log('n',['Using ',lib,' as eigensolver']);
                SF_core_setopt('eigensolver',librairiesinclude{i},'live', true, 'settable', true);
            end
        else
            SF_core_log('w',['librairy ',lib,' NOT available']);
        end
    end
    
    if ~SF_core_isopt('eigensolver')
        SF_core_log('w',[' Neither SLEPC not ARPACK are detected. You will not be able to perform eigenvalue computations ']);
        SF_core_setopt('eigensolver','','live', true, 'settable', true);
     end
    
    % block to be removed soon
    %MUMPSAVAILABLE = SF_core_detectlib('MUMPS','bin','FreeFem++');
    % if ~MUMPSAVAILABLE
    %   SF_core_log('w','MUMPS NOT AVAILABLE WITH FreeFem++ executable (nonstandard implementation)');
    %   SF_core_setopt('MUMPSAVAILABLE',MUMPSAVAILABLE,'live', true, 'settable', false);
    % end
    % end block
    
    % Elementary tests to import data from freefem
    test1 = SF_Launch('TESTS/Test1_importdata.edp');
    if (isstruct(test1)&&isfield(test1,'Z')&&(test1.Z==1i))
        SF_core_log('n','Elementary Freefem test 1 (import data) passed');
    else
        SF_core_log('w','Elementary Freefem test 1 (import data) FAILED');
    end
    SF_core_syscommand('rm','Data.txt');SF_core_syscommand('rm','Data.ff2m');
    test2 = SF_core_freefem('TESTS/Test2_pipe.edp','parameters','1 test','continueonerror','yes' );
    if ~test2
        SF_core_log('n','Elementary Freefem test 2 (piping parameters) passed');
    else
        SF_core_log('w','Elementary Freefem test 2 (piping parameters) FAILED');
    end
    
    r = true;
    
catch
    SF_core_log('w','Problems when doing FreeFem tests.')
    r=true;
    SF_core_setopt('eigensolver','SLEPC','live', true, 'settable', true);
end
end




function watcherMkdir(optionname)
SF_core_syscommand('mkdir', SF_core_getopt(optionname));
end

function output = ffdatadirSanitizer(input)
if strcmp(input(end), filesep)|| strcmp(input(end), '/')
    output = input;
else
    output = [input '/']; % modified 22/11/2021 for windows
end
end

function ffdatadirWatcher(optname)
workdir = SF_core_getopt('ffdatadir');

if strcmp(workdir,'./')||strcmp(workdir,'')
    return
end

SF_core_log('n',['Database directory :' workdir]);
if  exist(workdir,'dir')
    SF_core_log('n',['This directory already exists']);
    if ~exist([workdir 'STATS'],'dir')
        SF_core_log('n',' Warning arborescence seems to be obsolete or inexistent : creating it')
        SF_core_arborescence('create');
    end
    SF_core_log('n','Please type "SF_Status" to see what is available in this dir');
    SF_core_log('n','    or type "SF_core_arborescence(''cleanall'')" to erase any previous data');
else
    SF_core_log('n',['Working dir does not exist : create it']);
    SF_core_arborescence('create');
    
end
end

function verbosityWatcher(optname)
levellist = {'Autorun mode';'Errors only'; 'Errors + Warnings';'Notice messages'; 'Notice + FreeFem output';
    'Notice + Legacy issues';'Debug'; 'Debug+'; 'Debug++'};
verbosity = SF_core_getopt('verbosity');
if (verbosity==4)&&~isempty(SF_core_getopt('SF_PUBLISH'))
    SF_core_log('w','Detected verbosity = 4 in Publish mode ; not recommended ! switching to 2 instead')
    SF_core_setopt('verbosity',2)
else
    SF_core_log('n',['Verbosity set to ' , num2str(verbosity), ' : ',levellist{verbosity+1}]);
end
end

function eigensolverWatcher(optname)
eigensolver = SF_core_getopt('eigensolver');
if strcmpi(eigensolver,'ARPACK')
    SF_core_log('n',['Eigensolver set to ARPACK']);
    %  if strcmp(SF_core_getopt('platform'),'mac')&&exist('/usr/local/bin/FreeFem++361','file')
    %     SF_core_log('w','Warning : ARPACK INSTALATION FOR DAVID''S MAC : using FeFem361');
    %     SF_core_setopt('freefemexecutable','/usr/local/bin/FreeFem++361');
    %  end
elseif strcmpi(eigensolver,'SLEPC')
    SF_core_log('n',['eigensolver set to SLEPC']);
elseif strcmpi(eigensolver,'default')
    if SF_core_detectlib('SLEPc-complex','bin','FreeFem++-mpi')
        SF_core_setopt('eigensolver','SLEPC')
    else
        SF_core_setopt('eigensolver','ARPACK')
    end
elseif strcmpi(eigensolver,'')
    SF_core_log('dd',['Temporarily setting eigensolver to '''' (must be set to something before tests)']);
else
    SF_core_log('e','eigensolver must be either ARPACK or SLEPC !');
end
end

function solverWatcher(optname)
solver = SF_core_getopt('solver');
if strcmpi(solver,'MUMPS')
    SF_core_log('n',['solver set to MUMPS']);
    
elseif strcmpi(solver,'default')
    if SF_core_detectlib('MUMPS','bin','FreeFem++-mpi')
        SF_core_setopt('solver','MUMPS')
    else
        SF_core_setopt('solver','')
    end
elseif strcmpi(solver,'')
    SF_core_log('dd',['Temporarily setting solver to '''' (must be set to something before tests)']);
else
    SF_core_log('w','Not sure about your solver ');
end
end

function BFsolverWatcher(~)
    BFSolver = SF_core_getopt('BFSolver');
     if ~isempty(BFSolver)
        if ~ischar(BFSolver)&&~isstring(BFSolver)
            SF_core_log('e',' Option BFSolver should be a char or a string');
        end
        SF_core_log('n',['Solver ', BFSolver, ' has been defined as default solver for Base-Flow computations']); 
     end
end

function StabsolverWatcher(~)
    BFSolver = SF_core_getopt('StabSolver');
     if ~isempty(BFSolver)
        if ~ischar(BFSolver)&&~isstring(BFSolver)
            SF_core_log('e',' Option BFSolver should be a char or a string');
        end
        SF_core_log('n',['Solver ', BFSolver, ' has been defined as default solver for Stability computations']); 
     end
end

function PlotOptionsWatcher(~)
    PlotOptions = SF_core_getopt('PlotBFOptions');
     if ~isempty(PlotOptions)
        if ~iscell(PlotOptions)
            SF_core_log('e',' plot Options should be a cell array');
        end
        SF_core_log('n',['Default options for ploting base flows have been set']); 
     end
end

function StabPlotOptionsWatcher(~)
    PlotOptions = SF_core_getopt('PlotModeOptions');
     if ~isempty(PlotOptions)
        if ~iscell(PlotOptions)
            SF_core_log('e',' plot Options should be a cell array');
        end
        SF_core_log('n',['Default options for plotting eigenmodes have been set']); 
     end
end