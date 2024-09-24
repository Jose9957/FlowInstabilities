function handle = SF_Plot(FFdata, varargin)
%>  function SF_Plot
%>  plots a data field imported from freefem.
%>  This function is part of the StabFem project by D. Fabre & coworkers.
%>
%>   This version of SF_Plot is based on ffpdeplot developed by chloros2
%>   as an Octave-compatible alternative to pdeplot from toolbox pdetools
%>   (https://github.com/samplemaker/freefem_matlab_octave_plot)
%>
%>
%>  Usage :
%>  1/  handle=SF_Plot(ffdata,'mesh'[,PARAM,VALUE,..]);
%>           To plot a mesh
%>  2/  handle=SF_Plot(ffdata,'field'[,PARAM,VALUE,..]);
%>           To plot color levels of a P1 or P2 field specified by its name
%>                  (e.g. 'ux' for axial velocity component)
%>  3/ handle=SF_Plot(ffdata,'field','contour','only'[,PARAM,VALUE,..] );
%>           To plot contour levels (no color scale).
%>              (This way is useful after 'hold on' to superpose onto color levels)
%>  4/ handle=SF_Plot(ffdata,{'field1','field2'} [,PARAM,VALUE,..] );
%>           To plot quiver plots (vector field with two components)
%>
%> Alternative (advanced) usage :
%>  2b/ handle=SF_Plot(ffdata,'field.re'[,PARAM,VALUE,..] );
%>           To plot color levels of a complex field (specify '.re' or '.im')
%>  2c/ handle=SF_Plot(ffdata,data,[,PARAM,VALUE,..] );
%>           To plot isocontours of a field transmitted as a vector (dimension must be consistent)
%>
%>  (NB :  4/ handle=SF_Plot(mesh) also works as an alternative syntax to 1/ but his syntax is not recommended anymore)
%>
%>  FFdata is the structure containing the data to plot
%>       a valid 'dataset' structure is expected (with a mesh as a field of this structure)
%>       but a 'mesh' structure can also be tranmitted directly.
%>
%>   [PARAM,VALUE] are any couple of name/value parameter accepted by
%>   ffpdeplot.
%>
%>   The list of accepted parameters are the same as accepted by ffpdeplot,
%>   plus two specific ones : 'symmmetry' and 'logsat'.
%>   NB : parameter 'colomap' accepts  a few custom ones including 'redblue' and 'ice'.
%>
%>   Here is the list of parameters accepted by ffpdeplot :
%>
%>      Parameter       Value
%>      'XYStyle'      Coloring choice
%>                        'interp' (default) | 'off'
%>      'ZStyle'       Draws 3D surface plot instead of flat 2D Map plot
%>                        'continuous' | 'off' (default)
%>      'ColorMap'     ColorMap value or matrix of such values
%>                        'off' | 'cool' (default) | colormap name | three-column matrix of RGB triplets.
%>                     NB in addition to the default colormaps ('cool','parula',...) 
%>                        a number of custom ones are available :
%>                        'viridis','redblue','french','ice','fire','seashore','dawn' .
%>      'ColorBar'     Indicator in order to include a colorbar
%>                        'on' (default) | 'off' | 'northoutside' ...
%>      'CBTitle'      Colorbar Title
%>                        (default=[])
%>      'ColorRange'   Range of values to adjust the colormap thresholds
%>                        'off' | 'minmax' (default) | 'centered' | 'cropminmax' | 'cropcentered' | [min,max]
%>      'Mesh'         Switches the mesh off / on
%>                        'on' | 'off' (default)
%>      'MColor'       Color to colorize the mesh
%>                        'auto' (default) | RGB triplet | 'r' | 'g' | 'b'
%>      'RLabels'      Meshplot of specified regions
%>                        [] (default) | [region1,region2,...]
%>      'RColors'      Colorize regions with a specific color (linked to 'RLabels')
%>                        'b' (default) | three-column matrix of RGB triplets
%>      'Boundary'     Shows the domain boundary / edges
%>                        'on' | 'off' (default)
%>      'BDLabels'     Draws boundary / edges with a specific label
%>                        [] (default) | [label1,label2,...]
%>      'BDColors'     Colorize boundary / edges with a specific color (linked to 'BDLabels')
%>                        'r' (default) | three-column matrix of RGB triplets
%>      'BDShowText'   Shows the labelnumber on the boundary / edges
%>                        'on' | 'off' (default)
%>      'BDTextSize'   Size of labelnumbers on the boundary / edges
%>                        scalar value greater than zero
%>      'BDTextWeight' Character thickness of labelnumbers on the boundary / edges
%>                        'normal' (default) | 'bold'
%>      'Contour'      Isovalue plot
%>                        'off' (default) | 'on'
%>      'CStyle'       Contour plot style
%>                        'solid' (default) | 'dashed' | 'dashedneg'
%>      'CColor'       Isovalue color (can be monochrome or flat)
%>                        'flat' | [0,0,0] (default) | RGB triplet, three-element row vector | 'r' | 'g' | 'b'
%>      'CLevels'      Number of isovalues used in the contour plot
%>                        (default=10)
%>      'CGridParam'   Number of grid points used for the contour plot
%>                        'auto' (default) | [N,M]
%>      'Title'        Title
%>                        (default=[])
%>      'XLim'         Range for the x-axis
%>                        'minmax' (default) | [min,max]
%>      'YLim'         Range for the y-axis
%>                        'minmax' (default) | [min,max]
%>      'ZLim'         Range for the z-axis
%>                        'minmax' (default) | [min,max]
%>      'DAspect'      Data unit length of the xy- and z-axes
%>                        'off' | 'xyequal' (default) | [ux,uy,uz]
%>      'FlowData'     Data for quiver plot
%>                        FreeFem++ point data | FreeFem++ triangle data
%>      'FColor'       Color to colorize the quiver arrows
%>                        'b' (default) | RGB triplet | 'r' | 'g'
%>      'FGridParam'   Number of grid points used for quiver plot
%>                        'auto' (default) | [N,M]
%>      'XYData'       PDE data used to create the plot
%>                        (see documentation of ffpdeplot)
%>      'VhSeq'        Finite element connectivity
%>                        (see documentation of ffpdeplot)
%>
%> ADDITIAL PARAMETERS NOT RECOGNIZED BY FFPDEPLOT :
%>
%>       'Amp'       Amplitude rescaling of the quantity to plot 
%>                   (possibly complex, if so we will plot Re( Amp * field )
%>       'Deform'    Deformation of the mesh (for cases involving ALE).
%>                   Expected value is an amplitude (possibly complex).
%>                   The mesh will be deformed by applying a deformation Amp * xi (real part if complex)
%>       'symmetry'  symmetry property of the flow to plot
%>                       'no' (default) | 'YS' (symmetric w.r.t. Y axis) | 'YA' (antisymmetric w.r.t. Y axis) | 'XS' | 'XA'
%>                                      | 'XM' (mirror image w/r to X axis) | 'YM'
%>       'logsat'    use nonlinearly scaled colorange using filter function f_S
%>                   colorange is linear when |value|<S and turns into logarithmic when |value|>S
%>                   (use this option to plot fields with strong spatial amplifications)
%>                   NB : is S = 0 the colorrange is purely logarithmic
%>                   -1 (default, disabled) | S
%>     Notes :


if length(FFdata)>1||~isstruct(FFdata)
    SF_core_log('e','Wrong type of argument for SF_Plot : you must specify a single dataset');
end


%% Load all fields if not previously loaded
if isfield(FFdata,'status')&&strcmp(FFdata.status,'unloaded')
    FFdata = SF_LoadFields(FFdata);
    SF_core_log('n',[' Loading dataset from file ', FFdata.filename ' because not previously loaded']);
    SF_core_log('n','to do this permanently : use SF_LoadFields (see documentation or help SF_LoadFields)')
    FFdata.status = 'loaded';
end


%% Tweaks a number of parameters which are not directly recognized by ffpdeplot
verbosity = SF_core_getopt('verbosity');

% first check if 'colormap' is a custom one
%   (a few customs are defined at the bottom of this function)
for i=1:length(varargin)-1
    if(strcmpi(varargin{i},'colormap'))
        cmprovided = 1;
        if ischar(varargin{i+1})
        switch(lower(varargin{i+1}))
            case('viridis')
                varargin{i+1} = viridis();
            case('redblue')
                varargin{i+1} = redblue(); % defined at the bottom
            case('french')
                varargin{i+1} = french();
            case('ice')
                varargin{i+1} = ice();
            case('fire')
                varargin{i+1} = fire();
            case('seashore')
                varargin{i+1} = seashore();
            case('dawn')
                varargin{i+1} = dawn();
                %otherwise varargin{i+1} should be a standard colormap
        end
        end
    end
end
if ~exist('cmprovided','var')
        varargin = [varargin, {'colormap', viridis()} ];
        %varargin = [varargin, {'colormap', 'viridis'} ]; when this will be default in Matlab...
end


% check if 'contour' is part of the parameters and recovers its value
contourval='off';
for i=1:length(varargin)-1
    if(strcmp(varargin{i},'contour'))
        icontour = i;
        contourval = varargin{i+1};
    end
end

% check if 'xystyle' is part of the parameters and recovers it
xystyle = 'on';
for i=1:length(varargin)-1
    if(strcmp(varargin{i},'xystyle'))
        xystyle = varargin{i+1};
    end
end
if (strcmpi(xystyle,'off')==1)
    varargin = [varargin, {'colorrange','off','colorbar','off','colormap','off'}];
end

% check if 'symmetry' is part of the parameters and recovers it
symmetry = 'no';
for i=1:length(varargin)-1
    if(strcmp(varargin{i},'symmetry'))
        isymmetry = i;
        symmetry = varargin{i+1};
    end
end
if (strcmp(symmetry,'no')~=1)
    varargin = { varargin{1:isymmetry-1} ,varargin{isymmetry+2:end}} ;
    if(strcmpi(symmetry,'ya')||strcmpi(symmetry,'xa'))
        varargin = [ varargin 'colorrange','cropcenter'];
    end
end

% check if 'logsat' is part of the parameters and recovers it
logscaleS = -1;
for i=1:length(varargin)
    if(strcmp(varargin{i},'logsat'))
        ilogscale = i;
        logscaleS = varargin{i+1};
        SF_core_log('nnn',['using colorrange with logarithmic saturation ; S = ',num2str(logscaleS)]);
    end
end
if (logscaleS~=-1)
    varargin = { varargin{1:ilogscale-1} ,varargin{ilogscale+2:end}} ;
end

% check if 'amp' is part of the parameters and recovers it
iAmpplot = 0;Ampplot = 1;
for i=1:length(varargin)-1
    if(strcmpi(varargin{i},'amp'))
        iAmpplot = i;
        Ampplot = varargin{i+1};
        SF_core_log('nnn',['using amplitude ; A = ',num2str(Ampplot)]);
    end
end
if (iAmpplot~=0)
    varargin = { varargin{1:iAmpplot-1} ,varargin{iAmpplot+2:end}} ;
end

% check if 'Deform' is part of the parameters and tweak this parameter for ffpdeplot
for i=1:length(varargin)-1
    if(strcmpi(varargin{i},'Deform'))
        DEFDEF = varargin{i+1};
        if iscell(DEFDEF)
            SF_core_log('d','Plotting deformed field as a cell array ; providing components');
        else
            SF_core_log('d','Plotting deformed field as a cell array ; providing amplitude');
            if isfield(FFdata,'xix')&&isfield(FFdata,'xiy')
                varargin{i+1} = { DEFDEF*FFdata.xix, DEFDEF*FFdata.xiy};
            elseif isfield(FFdata,'xir')&&isfield(FFdata,'xiz')
                varargin{i+1} = { DEFDEF*FFdata.xir, DEFDEF*FFdata.xiz};
            else
                SF_core_log('e',' Plotting deformed mesh not possible, you data should have fields xir,xiz or xix,xiy');
            end
        end
    end
end




if (mod(nargin, 2) == 1)
    %% plot mesh only in single-entry mode
    % (not recommended any more but kept for legacy)
    varargin = [{'mesh'}, varargin];
    SF_Plot(FFdata,varargin{:});
    else
    %% New method : 
    % plot in double-entry mode : first parameter is a dataset, second parameter can be :
    %   a/ the name of a field (for contour plots)
    %   b/ a cell-array with two names (for quiver plots)
    %   c/ the keyword 'mesh' (to plot the mesh)
    
     %% prepares to invoke ffpdeplot : check mesh 
    if strcmpi(FFdata.datatype,'mesh')
        mesh = FFdata;
    elseif isfield(FFdata,'mesh')
        mesh = FFdata.mesh;
    else
        SF_core_log('w',' NO MESH SPECIFIED FOR READING THIS DATA FILE')
        SF_core_log('w',' ASSUMING THE DATASET IS ASSOCIATED TO LAST MESH')
        mesh = SF_Load('MESH','last');
    end
    
    % xlim and ylim may be defined in the mesh (obsolete method)
    field1 = varargin{1};
    varargin = {varargin{2:end}};
    if(isfield(mesh,'xlim'))
        varargin = {varargin{:}, 'xlim', mesh.xlim};
    end
    if(isfield(mesh,'ylim'))
        varargin = [varargin, {'ylim', mesh.ylim}];
    end
    
    
    if (~iscell(field1)==1&&strcmpi(field1, 'mesh'))
        %% plot mesh 
        varargin = [varargin, {'mesh', 'on'}];
        
        SF_core_log('dd', ['launching ffpeplot with the following options :']);
        if (verbosity >= 7)
            varargin
        end
        if(strcmpi(symmetry,'xm'))
            mesh.points(2,:) = -mesh.points(2,:);
            symmetry = 'no';
        elseif(strcmpi(symmetry,'ym'))
            mesh.points(1,:) = -mesh.points(1,:);
            symmetry ='no';
        end
        
        handle = ffpdeplot(mesh.points, mesh.bounds, mesh.tri, varargin{:});
        
    else
        %% first prepare data
        if(~iscell(field1))
            %% case for contour plots
            if (~isnumeric(field1))
                % check if data to plot is the name of a field or a numerical dataset
                [~, field, suffix] = fileparts(field1); % to extract the suffix
                if ~isfield(FFdata,field)
                    SF_core_log('w',[' Error in SF_Plot : Field ',field, ' does not exist']);
                    return
                end
                if (strcmp(suffix, '.im') == 1)
                    data = imag(Ampplot*FFdata.(field));
                else
                    data = real(Ampplot*FFdata.(field));
                end
            else
                data = field1;
            end
            if (logscaleS~=-1)
                varargin = [varargin, {'ColorRangeTicks', logscaleS } ];
                data = logfilter(data,logscaleS);
            end
            
            varargin = [ {'xydata', data}, varargin];
            
        else
            %% case for quiver plots
            data = real(Ampplot*FFdata.(field1{1}));
            data2 = real(Ampplot*FFdata.(field1{2}));
            varargin = [{'flowdata', [data,data2]}, varargin];
        end
        
        %% a few tweaks
        if ~strcmpi(contourval,'off')&&~strcmpi(contourval,'on')&&~strcmpi(contourval,'only')
            SF_core_log('e','this way of plotting contour levels is not possible any more !');
            varargin{icontour} = 'on';
            [~, field, suffix] = fileparts(contourval); % to extract the suffix
            if (strcmp(suffix, '.im') == 1)
                xydata = imag(FFdata.(field));
            else
                xydata = real(FFdata.(field));
            end
            varargin = [ varargin , {'cxydata',xydata } ];
        end
        
        
        SF_core_log('dd', 'launching ffpeplot with the following options :');
        if (verbosity >= 7)
            varargin
        end
        
        % for symmetryzing plot
        pointsS = mesh.points;
        if(strcmpi(symmetry,'xm'))
            pointsS(2,:) = -pointsS(2,:);
            symmetry = 'no';
        elseif(strcmpi(symmetry,'ym'))
            pointsS(1,:) = -pointsS(1,:);
            symmetry ='no';
        end
        
        %% preparing VhSeq according to data type
        if(length(data)==mesh.nt)
            SF_core_log('d','plotting P0 field');
            varargin{2} = repelem(varargin{2},3);
            varargin= [varargin, {'VhSeq',  (0 : 3*mesh.nt-1) } ];
        elseif(length(data)==mesh.np)
            SF_core_log('d','plotting P1 field');
            varargin=[varargin, { 'VhSeq', reshape(mesh.tri(1:3,:),size(mesh.tri,2)*3,1)-1} ];
        elseif(length(data)==3*mesh.nt)
            SF_core_log('d','plotting P1 field (from vectorized data)');
            varargin=[varargin, { 'VhSeq', (0 : 3*mesh.nt-1) } ]; % [0 3*mesh.nt-1]
        elseif isfield(mesh,'np2')&&(length(data)==mesh.np2)
            SF_core_log('d','plotting P2 field');
            varargin=[varargin, { 'VhSeq', mesh.Vh_P2} ];
        elseif(length(data)==6*mesh.nt)
            SF_core_log('d','plotting P2 field (from vectorized data)');
            varargin=[varargin, { 'VhSeq', (0 : 6*mesh.nt-1) } ]; % replace by % [0 6*mesh.nt-1]
        elseif isfield(mesh,'np1b')&&(length(data)==mesh.np1b)
            SF_core_log('d','plotting P1b field');
            varargin=[varargin, { 'VhSeq', mesh.Vh_P1b} ];
        elseif(length(data)==4*mesh.nt)
            SF_core_log('d','plotting P1b field (from vectorized data)');
            varargin=[varargin, { 'VhSeq', (0 : 4*mesh.nt-1) } ]; % replace by % [0 4*mesh.nt-1]
        else
            disp('np, np2 , nt, ndata');
            mesh.np
            mesh.np2
            mesh.nt
            length(data)
            error('Error : data size does not fit with P1, P2, P1b dimensions')
        end
        
        
        %% Now plotting !
        
        
        handle = ffpdeplot(pointsS, mesh.bounds, mesh.tri,  varargin{:});
        
        %% SYMMETRIZATION OF THE PLOT
        if(strcmp(symmetry,'no'))
            SF_core_log('nnn','No symmetry');
        else
            SF_core_log('nnn',['Symmetrizing the plot with option ',symmetry]);
            pointsS = mesh.points;
            switch(symmetry)
                case('XS')
                    pointsS(2,:) = -pointsS(2,:);dataS = data;
                case('XA')
                    pointsS(2,:) = -pointsS(2,:);dataS = -data;
                case('YS')
                    pointsS(1,:) = -pointsS(1,:);dataS = data;
                case('YA')
                    pointsS(1,:) = -pointsS(1,:);dataS = -data;
                case({'XM','YM'})
                    % do nothing as these case has already been treated
                otherwise
                    error(' Error in SF_Plot with option symmetry ; value must be XS,XA,YS,YA,XM,YM or no')
            end
            
            hold on;
            handle = ffpdeplot(pointsS, mesh.bounds, mesh.tri, varargin{:},'xydata', dataS);
            hold off;
        end
    end
end

end




% custom colormaps for StabFem
function cmap = redblue()
%colmapdef=[193,0,0; 235,164,164; 235,235,235; 196,196,255; 127,127,255]/255;
colmapdef=[127,127,255; 196,196,255; 235,235,235; 235,164,164; 193,0,0  ]/255;
[sz1,~]=size(colmapdef);
cmap=interp1(linspace(0,1,sz1),colmapdef,linspace(0,1,255));
end

function cmap = french()
colmapdef=[255,0,0; 255,255,255; 0,0,255]/255;
[sz1,~]=size(colmapdef);
cmap=interp1(linspace(0,1,sz1),colmapdef,linspace(0,1,255));
end

function cmap = ice()
%definition of the colormap "ice"
colmapdef=[255,255,255; 125,255,255; 0,123,255; 0,0,124; 0,0,0]/255;
[sz1,~]=size(colmapdef);
cmap=interp1(linspace(0,1,sz1),colmapdef,linspace(0,1,255));
end

function cmap = fire()
% definition of colormap "fire"
colmapdef = [255   255   255
    255   255   151
    255   207    89
    255   148    45
    255    99    13
    253    57     0];
colmapdef = colmapdef/255;
[sz1,~]=size(colmapdef);
cmap=interp1(linspace(0,1,sz1),colmapdef,linspace(0,1,255));
end

function cmap = dawn()
% definition of colormap "dawn"
colmapdef = [255   255   195
    255   255   139
    255   179   126
    204    77   127
    101     0   127
    0     0   126];
colmapdef = colmapdef/255;
[sz1,~]=size(colmapdef);
cmap=interp1(linspace(0,1,sz1),colmapdef,linspace(0,1,255));
end

function cmap = seashore()
% definition of colormap "seashore"
colmapdef = [[255   255   195];[255   255   139];[179   255   126];[77   204   127];[ 0   101   127];[0     0   126]];
colmapdef = colmapdef/255;
[sz1,~]=size(colmapdef);
cmap=interp1(linspace(0,1,sz1),colmapdef,linspace(0,1,255));
end

% Note for future (and for Javier) : here is the way to convert a [255,3]
% array into a [5,3] array producing an equivalent colormap
% colmapdef = colmapdef(1+255*(0:5)/5,:)
% colmapdef = colmapdef/255;


function cmap = viridis()
%
%   VIRIDIS is the new default colormap for matplotlib
%  
% This function adapted from one created by Ed Hawkins (@ed_hawkins) and Kevin Anchukaitis

viridi = [
0.26700401  0.00487433  0.32941519
0.26851048  0.00960483  0.33542652
0.26994384  0.01462494  0.34137895
0.27130489  0.01994186  0.34726862
0.27259384  0.02556309  0.35309303
0.27380934  0.03149748  0.35885256
0.27495242  0.03775181  0.36454323
0.27602238  0.04416723  0.37016418
0.2770184   0.05034437  0.37571452
0.27794143  0.05632444  0.38119074
0.27879067  0.06214536  0.38659204
0.2795655   0.06783587  0.39191723
0.28026658  0.07341724  0.39716349
0.28089358  0.07890703  0.40232944
0.28144581  0.0843197   0.40741404
0.28192358  0.08966622  0.41241521
0.28232739  0.09495545  0.41733086
0.28265633  0.10019576  0.42216032
0.28291049  0.10539345  0.42690202
0.28309095  0.11055307  0.43155375
0.28319704  0.11567966  0.43611482
0.28322882  0.12077701  0.44058404
0.28318684  0.12584799  0.44496   
0.283072    0.13089477  0.44924127
0.28288389  0.13592005  0.45342734
0.28262297  0.14092556  0.45751726
0.28229037  0.14591233  0.46150995
0.28188676  0.15088147  0.46540474
0.28141228  0.15583425  0.46920128
0.28086773  0.16077132  0.47289909
0.28025468  0.16569272  0.47649762
0.27957399  0.17059884  0.47999675
0.27882618  0.1754902   0.48339654
0.27801236  0.18036684  0.48669702
0.27713437  0.18522836  0.48989831
0.27619376  0.19007447  0.49300074
0.27519116  0.1949054   0.49600488
0.27412802  0.19972086  0.49891131
0.27300596  0.20452049  0.50172076
0.27182812  0.20930306  0.50443413
0.27059473  0.21406899  0.50705243
0.26930756  0.21881782  0.50957678
0.26796846  0.22354911  0.5120084 
0.26657984  0.2282621   0.5143487 
0.2651445   0.23295593  0.5165993 
0.2636632   0.23763078  0.51876163
0.26213801  0.24228619  0.52083736
0.26057103  0.2469217   0.52282822
0.25896451  0.25153685  0.52473609
0.25732244  0.2561304   0.52656332
0.25564519  0.26070284  0.52831152
0.25393498  0.26525384  0.52998273
0.25219404  0.26978306  0.53157905
0.25042462  0.27429024  0.53310261
0.24862899  0.27877509  0.53455561
0.2468114   0.28323662  0.53594093
0.24497208  0.28767547  0.53726018
0.24311324  0.29209154  0.53851561
0.24123708  0.29648471  0.53970946
0.23934575  0.30085494  0.54084398
0.23744138  0.30520222  0.5419214 
0.23552606  0.30952657  0.54294396
0.23360277  0.31382773  0.54391424
0.2316735   0.3181058   0.54483444
0.22973926  0.32236127  0.54570633
0.22780192  0.32659432  0.546532  
0.2258633   0.33080515  0.54731353
0.22392515  0.334994    0.54805291
0.22198915  0.33916114  0.54875211
0.22005691  0.34330688  0.54941304
0.21812995  0.34743154  0.55003755
0.21620971  0.35153548  0.55062743
0.21429757  0.35561907  0.5511844 
0.21239477  0.35968273  0.55171011
0.2105031   0.36372671  0.55220646
0.20862342  0.36775151  0.55267486
0.20675628  0.37175775  0.55311653
0.20490257  0.37574589  0.55353282
0.20306309  0.37971644  0.55392505
0.20123854  0.38366989  0.55429441
0.1994295   0.38760678  0.55464205
0.1976365   0.39152762  0.55496905
0.19585993  0.39543297  0.55527637
0.19410009  0.39932336  0.55556494
0.19235719  0.40319934  0.55583559
0.19063135  0.40706148  0.55608907
0.18892259  0.41091033  0.55632606
0.18723083  0.41474645  0.55654717
0.18555593  0.4185704   0.55675292
0.18389763  0.42238275  0.55694377
0.18225561  0.42618405  0.5571201 
0.18062949  0.42997486  0.55728221
0.17901879  0.43375572  0.55743035
0.17742298  0.4375272   0.55756466
0.17584148  0.44128981  0.55768526
0.17427363  0.4450441   0.55779216
0.17271876  0.4487906   0.55788532
0.17117615  0.4525298   0.55796464
0.16964573  0.45626209  0.55803034
0.16812641  0.45998802  0.55808199
0.1666171   0.46370813  0.55811913
0.16511703  0.4674229   0.55814141
0.16362543  0.47113278  0.55814842
0.16214155  0.47483821  0.55813967
0.16066467  0.47853961  0.55811466
0.15919413  0.4822374   0.5580728 
0.15772933  0.48593197  0.55801347
0.15626973  0.4896237   0.557936  
0.15481488  0.49331293  0.55783967
0.15336445  0.49700003  0.55772371
0.1519182   0.50068529  0.55758733
0.15047605  0.50436904  0.55742968
0.14903918  0.50805136  0.5572505 
0.14760731  0.51173263  0.55704861
0.14618026  0.51541316  0.55682271
0.14475863  0.51909319  0.55657181
0.14334327  0.52277292  0.55629491
0.14193527  0.52645254  0.55599097
0.14053599  0.53013219  0.55565893
0.13914708  0.53381201  0.55529773
0.13777048  0.53749213  0.55490625
0.1364085   0.54117264  0.55448339
0.13506561  0.54485335  0.55402906
0.13374299  0.54853458  0.55354108
0.13244401  0.55221637  0.55301828
0.13117249  0.55589872  0.55245948
0.1299327   0.55958162  0.55186354
0.12872938  0.56326503  0.55122927
0.12756771  0.56694891  0.55055551
0.12645338  0.57063316  0.5498411 
0.12539383  0.57431754  0.54908564
0.12439474  0.57800205  0.5482874 
0.12346281  0.58168661  0.54744498
0.12260562  0.58537105  0.54655722
0.12183122  0.58905521  0.54562298
0.12114807  0.59273889  0.54464114
0.12056501  0.59642187  0.54361058
0.12009154  0.60010387  0.54253043
0.11973756  0.60378459  0.54139999
0.11951163  0.60746388  0.54021751
0.11942341  0.61114146  0.53898192
0.11948255  0.61481702  0.53769219
0.11969858  0.61849025  0.53634733
0.12008079  0.62216081  0.53494633
0.12063824  0.62582833  0.53348834
0.12137972  0.62949242  0.53197275
0.12231244  0.63315277  0.53039808
0.12344358  0.63680899  0.52876343
0.12477953  0.64046069  0.52706792
0.12632581  0.64410744  0.52531069
0.12808703  0.64774881  0.52349092
0.13006688  0.65138436  0.52160791
0.13226797  0.65501363  0.51966086
0.13469183  0.65863619  0.5176488 
0.13733921  0.66225157  0.51557101
0.14020991  0.66585927  0.5134268 
0.14330291  0.66945881  0.51121549
0.1466164   0.67304968  0.50893644
0.15014782  0.67663139  0.5065889 
0.15389405  0.68020343  0.50417217
0.15785146  0.68376525  0.50168574
0.16201598  0.68731632  0.49912906
0.1663832   0.69085611  0.49650163
0.1709484   0.69438405  0.49380294
0.17570671  0.6978996   0.49103252
0.18065314  0.70140222  0.48818938
0.18578266  0.70489133  0.48527326
0.19109018  0.70836635  0.48228395
0.19657063  0.71182668  0.47922108
0.20221902  0.71527175  0.47608431
0.20803045  0.71870095  0.4728733 
0.21400015  0.72211371  0.46958774
0.22012381  0.72550945  0.46622638
0.2263969   0.72888753  0.46278934
0.23281498  0.73224735  0.45927675
0.2393739   0.73558828  0.45568838
0.24606968  0.73890972  0.45202405
0.25289851  0.74221104  0.44828355
0.25985676  0.74549162  0.44446673
0.26694127  0.74875084  0.44057284
0.27414922  0.75198807  0.4366009 
0.28147681  0.75520266  0.43255207
0.28892102  0.75839399  0.42842626
0.29647899  0.76156142  0.42422341
0.30414796  0.76470433  0.41994346
0.31192534  0.76782207  0.41558638
0.3198086   0.77091403  0.41115215
0.3277958   0.77397953  0.40664011
0.33588539  0.7770179   0.40204917
0.34407411  0.78002855  0.39738103
0.35235985  0.78301086  0.39263579
0.36074053  0.78596419  0.38781353
0.3692142   0.78888793  0.38291438
0.37777892  0.79178146  0.3779385 
0.38643282  0.79464415  0.37288606
0.39517408  0.79747541  0.36775726
0.40400101  0.80027461  0.36255223
0.4129135   0.80304099  0.35726893
0.42190813  0.80577412  0.35191009
0.43098317  0.80847343  0.34647607
0.44013691  0.81113836  0.3409673 
0.44936763  0.81376835  0.33538426
0.45867362  0.81636288  0.32972749
0.46805314  0.81892143  0.32399761
0.47750446  0.82144351  0.31819529
0.4870258   0.82392862  0.31232133
0.49661536  0.82637633  0.30637661
0.5062713   0.82878621  0.30036211
0.51599182  0.83115784  0.29427888
0.52577622  0.83349064  0.2881265 
0.5356211   0.83578452  0.28190832
0.5455244   0.83803918  0.27562602
0.55548397  0.84025437  0.26928147
0.5654976   0.8424299   0.26287683
0.57556297  0.84456561  0.25641457
0.58567772  0.84666139  0.24989748
0.59583934  0.84871722  0.24332878
0.60604528  0.8507331   0.23671214
0.61629283  0.85270912  0.23005179
0.62657923  0.85464543  0.22335258
0.63690157  0.85654226  0.21662012
0.64725685  0.85839991  0.20986086
0.65764197  0.86021878  0.20308229
0.66805369  0.86199932  0.19629307
0.67848868  0.86374211  0.18950326
0.68894351  0.86544779  0.18272455
0.69941463  0.86711711  0.17597055
0.70989842  0.86875092  0.16925712
0.72039115  0.87035015  0.16260273
0.73088902  0.87191584  0.15602894
0.74138803  0.87344918  0.14956101
0.75188414  0.87495143  0.14322828
0.76237342  0.87642392  0.13706449
0.77285183  0.87786808  0.13110864
0.78331535  0.87928545  0.12540538
0.79375994  0.88067763  0.12000532
0.80418159  0.88204632  0.11496505
0.81457634  0.88339329  0.11034678
0.82494028  0.88472036  0.10621724
0.83526959  0.88602943  0.1026459 
0.84556056  0.88732243  0.09970219
0.8558096   0.88860134  0.09745186
0.86601325  0.88986815  0.09595277
0.87616824  0.89112487  0.09525046
0.88627146  0.89237353  0.09537439
0.89632002  0.89361614  0.09633538
0.90631121  0.89485467  0.09812496
0.91624212  0.89609127  0.1007168 
0.92610579  0.89732977  0.10407067
0.93590444  0.8985704   0.10813094
0.94563626  0.899815    0.11283773
0.95529972  0.90106534  0.11812832
0.96489353  0.90232311  0.12394051
0.97441665  0.90358991  0.13021494
0.98386829  0.90486726  0.13689671
0.99324789  0.90615657  0.1439362];

P = size(viridi,1);
N=P;
cmap = interp1(1:P, viridi, linspace(1,P,N), 'linear');
end


function y = logfilter(x,S)
y = S*sign(x).*log(1+abs(x)/S);
end
