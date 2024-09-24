function baseflow = SF_BFContinue(varargin)
ffdatadir = SF_core_getopt('ffdatadir');
%>
%> function SF_BFContinue
%>
%> Generic driver for computation of a base flow using arclength
%> continuation in the plane of parameters (alpha,beta)
%> here alpha is a and beta is a monitor (both defined by macros).
%> For correct operation bf must possess fields 'tangent1' and 'tangent2'
%> corresponidng to d alpha / d s and d beta / d s
%> 
%>
%> usage :
%> bf = SF_BFContinue(bf,'step',step,[...])
%>
%> 'step'       : required step in arclength direction.
%> 'solver'     : freefem++ solver (when using generic interface)
%> 'Options'    : string of numerical parameters recognized by gatARGV 
%> 
%> The driver will launch a FreeFem solver, either the one specified as input (generic interface) 
%> or the default one for this class of problems (if a 'problemtype' has been defined while creating mesh)

%% Read parameters
baseflow = varargin{1}(end);
ffmesh = baseflow.mesh;
vararginopt = {varargin{2:end}};

p = inputParser;
addParameter(p, 'step', 0.01);
addParameter(p, 'param', 'Re');

addParameter(p, 'Options', '');
addParameter(p, 'solver', 'default');

parse(p, vararginopt{:});

% Rename variables for easy access
param = p.Results.param;
step = p.Results.step;
Re = baseflow.Re;



if(isfield(baseflow,'tangent1'))
    tangent1 = baseflow.tangent1;
else
    tangent1 = 0.;
end

if(isfield(baseflow,'tangent2'))
    tangent2 = baseflow.tangent2;
else
    tangent2 = 1.;
end

if(isfield(baseflow,'Ma'))
    Mach = baseflow.Ma
end

if(isfield(baseflow,'Omegax'))
    Omegax = baseflow.Omegax;
else
    Omegax = 0;
end


if isfield(baseflow,'solver')
    % trick to allow recomputation after adapt
    newtonsolver = baseflow.solver;
else
    newtonsolver = '';
end

%%% Position input files

if (strcmpi(baseflow.datatype,'baseflow')||strcmpi(baseflow.datatype,'addition'))
    SF_core_log('n',['Computing base flow for Re = ', num2str(Re), '  starting from guess']);
    SFcore_MoveDataFiles(baseflow.filename,'BaseFlow_guess.txt','cp');
    SFcore_MoveDataFiles(baseflow.mesh.filename,'mesh.msh','cp');
    mesh = baseflow.mesh;
    problemtype = baseflow.mesh.problemtype;
elseif (strcmpi(baseflow.datatype,'mesh'))
    SF_core_log('n', ['Computing base flow for Re = ', num2str(Re), 'starting from guess']);
    mymyrm('BaseFlow_guess.txt'); % To be modified soon
    problemtype = baseflow.problemtype;
    mesh = baseflow;
    SFcore_MoveDataFiles(mesh.filename,'mesh.msh','cp');
    % imported meshes do not work
else
    error('wrong type of argument to SF_BaseFlow')
end

ffarguments = p.Results.Options;
% to be done better
if isfield(baseflow,'U1')
    ffarguments = [ffarguments , ' -U1 ',num2str(baseflow.U1)];
end
if isfield(baseflow,'U2')
    ffarguments = [ffarguments , ' -U2 ',num2str(baseflow.U2)];
end
if isfield(baseflow,'bctype')
    ffarguments = [ffarguments , ' -bctype ',num2str(baseflow.bctype)];
end
    


%% Launch FreeFem codes
SF_core_log('n', ['FUNCTION SF_BFContinue : computing baseflow with pseudo arclength, step = ',num2str(step)]);

