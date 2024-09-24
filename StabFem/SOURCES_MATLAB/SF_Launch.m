function varargout = SF_Launch(file, varargin)
% generic Matlab/FreeFem driver
%
% usage : mesh = SF_Launch('File.edp', {Param1, Value1, Param2, Value2, etc...})
%
% First argument must be a valid FreeFem++ script
%
% Couples of optional parameters/values comprise :
%   'Options' -> Optional arguments passed to
%           Freefem and interpreted with getARGV.
%    Three methods :
%      1/   A list of descriptor/value pairs
%           Example :
%              SF_Launch('File.edp','Options',{'option1' 10 'option2' 20})
%              will launch 'FreeFem++ File.edp -option1 10 -option2 20'
%      2/   A structure
%           Example :
%               Opt.option1 = 10; Opt.option2 = 20;
%               SF_Launch('File.edp','Options',Opt)
%      3/   A string containing the optional arguments.
%           Example :
%               SF_Launch('File.edp','Options','-option1 10 -option2 20')
%   'ncores' -> number of cores for parallel run
%   'Include' -> a cell-array list of strings to be included in the preamble
%   'Params' -> an array of (numerical) input parameters for the FreeFem++ script
%           for instance SF_Launch('File.edp','Params',[10 100]) will be
%           equivalent to running 'FreeFem++ File.edp' and entering successively
%           10 and 100 through the keyboard)
%   'Mesh' -> a mesh associated to the data
%           (either a mesh struct or the name of a file)
%   'BaseFlow' -> a baseflow associated to the data
%           (either a flowfield struct or the name of a file)
%           (NB if providing a baseflow it is not ncessary to provide a
%           mesh as themesh is a field of the baseflow object)
%   'DataFile' -> the name(s) of the resulting file to be imported
%                 (default is 'Data.txt', for multiple files use a cell-array list)
%   'Store' -> a string corresponding to the name of the subfolder where
%                 the data files should be stored
%   'LoadFields' (true|false) -> to specify if all mesh-associated data should be imported
%                from .txt file (and from auxiliary data in .ff2m file).
%                default is 'true' but setting to 'false' may speed up the
%                code (the data will then be imported only when needed).
%   'Type' -> a string specifying the type of computation for the FreeFem++ script (OBSOLETE ?)
% 
%
% by D. Fabre, june 2017, redesigned dec. 2018 then may-june 2020 then sept
% 2020 then on and on...
%

% parameters management
p = inputParser;
addParameter(p, 'Params', []);
addParameter(p,'Options','');
addParameter(p, 'Mesh', 0);
addParameter(p, 'Init', 0);
addParameter(p, 'Forcing', 0);
addParameter(p, 'BaseFlow', 0);
addParameter(p, 'DataFile', 'Data.ff2m');
addParameter(p, 'MeshFile', '');
addParameter(p, 'Store', '');
addParameter(p, 'Type', 'none');
addParameter(p, 'Include','');
addParameter(p, 'Macros',''); % alternative to Include, obsolete
addParameter(p, 'ncores', 1, @isnumeric); % number of cores to launch in parallel
addParameter(p, 'LoadFields',true);
addParameter(p, 'NewMesh', false);
parse(p, varargin{:});

if ~isempty(p.Results.Store)&&(isempty(SF_core_getopt('ffdatadir'))||strcmp(SF_core_getopt('ffdatadir'),'./'))
   SF_core_log('e',' Option ''store'' is not possible here because no database folder is defined ')
end
themeshfilename = '';

% optional arguments for FreeFem
ffargument = p.Results.Options;
ffargument = SF_options2str(ffargument); % transforms into a string




% mesh
if (isstruct(p.Results.Mesh))
    SF_core_log('d', 'Mesh passed as structure');
    ffmesh = p.Results.Mesh;
    themeshfilename = ffmesh.filename;
end

% Baseflow
if (isstruct(p.Results.BaseFlow))
    SF_core_log('d', 'Baseflow passed as structure');
    bf = p.Results.BaseFlow;
    SFcore_MoveDataFiles(bf.filename,'BaseFlow.txt','cp');
    if ~exist('ffmesh','var')
        ffmesh = bf.mesh;
        themeshfilename = ffmesh.filename;
    end
end

% Initial
if (isstruct(p.Results.Init))
    SF_core_log('d', 'Starting dataset passed as structure');
    bf = p.Results.Init;
    SFcore_MoveDataFiles(bf.filename,'dnsfield_start.txt','cp'); % expected name for DNS solvers
    SFcore_MoveDataFiles(bf.filename,'BaseFlow_guess.txt','cp'); % expected name for Newton solvers
    if ~exist('ffmesh','var')
        ffmesh = bf.mesh;
        themeshfilename = ffmesh.filename;
    end
else
    SF_core_syscommand('rm',[SF_core_getopt('ffdatadir'),'/','BaseFlow_guess.txt']); % TRICK to avoid a bug
end

if exist('ffmesh','var')
    SFcore_MoveDataFiles(themeshfilename,'mesh.msh','cp');
end
% This is old method : Freefem will look for mesh.msh in the working directory (legacy)
% New method is through 'themeshfilename' passed directly to the solver
% through SF_core_freefem.
% Both methods are currently maintained...


% Forcing
if (isstruct(p.Results.Forcing))
    SF_core_log('d', 'Forcing passed as structure');
    forcing = p.Results.Forcing;
    SFcore_MoveDataFiles(forcing.filename,'Forcing.txt','cp');
end



