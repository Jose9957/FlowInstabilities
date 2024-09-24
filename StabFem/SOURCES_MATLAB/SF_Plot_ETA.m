function h = SF_Plot_ETA(eigenmode,varargin)
%
% This functions adds to the current plot a representation of the
% free-surface displacement ETA.
%
% Usage 
% SF_Plot(em,[...])
%
% (may be used just after "SF_Plot(em,[...]); hold on;" to superpose with a color level plot)
%
% Optional argumengents : 
%  'Amp'          : amplitude to rescale the deformation (if complex, will take the real part of E*eta)
%  'style'      : color and/or symbol to use
%  'LineWidth'  : line width,
%  'projection' : 'n' (normal displacement),  'r' (radial displacement deduced from the normal one) 
%                 'z' (vertical displacement deduced from the normal one),
%                 'nt' (displacement specified by normal and tangential component), 
%                 'xy' (displacement specified by x and y components). 
%  'symmmetry'  : 'N' (n symmetry) | 'S' (symmetric) | 'A' (antisymmetric) 
%  'dim'        : '2D' (default) or '3D' to draw a 3D surface (may not work in all cases).
%

if isfield(eigenmode,'status')&&strcmp(eigenmode.status,'unloaded')
    eigenmode = SF_LoadFields(eigenmode);
    SF_core_log('n',[' Loading dataset from file ', eigenmode.filename ' because not previously loaded']);
    SF_core_log('n','to do this permanently : use SF_LoadFields (see documentation or help SF_LoadFields)')
    eigenmode.status = 'loaded';
end

p = inputParser;
addParameter(p,'dim','2D');
addParameter(p,'Amp',.15,@isnumeric);
addParameter(p,'style','r',@ischar); % style for plots (e.g. color)
addParameter(p,'LineWidth',2,@isnumeric); % Linewidth
addParameter(p,'projection','n',@ischar); % projection : 'n' | 'r' | 'z'
addParameter(p,'symmetry','no',@ischar); % symmetry condition. 
                                         % available values are 'no', 
                                         % 'YS' (symmetric with respect to Y axis)
                                         % 'YA' (antisymmetric with respect to Y axis) 
parse(p,varargin{:});

E = p.Results.Amp;
ffmesh = eigenmode.mesh;

if isfield(ffmesh,'meshlin')&&isfield(ffmesh.meshlin,'rsurf')
    xsurf = ffmesh.meshlin.rsurf; 
    ysurf = ffmesh.meshlin.zsurf;
    N0x = ffmesh.meshlin.N0r;
    N0y = ffmesh.meshlin.N0z;
elseif isfield(ffmesh,'meshlin')&&isfield(ffmesh.meshlin,'xsurf')
    xsurf = ffmesh.meshlin.xsurf; 
    ysurf = ffmesh.meshlin.ysurf;
    N0x = ffmesh.meshlin.N0x;
    N0y = ffmesh.meshlin.N0y;
elseif isfield(ffmesh,'rsurf')
    xsurf = ffmesh.rsurf; 
    ysurf = ffmesh.zsurf;
    N0x = ffmesh.N0r;
    N0y = ffmesh.N0z;
elseif isfield(ffmesh,'xsurf')
    xsurf = ffmesh.xsurf; 
    ysurf = ffmesh.ysurf;
    N0x = ffmesh.N0x;
    N0y = ffmesh.N0y;    
else
    SF_core_log('e','Error : could not find xsurf/ysurf/N0x/N0y arrays')
end

if strcmpi(p.Results.dim,'2D')
% 2D plot
    
switch(p.Results.projection)
    case('n')
        if(~isfield(eigenmode,'eta'))
            SF_core_log('w',' No field eta. Probably you shoud use option ''Projection'',''nt'' ');
        end
    h = plot(xsurf+real(E*eigenmode.eta).*N0x,ysurf+real(E*eigenmode.eta).*N0y,p.Results.style,'LineWidth',p.Results.LineWidth);
    case({'r','x'})
    h = plot(xsurf+real(E*eigenmode.eta)./N0x,ysurf,p.Results.style,'LineWidth',p.Results.LineWidth);
    case({'z','y'})
    h = plot(xsurf,ysurf+real(E*eigenmode.eta)./N0y,p.Results.style,'LineWidth',p.Results.LineWidth);
    case({'nt'})
    h = plot(xsurf+real(E*(eigenmode.etan.*N0x+eigenmode.etat.*N0y)),ysurf+real(E*(eigenmode.etan.*N0y-eigenmode.etat.*N0x)),p.Results.style,'LineWidth',p.Results.LineWidth);     
end
        


switch p.Results.symmetry
    case('no')
        mydisp(15,'No symmetry');
    case('YS')
        eigenmodeSYM = eigenmode;
         if isfield(eigenmodeSYM.mesh,'meshlin')
            eigenmodeSYM.mesh.meshlin.rsurf = - eigenmodeSYM.mesh.meshlin.rsurf;
        else
            eigenmodeSYM.mesh.rsurf = - eigenmodeSYM.mesh.rsurf;
        end
        hold on; 
        SF_Plot_ETA(eigenmodeSYM,varargin{:},'symmetry','no');
        %
        %hold on; 
        %h1 = plot(-ffmesh.rsurf-real(E*eigenmode.eta).*ffmesh.N0r,ffmesh.zsurf+real(E*eigenmode.eta).*ffmesh.N0z,p.Results.style,'LineWidth',p.Results.LineWidth);
        %h = [h; h1];
    case('YA')
        %hold on; 
        %h1 = plot(-ffmesh.rsurf+real(E*eigenmode.eta).*ffmesh.N0r,ffmesh.zsurf-real(E*eigenmode.eta).*ffmesh.N0z,p.Results.style,'LineWidth',p.Results.LineWidth);
        %h = [h; h1];
        eigenmodeSYM = eigenmode;
        if isfield(eigenmodeSYM.mesh,'meshlin')
            eigenmodeSYM.mesh.meshlin.rsurf = - eigenmodeSYM.mesh.meshlin.rsurf;
        else
            eigenmodeSYM.mesh.rsurf = - eigenmodeSYM.mesh.rsurf;
        end
        eigenmodeSYM.eta = - eigenmodeSYM.eta;
        hold on; 
        SF_Plot_ETA(eigenmodeSYM,varargin{:},'symmetry','no');
end


if isfield(eigenmode,'ksi')
    hold on;
    plot(eigenmode.Xplate,real(E*eigenmode.ksi),'b-')
end


else
% 3D plot

nphi = 40;
for k=1:nphi+1
    phik = 2*pi*k/nphi;
    Rsurf = xsurf+real(E*exp(1i*eigenmode.m*phik)*eigenmode.eta).*N0x;
    Xsurf(k,:) = Rsurf*cos(phik);
    Ysurf(k,:) = Rsurf*sin(phik);    
    Zsurf(k,:) = ysurf+real(E*exp(1i*eigenmode.m*phik)*eigenmode.eta).*N0y;
    Csurf(k,:) = real(E*exp(1i*eigenmode.m*phik)*eigenmode.eta);
end

surf(Xsurf,Ysurf,Zsurf,Csurf);


end
