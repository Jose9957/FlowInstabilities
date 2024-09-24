function ffmesh = SF_Mesh_Deform(ffmesh, varargin)
% Matlab/SF_ driver for mesh deformation  (Newton iteration)
%
% usage : ffmesh = SF_Mesh_Deform(ffmesh,'Volume',Volume,[...])
%
% this driver will lanch the "NewtonMesh" program of the coresponding
% case.
%
% Version 2.0 by D. Fabre , september 2017
%

%global ff ffdir ffdatadir sfdir verbosity
ffdatadir = SF_core_getopt('ffdatadir');

%%% MANAGEMENT OF PARAMETERS (Re, Mach, Omegax, Porosity...)

%%% check which parameters are transmitted to varargin (Mode 1)
p = inputParser;
   addParameter(p,'gamma',1,@isnumeric); % Surface tension
   addParameter(p,'rhog',0,@isnumeric); % gravity parameter
   addParameter(p,'V',-1,@isnumeric); % Volume 
   addParameter(p,'P',1,@isnumeric); % Pressure 
   addParameter(p,'typestart','pined',@ischar); % 
   addParameter(p,'typeend','pined',@ischar); % 
   addParameter(p,'GAMMABAR',0,@isnumeric);
parse(p, varargin{:});

if(p.Results.GAMMABAR~=0)
    error('ERROR : GAMMABAR (rotation) not yet fully implemented... Newton_Axi_FreeSurface_Static.edp should be revised');
end

%mycp(ffmesh.filename, [ffdatadir, 'mesh_guess.msh']); % position mesh file
SFcore_MoveDataFiles(ffmesh.filename,'mesh_guess.msh');
switch (lower(ffmesh.problemtype))
    
    case ('3dfreesurfacestatic')
        
        if(p.Results.V~=-1)% V-controled mode
            mydisp(1,'## Deforming MESH For STATIC FREE SURFACE PROBLEM (V-controled)'); 
            parameterstring = [' " V ',num2str(p.Results.V),' ',num2str(p.Results.gamma),...
                ' ',num2str(p.Results.rhog),' ',num2str(p.Results.GAMMABAR),'  ',p.Results.typestart,' ',p.Results.typeend,' " '];
            ffsolver = 'Newton_Axi_FreeSurface_Static.edp';
%            solvercommand = ['echo ',parameterstring, ' | ',ff,' ',ffdir,'Newton_Axi_FreeSurface_Static.edp'];

        elseif(p.Results.P~=-1)% P-controled mode
            mydisp(1,'## Deforming MESH For STATIC FREE SURFACE PROBLEM (P-controled)'); 
            parameterstring = [' " P ',num2str(p.Results.P),' ',num2str(p.Results.gamma),...
                ' ',num2str(p.Results.rhog),' ',num2str(p.Results.GAMMABAR),' ',p.Results.typestart,' ',p.Results.typeend,' " '];
            ffsolver = 'Newton_Axi_FreeSurface_Static.edp';
            %solvercommand = ['echo ',parameterstring, ' | ',ff,' ',ffdir,'Newton_Axi_FreeSurface_Static.edp'];
        end
        
   % case (implement other cases)
        
    otherwise
        error('case not implemented in SF_Mesh_Deform')
end


errormessage = 'ERROR : SF_BaseFlow_MoveMesh computation aborted';
%mysystem(solvercommand, errormessage); %needed to generate .ff2m file
value = SF_core_freefem(ffsolver,'parameters',parameterstring);

newname = SFcore_MoveDataFiles('mesh.msh','MESHES');
ffmeshNew = SFcore_ImportMesh(newname);

ffmeshNew.problemtype = ffmesh.problemtype;
ffmeshNew.gamma = p.Results.gamma;
ffmeshNew.rhog = p.Results.rhog;

ffmesh = ffmeshNew; %% here one should add convergence tests


mydisp(1, '#### SF_Mesh_Deform : NEW MESH CREATED');
mydisp(1, ['Volume = ', num2str(ffmesh.Vol)]);
mydisp(1, ['P0 = ', num2str(ffmesh.P0)]);

end