%ffdir = SF_core_getopt('ffdir'); % to remove soon
%ffdirPRIVATE = SF_core_getopt('ffdirPRIVATE');

SF_core_log('nn', ['### Starting SF_Launch ', file]);

stringparam = [];
if (~strcmpi(p.Results.Type,'none'))
        stringparam = [p.Results.Type '  '];
end

%if ~(exist(file,'file'))
%    for ffdir =
%    if(exist([ffdir file],'file'))
%        file = [ffdir file];
%    elseif(exist([ffdirPRIVATE file],'file'))
%        file = [ffdirPRIVATE file];
%    else
%        error([' Error in SF_Launch : FreeFem++ program ' ,file, ' not found']);
%    end
%end

stringparam = ' ';
if ~isempty(p.Results.Params)
    SF_core_log('w',' Your program uses depreciated syntax ''Params'' to pass parameters ');
    SF_core_log('w',' It is advised to switch to new method using ''Options'', and modify your Freefem solvers to detect parameters using ''getARGV''  ');
    for pp = p.Results.Params
        if isnumeric(pp)
            stringparam = [stringparam, num2str(pp), '  '];
        else
            stringparam = [stringparam, pp, '  '];
        end
    end
end

%% included lines
if ~isempty(p.Results.Macros)
   Include = p.Results.Macros;
   SF_core_log('w','Please use "Include" instead of "Macros"'); % legacy
else
   Include = p.Results.Include;
end



% Launch FreeFem
value = SF_core_freefem(file,'parameters',stringparam,'arguments',ffargument,'Include',Include,'ncores',p.Results.ncores,'meshfilename',themeshfilename);




%% Post FreeFem tasks

%% Get new mesh if relevant
if p.Results.NewMesh
    SF_core_log('n',' Importing new mesh...');
    newname = SFcore_MoveDataFiles('mesh.msh','MESHES','cp');
    ffmeshNew = SFcore_ImportMesh(newname);
    ffmeshNew.problemtype = ffmesh.problemtype;
    ffmesh = ffmeshNew; 
end
    

%% get files
if iscell(p.Results.DataFile) % multiple files
   numDatafiles = min(length(p.Results.DataFile),nargout);
   theDatafiles = p.Results.DataFile;
else
    numDatafiles = 1; % single file
    theDatafiles = {p.Results.DataFile};
end

SF_core_log('nn',['processing ', num2str(numDatafiles), ' output files ']);
for ii = 1:numDatafiles
    theDatafile = theDatafiles{ii};
  if (numDatafiles>1)
    if ~exist([SF_core_getopt('ffdatadir'),theDatafile],'file')
        SF_core_log('e',' You must provide a list of datafile names using option DataFile');
    end
  else
    % A single file may be called "Data.txt" or "BaseFlow.txt" (legacy)
    if exist([SF_core_getopt('ffdatadir'),theDatafile],'file') %OK
    elseif exist([SF_core_getopt('ffdatadir'),'BaseFlow.txt'],'file')
        theDatafile = 'BaseFlow.txt';
        SF_core_log('w',['expected file ',p.Results.DataFile,' not found ; instead I found a file BaseFlow.ff2m']);
    else
        SF_core_log('e',['expected file ',p.Results.DataFile,' not found ; You must provide a datafile name using option DataFile']);
    end
  end
  SF_core_log('nn',['writing output file ',theDatafile]);
%% If requested : copy file in subfolder of database

  if ~isempty(p.Results.Store)
    if ~exist([SF_core_getopt('ffdatadir'),'/',p.Results.Store],'dir')
       SF_core_log('w',[' Folder ' SF_core_getopt('ffdatadir'),'/',...
           p.Results.Store, ' mentioned for database storing does not exist ; creating it']);
       mkdir([SF_core_getopt('ffdatadir'),'/',p.Results.Store])
    end
    SF_core_log('N',['Storing result in folder ',p.Results.Store]);

    SFcore_AddMESHFilenameToFF2M(theDatafile,ffmesh.filename);
    filename = SFcore_MoveDataFiles(theDatafile,p.Results.Store);
  else
    filename = theDatafile;
  end

% Import results

 hadError = 0;
 if ~hadError
    if p.Results.LoadFields
        if isnumeric(p.Results.Mesh)&&isnumeric(p.Results.BaseFlow)&&isnumeric(p.Results.Init)
            theData = SFcore_ImportData(filename);
        else
            theData = SFcore_ImportData(ffmesh, filename);
        end 
    else
        if isnumeric(p.Results.Mesh)&&isnumeric(p.Results.BaseFlow)&&isnumeric(p.Results.Init)
            theData = SFcore_ImportData(filename,'metadataonly');
        else
            theData = SFcore_ImportData(ffmesh, filename,'metadataonly');
        end
    end
 else
    theData = [];
 end
 varargout{ii} = theData;
end

end

function arg = argumentcell2str(cell)

if mod(length(cell),2)==1
    SF_core_log('e', 'must provide a list of pairs descriptor/value')
end

numel = length(cell)/2;
arg = ' ';
for i=1:numel
    if ~ischar(cell{2*i-1})
        SF_core_log('e','In argument : descriptors must be char type')
    end
    arg = [ arg, '-',cell{2*i-1},' '];
    if ischar(cell{2*i})||isstring(cell{2*i-1})
         arg = [ arg, cell{2*i},' '];
    elseif isnumeric(cell{2*i})
        arg = [ arg, num2str(cell{2*i}),' '];
    else
        SF_core_log('e','In argument : value must be char or numeric')
    end
end

end
