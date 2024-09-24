function [wnl, meanflow, harmonicMode1, harmonicMode2] = SF_WNL(baseflow, eigenmode, varargin)
%
% Matlab/FreeFem driver for computation of weakly nonlinear expansion
% This is part of the StabFem project, version 2.1, july 2017, D. Fabre
%
% Modified by Javier Sierra. PLEASE JAVIER UPDATE THE DOCUMENTATION !
%
% ONE-OUTPUT usage : wnl = SF_WNL(baseflow , eigenmode, {'param','value'} );
%    output is a structure with fields wnl.lambda, wnl.mu, wnl.a, etc..
%    'baseflow' should be a base-flow structure corresponding to the critical Reynolds
%     number. 'eigenmode' should be the corresponding neutral mode.
%
%  the optional parameters (couple of 'param' and 'value') may comprise :
%   'Normalization'  -> can be 'L' (lift), 'E' (energy of perturbation),
%                       'V' (velocity a one point), or 'none' (no normalization). Default is 'L'.
%   'AdjointType',   -> can be 'dA' for discrete adjoint or 'cA' for continuous adjoint (default 'dA')
%   'Retest'         -> Value of Reynolds number to generate a "guess" for the
%                     SC-HB methods (useful in three-output and four-output usage, see below)
%
% THREE-OUTPUT USAGE : [wnl,meanflow,selconsistentmode] = SF_WNL(baseflow,eigenmode,[option list])
% this will create an estimation of the meanflow and quasilinear mode, for
% instance to initiate the Self-Consistent model. Ideally the value of Retest
% should be slightly above the threshold.
%
% FOUR-OUTPUT USAGE : [wnl,meanflow,selconsistentmode,secondharmonicmode] = SF_WNL(baseflow,eigenmode,[option list])
%
% IMPLEMENTATION :
% according to parameters this generic driver will launch one of the
% following FreeFem programs :
%      WeaklyNonLinear_2D.edp
%      WeaklyNonLinear_Axi.edp
%      ( WeaklyNonLinear_BirdCall.edp : version to be abandonned)
%
% TODO : 
% * use SF_core_freefem for all case instead of old syntax.
% * problem with windows / MPI ?? -> solution use FreeFem++-mpi everywhere

ffdir = SF_core_getopt('ffdir');
ffdatadir = SF_core_getopt('ffdatadir');

p = inputParser;
addParameter(p, 'Retest', -1, @isnumeric);
addParameter(p, 'Normalization', 'L');
addParameter(p, 'AdjointType', 'dA');
addParameter(p, 'NormalForm', 'Hopf');
addParameter(p, 'symmetryBF', 'S');
addParameter(p, 'symmetryMode', 'A');
SFcore_addParameter(p, baseflow,'Re', 1, @isnumeric); % Add Reynolds
SFcore_addParameter(p, baseflow,'Ma', 0.01, @isnumeric); % Add Reynolds

addParameter(p,'ncores',1,@isnumeric);
addParameter(p, 'Adjoint','');
parse(p, varargin{:});

if ~strcmp('AdjointType', 'dA')
  SF_core_log('w', ' option "AdjointType" is no longer operational');
end

%% Position input files for FreeFem solver

%SFcore_MoveDataFiles(baseflow.filename,'BaseFlow.txt');
%SFcore_MoveDataFiles(eigenmode.filename,'Eigenmode.txt')

%if isstruct(p.Results.Adjoint)
%    SFcore_MoveDataFiles(p.Results.Adjoint.filename,'EigenmodeA.txt');
%else
    % assuming that a file 'EigenmodeA.txt' already exists... in future we
    % should treat this as an error
%    SF_core_log('nnn',' Warning in SF_WNL : better to explicitly specify an adjoint as SF_WNL(bf,em,''Adjoint'',emA,...)') 
%end

 SFcore_MoveDataFiles(baseflow.mesh.filename,'mesh.msh','cp');
 SFcore_MoveDataFiles(baseflow.filename,'BaseFlow.txt','cp');
 SFcore_MoveDataFiles(eigenmode.filename,'Eigenmode.txt','cp');
 if isstruct(p.Results.Adjoint)
    SFcore_MoveDataFiles(p.Results.Adjoint.filename,'EigenmodeA.txt','cp');
 else
    SF_core_log('e',' Error in SF_WNL : mandatory to explicitly specify an adjoint as SF_WNL(bf,em,''Adjoint'',emA,...)') ; 
 end
%% Selects the right solver

ffsolver = [];
ffarguments = [' ']; % Define arguments by default (empty) 

