function meshstruct = importFFmesh(varargin)


%   function importFFmesh
%    Obolete ; please use SFcore_ImportMesh instead
%

disp('WARNING : DO NOT USE importFFmesh any more ! SWITCH TO SFcore_ImportMesh');
meshstruct = SFcore_ImportMesh(varargin{:});

% global ff ffdir ffdatadir sfdir verbosity
%
% % Check for the mesh file which should be in the ffdatadir directory
% if (exist([ffdatadir, fileToRead1]) == 2)
%     fileToRead1 = [ffdatadir, fileToRead1];
% end
% 
% %First, checks of auxiliary files "mesh.ff2m" and "SF_Init.ff2m" are
% %present ; if so imports them
% [filepath, name, ~] = fileparts(fileToRead1);
% fileToRead2 = [filepath, '/', name, '.ff2m'];
% fileToRead3 = [filepath, '/SF_Init.ff2m'];
% 
% if(exist(fileToRead2,'file')&&exist(fileToRead3,'file'))
% mydisp(2, ['FUNCTION  importFFmesh.m : reading complementary files']);
% meshstruct = importFFdata(fileToRead2, fileToRead3);
% end
% 
% % Now reading mesh file using ffreadmesh from Markus
% [meshstruct.points,meshstruct.bounds,meshstruct.tri,meshstruct.np,meshstruct.nbe,meshstruct.nt,meshstruct.labels]=ffreadmesh(fileToRead1);
% 
% meshstruct.filename = fileToRead1;
% 
% 
% %
% % The remainder of this routine has to be rationalised...
% %
% 
% 
% meshstruct.seg = []; % probably obsolete
% 
% 
% 
% if (~isfield(meshstruct, 'problemtype'))
%     meshstruct.problemtype = 'EXAMPLE';
% end
% 
% if (~isfield(meshstruct, 'meshtype'))
%     meshstruct.meshtype = '2D';
% end
% 
% if (~isfield(meshstruct, 'datatype'))
%     meshstruct.datatype = 'mesh';
% end
% 
% % change the field "datatype" to "problemtype" (to be rationalized ?)
% if (~isfield(meshstruct, 'problemtype')&&isfield(meshstruct, 'datatype')) % for retrocompatibility ; to be removed in future
%     disp(['WARNING : in mesh.ff2m datatyle should be replaced by problemtype']);
%     meshstruct.problemtype = meshstruct.datatype;
%     meshstruct = rmfield(meshstruct, 'datatype');
% end
% 
% if (~isfield(meshstruct, 'meshgeneration')) % for retrocompatibility ; to be removed in future
%     meshstruct.meshgeneration = findgeneration(fileToRead1);
%     % initial mesh should be generation = 0
% end
% 
% 
% if(strcmpi(meshstruct.meshtype,'2DMapped'))
%     mydisp(2,'Mapped mesh ; reading additional file for physical coordinates and mapping jacobians');
%     fileToRead4 = [ffdatadir,'Mapping.ff2m'];
%     if(exist(fileToRead4))
%         m2 = importFFdata(meshstruct,fileToRead4);
%         %merge m2 and meshstruct
%         f = fieldnames(m2);
%         for i = 1:length(f)
%             if (~strcmpi(f{i},'filename'))&&(~strcmpi(f{i},'datatype'))&&(~strcmpi(f{i},'mesh'))
%                 meshstruct.(f{i}) = m2.(f{i});
%             end
%         end
%     end
% end
% mydisp(2, ['END FUNCTION importFFmesh.m'])
% end
% 
% function generation = findgeneration(Filename)
% % this function extracts the number in a filename with the form
% % "mesh_adapt##.msh" or "mesh_stretch##.msh"
%     underlineLocations = find((Filename=='_'));
%     if(length(underlineLocations)==1)
%         if(Filename(underlineLocations(1)+1)=='a')
%             generation = str2double(Filename(underlineLocations(1)+6:end-4));
%         elseif(Filename(underlineLocations(1)+1)=='s')
%             generation = str2double(Filename(underlineLocations(1)+8:end-4));
%         else
%             generation = 0;
%         end
%     elseif(length(underlineLocations)>=1)
%         if(Filename(underlineLocations(1)+1)=='a')
%             generation = str2double(Filename(underlineLocations(1)+6:underlineLocations(2)-1));
%         elseif(Filename(underlineLocations(1)+1)=='s')
%             generation = str2double(Filename(underlineLocations(1)+8:underlineLocations(2)-1));
%         else
%             generation = 0;
%         end
%     else
%         generation = 0;
%     end
% end    
% 