switch (lower(baseflow.mesh.problemtype))
    
    case('unspecified')
        SF_core_log('n', '## Entering SF_BFContinue (GENERIC DRIVER)');
        ffparams = [ num2str(step), ' ', num2str(tangent1), ' ', num2str(tangent2)];
        ffarguments = [ffarguments ' -Symmetry ' ,baseflow.mesh.symmetry];
        ffsolver = p.Results.solver;
        
    case('2d')
        % Determination of sign of predictor tangents
        SF_core_log('n', '## Entering SF_BFContinue (2D INCOMPRESSIBLE)');
        ffparams = [ num2str(step), ' ', num2str(tangent1), ' ', num2str(tangent2)];
        ffarguments = [ffarguments ' -Symmetry ' ,baseflow.mesh.symmetry];
        if isfield(baseflow,'Omegax')
            ffarguments = [ffarguments ' -Omegax ',num2str(baseflow.Omegax) ];
        end
        ffsolver = 'ArcLengthContinuation2D.edp';
        %ffbin = 'FreeFem++'; % (other option is FreeFem++-mpi ; specified if required)
        BFfilename = [ffdatadir, 'BASEFLOWS/BaseFlow_ArcLength'];
    case('axixr')
        % Determination of sign of predictor tangents
        SF_core_log('n', '## Entering SF_BFContinue (Axi INCOMPRESSIBLE)');
        ffparams = [ num2str(step), ' ', num2str(tangent1), ' ', num2str(tangent2)];
        ffsolver = 'ArcLengthContinuationAxi.edp';
        %ffbin = 'FreeFem++'; % (other option is FreeFem++-mpi ; specified if required)
        BFfilename = [ffdatadir, 'BASEFLOWS/BaseFlow_ArcLength'];
    case('2dcomp')
        % Determination of sign of predictor tangents
        SF_core_log('n', '## Entering SF_BFContinue (2D COMPRESSIBLE)');
        ffparams = [ num2str(step), ' ', num2str(tangent1), ' ', num2str(tangent2), ' ', baseflow.mesh.symmetry];
        ffsolver = 'ArcLengthContinuation2D_Comp.edp';
  % case("your case...")
        % add your case here !
    otherwise
        SF_core_log('e',['Error in SF_BFContinue : your case ', baseflow.mesh.problemtype 'is not yet implemented....'])    
end

if ~strcmpi(baseflow.mesh.problemtype,'unspecified')&&~strcmpi(p.Results.solver,'default')
    ffsolver = p.Results.solver;
    SF_core_log('n',['Using specified solver ',ffsolver]);
end
    
    

value = SF_core_freefem(ffsolver,'parameters',ffparams,'arguments',ffarguments);
    
if (value>0)
   SF_core_log('w','SF_BFcontinue computation did not converge');
   baseflow.iter = -1;
   return;
end

%% Import data to Matlab

% add mesh filename into .ff2m file
SFcore_AddMESHFilenameToFF2M('BaseFlow.ff2m',mesh.filename); 

% Copy in the proper directory
filename = SFcore_MoveDataFiles([ffdatadir, 'BaseFlow.txt'],'BASEFLOWS');

% Then imports
baseflow = SFcore_ImportData(filename);

if ~isempty(newtonsolver)
    % trick for recomputation after adapt
    baseflow.solver = newtonsolver;
end

%% Log

if (baseflow.iter >= 1)
    message = ['=> Base flow converged in ', num2str(baseflow.iter), ' iterations '];
    if (isfield(baseflow, 'Fx') == 1) %% adding drag information for blunt-body wake
        message = [message, '; Fx = ', num2str(baseflow.Fx)];
    end
    if (isfield(baseflow, 'Lx') == 1) %% adding drag information for blunt-body wake
        message = [message, '; Lx = ', num2str(baseflow.Lx)];
    end
    if (isfield(baseflow, 'deltaP0') == 1) %% adding pressure drop information for jet flow
        message = [message, '; deltaP0 = ', num2str(baseflow.deltaP0)];
    end
    SF_core_log('n', message);
else
    SF_core_log('w', ['      ### Base flow diverged ! recovered from previous computation for Re = ', num2str(Re)]);
end

SF_core_log('d', '### END FUNCTION SF_BASEFLOW ');
end