switch(lower(baseflow.mesh.problemtype))
    case('axixr')
        if(p.Results.NormalForm=="Hopf")
             ffsolver = 'WeaklyNonLinear_Axi.edp';
             ffparameters = [p.Results.Normalization, ' ', num2str(p.Results.Retest),];   
        end
    case({'axicompcomplex','axicompsponge'})
        if(p.Results.NormalForm=="Hopf")
         solvercommand = ['echo '  p.Results.Normalization  ' ' num2str(p.Results.Retest) ' ' num2str(p.Results.Ma) ' ' p.Results.symmetryBF ' | ' ff, ' ', ffdir, 'WeaklyNonLinear_AxiComp.edp '  ];
        end
    
    case('2d')
        if(p.Results.NormalForm=="Hopf")
            ffsolver = 'WeaklyNonLinear_2D.edp';
            ffparameters = [' '];   
            ffarguments = [p.Results.Normalization, ' ', p.Results.AdjointType, ' ', num2str(p.Results.Retest)];
            ffarguments = [ffarguments, ' -Normalisation ', p.Results.Normalization];
            ffarguments = [ffarguments, ' -Reguess ', num2str(p.Results.Retest)];
            ffarguments = [ffarguments, ' -symmetryBaseFlow ',num2str(p.Results.symmetryBF)];
            ffarguments = [ffarguments, ' -symmetry ', p.Results.symmetryMode];
            
        elseif(p.Results.NormalForm=="Hopf5Order")
            ffsolver = 'WeaklyNonLinear_2D_GH.edp';
            ffparameters = [' '];   
            ffarguments = [p.Results.Normalization, ' ', p.Results.AdjointType, ' ', num2str(p.Results.Retest)];
            ffarguments = [ffarguments, ' -Normalisation ', p.Results.Normalization];
            ffarguments = [ffarguments, ' -Reguess ', num2str(p.Results.Retest)];
            ffarguments = [ffarguments, ' -symmetryBaseFlow ',num2str(p.Results.symmetryBF)];
            ffarguments = [ffarguments, ' -symmetry ', p.Results.symmetryMode];
        elseif(p.Results.NormalForm=="SaddleNode")
            solvercommand = ['echo ', p.Results.Normalization, ' ', p.Results.AdjointType, ' ', num2str(p.Results.Retest), ' | ', ff, ' ', ffdir, 'WeaklyNonLinear_2D_SN.edp '];
        end
    case({'2dcomp','2dcompsponge'})
        if(p.Results.NormalForm=="Hopf")
            ffparameters = [p.Results.Normalization, ' ', num2str(p.Results.Retest), ' ' num2str(p.Results.Ma) ' ' p.Results.symmetryBF];   
            ffsolver = 'WeaklyNonLinear_2DComp.edp';
        end
    otherwise
        error(['Error in SF_WNL : not currently implemented for problemtype = ',baseflow.mesh.problemtype]);
end

%% Launching FF solver

% should fo this using SF_core_freefem

SF_core_log('n',['#### LAUNCHING WNL computation for Re = ',...
            num2str(p.Results.Re) ' ']);

status = SF_core_freefem(ffsolver,'parameters',ffparameters,...
                        'arguments',ffarguments);

%% Error catching

if (status==1)
    error('ERROR in SF_WNL : Freefem program failed to run  !')
elseif(status==0)

%% Importing results
    filename = SFcore_MoveDataFiles('WNL_results.ff2m','MISC','cp');
    wnl = SFcore_ImportData(baseflow.mesh,filename);
    
    if ~strcmpi(baseflow.mesh.problemtype,'2d') %% PATCH : TO CHECK WITH JAVIER
        wnl = PostProcessWNL(wnl,p.Results.Retest);
    end    
        
        
    if (nargout == 1)
        SF_core_log('n','### WNL struct');
    end

    ffmesh=baseflow.mesh;
%     expectedname = ['MeanFlow_guess.txt'];
    expectedname = ['BaseFlow.txt'];
    SFcore_AddMESHFilenameToFF2M(expectedname,ffmesh.filename);
    filename = SFcore_MoveDataFiles(expectedname,'MEANFLOWS');
    meanflow = SFcore_ImportData(ffmesh,filename);


%     expectedname = ['HBMode1_guess.txt'];
    expectedname = ['EigenmodeA.txt']; % 
    SFcore_AddMESHFilenameToFF2M(expectedname,ffmesh.filename);
    filename = SFcore_MoveDataFiles(expectedname,'EIGENMODES');
    harmonicMode1 = SFcore_ImportData(ffmesh,filename);
    
