
function Map = SFcore_CreateMappingParamFile(varargin)
%>
%> This auxiliary function creates a file to be included at the top of freefem
%> solvers requiring a (complex) mapping function.
%>
%> The parameters needed to define the mapping functions 
%> are written in Param_Mapping.edp (to be recalled  .idp)
%> The definition of the function is in another include file named MappingDef_###.idp
%> which is supposed to be found in the INCLUDE subfolder.
%>
%> Usage :
%> 1/ (recommended)
%> Map = SF_Mapping(mesh,'rectangle','Xinf',-10,'Xsup',10,'Yinf',0,'Ysup',10,'gammac',.3,'Lc',2)
%> Map = SF_Mapping(mesh,'none') if you want to come back to no-mapping
%> 
%> first argument is either a mesh or a baseflow (with mesh a a field)
%>
%> The result is a Mapping object which allows to plot the corresponding functions 
%>
%> 2/ (legacy)
%> SFcore_CreateMappingParamFile('jet',[1 2 3 4 5 6])
%>
%> TODO : 
%> * implement this new version 
%> * should we rename this function SF_Mapping ???
%> * rename Param_Mapping.edp to Param_Mapping.idp
%> * Ideally this file should be in the WORK directory 
%>

if ischar(varargin{1})
    SF_core_log('l','using SFcore_CreateMappingParamFile in legacy mode')
    mesh.datatype = 'uglyfixforlegacy';
    MappingType = varargin{1};
    MappingParams = varargin{2};
else
    mesh = varargin{1};
    MappingType = varargin{2};
    if strcmp(MappingType,'jet') % to be removed soon
        MappingParams = varargin{3};
    end
end    

% parse the parameters from varargin{3:end}
    
if ~strcmpi(mesh.datatype,'mesh')&&~strcmpi(mesh.datatype,'uglyfixforlegacy')
       % first argument is a base flow
       mesh = mesh.mesh;
