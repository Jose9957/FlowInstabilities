function ffmesh = SF_Mesh_Deform(ffmesh, varargin)
% Matlab/SF_ driver for Base flow calculation (Newton iteration)
%
% usage : ffmesh = SF_Mesh_Deform(ffmesh,'Volume',Volume,[...])
%
% this driver will lanch the "NewtonMesh" program of the coresponding
% case.
%
% Version 2.0 by D. Fabre , september 2017
%

global ff ffdir ffdatadir sfdir verbosity

%%% MANAGEMENT OF PARAMETERS (Re, Mach, Omegax, Porosity...)

%%% check which parameters are transmitted to varargin (Mode 1)
p = inputParser;

addParameter(p, 'gamma', 1, @isnumeric); % Surface tension
addParameter(p, 'rhog', 0, @isnumeric); % gravity parameter
addParameter(p, 'V', -1, @isnumeric); % Volume (for liquid bridge)
addParameter(p, 'P', -1, @isnumeric); % Pressure (for liquid bridge)

parse(p, varargin{:});

switch (baseflow.mesh.problemtype)
    
    case ('3DFreeSurfaceStatic')
        
        if (p.Results.V ~= -1) % V-controled mode
            mydisp(1, '## solving base flow (ACTUALLY ONLY MESH) For STATIC FREE SURFACE PROBLEM (V-controled)');
            parameterstring = [' " V ', num2str(p.Results.V), ' ', num2str(p.Results.gamma), ' ', num2str(p.Results.rhog), ' " '];
            solvercommand = ['echo ', parameterstring, ' | ', ff, ' ', ffdir, 'Newton_Axi_FreeSurface_Static.edp'];
        elseif (p.Results.P ~= -1) % P-controled mode
            mydisp(1, '## solving base flow (ACTUALLY ONLY MESH) For STATIC FREE SURFACE PROBLEM (P-controled)');
            parameterstring = [' " P ', num2str(p.Results.P), ' ', num2str(p.Results.gamma), ' ', num2str(p.Results.rhog), ' " '];
            solvercommand = ['echo ', parameterstring, ' | ', ff, ' ', ffdir, 'Newton_Axi_FreeSurface_Static.edp'];
        end
end


error = 'ERROR : SF_BaseFlow_MoveMesh computation aborted';
mysystem(solvercommand, error); %needed to generate .ff2m file

if (exist([ffdatadir, 'BaseFlow.txt']) ~= 2)
    error('ERROR in SF_BaseFlow_MoveMesh : Newton did not converge');
end


meshNEW = importFFmesh('mesh.msh');
baseflowNEW = importFFdata(meshNEW, 'BaseFlow.ff2m');

baseflow = baseflowNEW;

mydisp(1, '#### SF_BaseFlow_FreeSurface : NEW MESH CREATED');
mydisp(1, ['Volume = ', num2str(baseflow.mesh.Vol)]);
mydisp(1, ['P0 = ', num2str(baseflow.mesh.P0)]);


end