%     expectedname = ['HBMode2_guess.txt'];
    expectedname = ['Eigenmode.txt'];
    SFcore_AddMESHFilenameToFF2M(expectedname,ffmesh.filename);
    filename = SFcore_MoveDataFiles(expectedname,'EIGENMODES');
    harmonicMode2 = SFcore_ImportData(ffmesh,filename);
    
    % eventually clean working directory from temporary files
    SF_core_arborescence('cleantmpfiles') 
    
    SF_core_log('d', '### END FUNCTION SF_WNL');
end

end

function wnlOut = PostProcessWNL(wnlInit,ReGuess)

%> StabFem wrapper for PostProcessing WNL Outputs
%>
%> usage : 
%>   [wnlOut] = SF_Stability(wnlInit, [ReGuess], options)
%>
%> wnlInit : structure read from FreemFem files (WNL_.edp)
%> ReGuess  : Reynolds maximum for WNL predictions
%>
%> Output :
%> wnlOut -> structure containing the WNL field
%> 
%> List of accepted parameters (in approximate order of usefulness):
%>
%> TO BE DONE
%>  
%>
%> This program is part of the StabFem project distributed under gnu licence. 
%> Copyright J. Sierra & D. Fabre, 2017-2020.
%>
%>
% Based on the article A Practical Review on Linear and Nonlinear Global Approaches to Flow Instabilities (AMR)

vararginopt = wnlInit;

p = inputParser;
p.KeepUnmatched=true; % Allows field not defined here
% Add parameters from WNL computation
SFcore_addParameter(p, wnlInit,'Rec', 0.0, @isnumeric);
SFcore_addParameter(p, wnlInit,'omegaC', 0.0, @isnumeric);
SFcore_addParameter(p, wnlInit,'Lambda', 0.0, @isnumeric);
SFcore_addParameter(p, wnlInit,'Nu0', 0.0, @isnumeric);
SFcore_addParameter(p, wnlInit,'Nu1', 0.0, @isnumeric);
SFcore_addParameter(p, wnlInit,'Nu2', 0.0, @isnumeric);
SFcore_addParameter(p, wnlInit,'AEnergy', 0.0, @isnumeric);
SFcore_addParameter(p, wnlInit,'Fx0', 0.0, @isnumeric);
SFcore_addParameter(p, wnlInit,'Fxeps2', 0.0, @isnumeric);
SFcore_addParameter(p, wnlInit,'FxA20', 0.0, @isnumeric);
SFcore_addParameter(p, wnlInit,'FxA22', 0.0, @isnumeric);
SFcore_addParameter(p, wnlInit,'FyA1', 0.0, @isnumeric);

parse(p, vararginopt);
% Define in a readable way parameters from input
Rec = p.Results.Rec;
omegaC = p.Results.omegaC;
AEnergy = p.Results.AEnergy;
Fx0 = p.Results.Fx0;
Fxeps2 = p.Results.Fxeps2;
FxA20 = p.Results.FxA20;
FxA22 = p.Results.FxA22;
FyA1 = p.Results.FyA1;
Lambda = p.Results.Lambda; Lambdar = real(Lambda); Lambdai = imag(Lambda);
Nu0 = p.Results.Nu0;
Nu1 = p.Results.Nu1;
Nu2 = p.Results.Nu2;
Nu = [Nu0,Nu1,Nu2]; NuT = sum(Nu); NuTr = real(NuT); NuTi = imag(NuT);


%% Outputs
% Initialise field
wnlOut = wnlInit;
epsilonMax = sqrt(abs(1.0/ReGuess - 1.0/Rec)); % For debuggin proposes abs
wnlOut.ReGuess = ReGuess;
wnlOut.epsilon = linspace(0.0,epsilonMax,100);
wnlOut.AAAwnl = sqrt(abs(Lambdar/NuTr)); 
wnlOut.AAA = wnlOut.AAAwnl.*wnlOut.epsilon; 
wnlOut.Aeps = wnlOut.AAA*AEnergy; % complex (SC) - sin/cos mult by sqrt(2)
wnlOut.Fyeps = 2*wnlOut.AAA*FyA1; % Equation (30) 
wnlOut.Fxeps20 = FxA20*wnlOut.AAA.^2;
wnlOut.Fxeps22 = FxA22*wnlOut.AAA.^2;
wnlOut.omegaWNL = omegaC + Lambdai.*wnlOut.epsilon.^2 - NuTi*wnlOut.AAA.^2;
wnlOut.FyTotal = wnlOut.Fyeps; 
% Equation (29) Note: Fxeps2 includes two first terms
wnlOut.Fx0Total = Fx0 + Fxeps2.*wnlOut.epsilon.^2 + wnlOut.Fxeps20 ; 


end