end


 fidlog = fopen('.stabfem_log.bash','a');
        if (fidlog>0)
            fprintf(fidlog, '#  Here a file Param_mapping.edp has been created by driver SFcore_CreateMappingParamFile \n');
            fclose(fidlog);
        end
       
    switch(lower(MappingType))   
         case({'rectangle','default'})  
        % Mapping with 6 parameters for axisym. flow across a hole 
            SF_core_log('w',['Using Complex mapping with gamma = ' num2str(MappingParams(4)) ]);
            fid = fopen('Param_Mapping.edp', 'w');
            fprintf(fid, '// Parameters for complex mapping (file generated by matlab driver SFcore_CreateMappingParamFile)\n');
            fprintf(fid, '\n');
            fprintf(fid, ['real ParamMapCXinf = ', num2str(MappingParams(1)), ' ;\n']);
            fprintf(fid, ['real ParamMapXsup = ',  num2str(MappingParams(2)), ' ;\n']);
            fprintf(fid, ['real ParamMapCYinf = ', num2str(MappingParams(3)), ' ;\n']);
            fprintf(fid, ['real ParamMapYsup = ', num2str(MappingParams(4)), ' ;\n']);
            fprintf(fid, ['real ParamMapGCx = ',  num2str(MappingParams(5)), ' ;\n']);
            fprintf(fid, ['real ParamMapLCx = ', num2str(MappingParams(6)), ' ;\n']);
            fprintf(fid, ['real ParamMapGCy = ',  num2str(MappingParams(7)), ' ;\n']);
            fprintf(fid, ['real ParamMapLCy = ',  num2str(MappingParams(8)), ' ;\n']);
            fprintf(fid, '\n');
            fprintf(fid, '// Definition of mapping function in done in an included file \n');
            fprintf(fid, 'include "MappingDef_Rectangle.idp"\n');
            fclose(fid);
        
            case({'circle'}) 
                % javier please put here the mapping in spherical
                % coordinates 
                
            case({'jet','type1'})  
        % Mapping with 6 parameters for axisym. flow across a hole 
            SF_core_log('w',['Using Complex mapping with gamma = ' num2str(MappingParams(4)) ]);
            fid = fopen('Param_Mapping.edp', 'w');
            fprintf(fid, '// Parameters for complex mapping (file generated by matlab driver SFcore_CreateMappingParamFile)\n');
            fprintf(fid, ['real ParamMapLm = ', num2str(MappingParams(1)), ' ;\n']);
            fprintf(fid, ['real ParamMapLA = ',  num2str(MappingParams(2)), ' ;\n']);
            fprintf(fid, ['real ParamMapLC = ', num2str(MappingParams(3)), ' ;\n']);
            fprintf(fid, ['real ParamMapGC = ',  num2str(MappingParams(4)), ' ;\n']);
            fprintf(fid, ['real ParamMapyA = ', num2str(MappingParams(5)), ' ;\n']);
            fprintf(fid, ['real ParamMapyB = ',  num2str(MappingParams(6)), ' ;\n']);
            fprintf(fid, ['include "MappingDef_Jet.idp" ;\n']);
            fclose(fid);
            
             case({'jetold'})  
        % Mapping with 6 parameters for axisym. flow across a hole 
            SF_core_log('w',['Using Complex mapping with gamma = ' num2str(MappingParams(4)) ]);
            fid = fopen('Param_Mapping.edp', 'w');
            fprintf(fid, '// Parameters for complex mapping (file generated by matlab driver SFcore_CreateMappingParamFile)\n');
            fprintf(fid, ['real ParamMapLm = ', num2str(MappingParams(1)), ' ;\n']);
            fprintf(fid, ['real ParamMapLA = ',  num2str(MappingParams(2)), ' ;\n']);
            fprintf(fid, ['real ParamMapLC = ', num2str(MappingParams(3)), ' ;\n']);
            fprintf(fid, ['real ParamMapGC = ',  num2str(MappingParams(4)), ' ;\n']);
            fprintf(fid, ['real ParamMapyA = ', num2str(MappingParams(5)), ' ;\n']);
            fprintf(fid, ['real ParamMapyB = ',  num2str(MappingParams(6)), ' ;\n']);
            fprintf(fid, ['include "MappingDef_Jet_OLD.idp" ;\n']);
            fclose(fid);
            
            
            
          case({'box','type2'})      
        % Mapping with 9 parameters for 2D flow around an object ???
                fid = fopen('Param_Mapping.edp', 'w');
                fprintf(fid, '// Parameters for complex mapping (file generated by matlab driver SFcore_CreateMappingParamFile)\n');
                fprintf(fid, ['real ParamMapCXinf = ', num2str(MappingParams(1)), ' ;']);
                fprintf(fid, ['real ParamMapXsup = ', num2str(MappingParams(2)), ' ;']);
                fprintf(fid, ['real ParamMapCYinf = ', num2str(MappingParams(3)), ' ;']);
                fprintf(fid, ['real ParamMapYsup = ', num2str(MappingParams(4)), ' ;']);
                fprintf(fid, ['real ParamMapGCx = ', num2str(MappingParams(5)), ' ;']);
                fprintf(fid, ['real ParamMapLCx = ', num2str(MappingParams(6)), ' ;']);
                fprintf(fid, ['real ParamMapGCy = ', num2str(MappingParams(7)), ' ;']);
                fprintf(fid, ['real ParamMapLCy = ', num2str(MappingParams(8)), ' ;']);
                fprintf(fid, ['include "MappingDef_Rectangle.idp" ;']);
                fclose(fid);
                
           case({'none','off'})
                fid = fopen('Param_Mapping.edp', 'w');
                fprintf(fid,'// definition of mapping : NO MAPPING \n');
                fprintf(fid,'macro dX(a) dx(a) //EOM \n');
                fprintf(fid,'macro dY(a) dy(a) //EOM \n');
                fprintf(fid,'macro JJ()  1     //EOM \n');	
                fprintf(fid,'macro JJJ() y     //EOM \n');	
                fclose(fid);

    end
    if nargout==1
        % generate the data to plot
        Xmin = min(mesh.points(1,:));
        Xmax = max(mesh.points(1,:));
        X = linspace(Xmin,Xmax,500);
        Map.X = X;
         switch(lower(MappingType))   
            case({'rectangle','default'})  
          
            case({'jet','type1'})  
                Lm = MappingParams(1); LA = MappingParams(2); LC = MappingParams(3);
                GC = MappingParams(4); yA = MappingParams(5); yB = MappingParams(6);
                Map.Gx = (X<Lm).*X + ...
                    (X>=Lm).*(Lm+(X-Lm)./(1-(X-Lm).^2/(LA-Lm)^2).^2.*(1+1i*GC*tanh((X-Lm).^2/LC^2)));  
                Map.Hx = (X<Lm)*1 + ... 
1./((1./((1-(X-Lm).^2/(LA - Lm)^2).^2).*(1 + 1i * GC ...
.* tanh(((X - Lm) .^ 2 / LC ^ 2))) + 4 * ((X - Lm) .^ 2)  ...
./ ((1 - (X - Lm) .^ 2 / (LA - Lm) ^ 2) .^ 3) .* (1 + 1i * GC *  ...
tanh(((X - Lm) .^ 2 / LC ^ 2))) / ((LA - Lm) ^ 2) + 2 * ((X - Lm) .^ 2)...  
./ ((1 - (X - Lm) .^ 2 / (LA - Lm) ^ 2) .^ 2) * 1i *  ...
GC .* (1 - tanh(((X - Lm) .^ 2 / LC ^ 2)) .^ 2) / (LC ^ 2) ) );
         end
        
    end
end