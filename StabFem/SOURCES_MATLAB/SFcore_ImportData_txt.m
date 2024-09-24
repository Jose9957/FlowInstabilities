function pdestruct = SFcore_ImportData_txt(pdestruct)

% Subfunction of SFcore_ImportData to read the .txt file 
%
% This one is for the old syntax like "ReP2P2P1.2" 

if ~strcmp(pdestruct.filename(end-2:end),'txt')
    SF_core_log('w', [' filename ',pdestruct.filename,' is not a .txt file and should not be read using SFcore_ImportData_txt !!!'])
end


mesh = pdestruct.mesh;

if (isfield(pdestruct,'datastoragemode'))&&(isfield(pdestruct,'datadescriptors'))
if ~(strcmpi(pdestruct.datastoragemode,'columns'))
        % reads .txt file
        SF_core_log('d',[ ' Now reading file ',pdestruct.filename]);
        fid1 = fopen(pdestruct.filename);
        if fid1<0
            SF_core_log('e',['Error while opening file ',pdestruct.filename]);
        end
        numfields = length(SplitNames(pdestruct.datastoragemode));
        if numfields>0
            size1 = fscanf(fid1,'%d',1);
            if(strcmp(pdestruct.datastoragemode(1:2),'Re'))
                data1raw = fscanf(fid1,'%f',size1); %% HERE WE SHOULD MODIFY TO IMPORT ONERA-TYPE STORAGE %% 
                data1 = data1raw(1:1:end);
                SF_core_log('dd',[' Read real data size ',num2str(size1),' in file ' pdestruct.filename  ]);
            else
                data1raw = fscanf(fid1,' (%f,%f)',2*size1);
                data1 = data1raw(1:2:end-1)+1i*data1raw(2:2:end);
                SF_core_log('dd',[' Read real data size ',num2str(size1),' in file ' pdestruct.filename  ]);
            end
        else
            size1=0;
        end
        if(strcmp(pdestruct.datastoragemode(1:2),'Re'))
            end1 = fscanf(fid1,'%f');
            SF_core_log('dd',[' Read real SCALAR data size ',num2str(size1),' in file ' pdestruct.filename  ]);
        else
            end1 = fscanf(fid1,' (%f,%f)');
            SF_core_log('dd',[' Read complex SCALAR data size ',num2str(size1),' in file ' pdestruct.filename  ]);
        end    
            if isempty(end1)
                SF_core_log('dd',[' not found SCALAR data in complex format in file ' pdestruct.filename, ' ; trying real' ]);
                end1 = fscanf(fid1,'%f');
            end
        fclose(fid1);
        SF_core_log('dd',['SFcore_ImportData : Read ' num2str(size1) ' + ' num2str(length(end1)) ' data in file ' pdestruct.filename])
        % set the field names according to the specified names
        variablenames = strsplit(pdestruct.datadescriptors,',');
        numscalars = length(variablenames)-numfields;
        Vhname = ['Vh_' GetRoot(pdestruct.datastoragemode)];
        if isempty(mesh)&&exist([dir,'/.meshfilename'],'file')
            SF_core_log('d',' TRYING TO GET MESH INFO from .meshfilename')
            fid = fopen([dir,'/.meshfilename'],'r');
            meshfilename = fscanf(fid,'%s');
            fclose(fid);   
            mesh = SFcore_ImportMesh(meshfilename);
        end
        if isempty(mesh)
            SF_core_log('w',' NO MESH SPECIFIED FOR READING THIS DATA FILE')
            SF_core_log('w',' ASSUMING THE DATASET IS ASSOCIATED TO LAST MESH')
            mesh = SF_Load('MESHES','last');
        end
        if ~strcmp(Vhname,'Vh_')
        if ~isfield(mesh,Vhname)&&~strcmp(Vhname,'Vh_P1')&&~strcmp(Vhname,'Vh_P0')
            SF_core_log('w',[' Data format ',GetRoot(pdestruct.datastoragemode),' not available ! please append it to the macro STORAGEMODES in your SF_Custom.idp file']); 
        end
        if strcmp(Vhname,'Vh_P1')
            Vh = [1:mesh.np];
        elseif strcmp(Vhname,'Vh_P0')
            Vh = [1:mesh.nt];
        else
            Vh = mesh.(Vhname);
        end
        if(numfields>1)
            for ii = 1:min(numfields,length(variablenames))
                [~,dataAA] = ffvectorget(SplitNames(pdestruct.datastoragemode),Vh,data1, ii);
                pdestruct.(variablenames{ii})=dataAA;
                SF_core_log('dd',[' SFcore_ImportData : imported field ', variablenames{ii} ' from vectorial dataset']);
            end
        else
           pdestruct.(variablenames{1})=data1;
           SF_core_log('dd',[' SFcore_ImportData : imported single field ', variablenames{1} ]);
        end
        end
        if numscalars>length(end1)
          SF_core_log('w',['wrong number of auxiliary data in file ',pdestruct.filename, ' : expecting ', num2str(numscalars), ' , reading ',num2str(length(end1)) ]); 
        end
        for ii=numfields+1:numfields+min(numscalars,length(end1))
            pdestruct.(variablenames{ii})=end1(ii-numfields);
            SF_core_log('dd',[' SFcore_ImportData : imported scalar ', variablenames{ii}]);
        end
        else
            % importing in 'column' form
            if ~exist(pdestruct.filename,'file')
                SF_core_log('e',[ 'when Reading associated .txt or .stat file : file ', pdestruct.filename, ' not found']); 
            end
            D = importdata(pdestruct.filename);
            if isstruct(D)
                D = D.data;
            end
                
            variablenames = strsplit(pdestruct.datadescriptors,',');
            if ~isempty(D)
            for ii = 1:length(variablenames)
                vn = variablenames{ii};
                if ii<=size(D,2)
                    pdestruct.(vn) = D(:,ii);
                    if (length(vn)>2)&&strcmp(vn(end-1:end),'_i')
                        pdestruct.(vn(1:end-2)) = pdestruct.([vn(1:end-2),'_r'])+1i*pdestruct.(vn);
                        pdestruct = rmfield(pdestruct,{[vn(1:end-2),'_r'],vn});
                    end
                else
                    SF_core_log('w',' When checking file StabStats.ff2m : dimensions do not agree')
                    SF_core_log('w','     (If using different solvers in the same project, metadata must be consistent) ')
                    
                end
            end
            else
                SF_core_log('w',['Nothing found in file ',pdestruct.filename])
            end
        end
    end
    
% Importation of 'timestatistics' data using previous method (to be removed)

     if ( isfield(pdestruct,'datatype')&&((strcmpi(pdestruct.datatype,'timestatistics')==1)...
         ||(strcmpi(pdestruct.datatype,'forcedlinear')==1))) && (~isfield(pdestruct,'datadescriptors'))
% 
%     % the data file is a time series (most likely coming from DNS)
%     % THIS PART IS TO BE REWRITTEN !
     indexdata = 1;
     %Ndata = 0;    
     for ifield = 1:numfieldsaux
         typefield = description{1}{2 * ifield - 1};
         namefield = description{1}{2 * ifield};
             switch (typefield)
             case ({'real','real[int]'})
                 value = data(:,indexdata);
                 indexdata = indexdata + 1;
                 pdestruct.(namefield) = value;
                 SF_core_log('d', ['Reading real tab. ',namefield,' in column-type file ',pdestruct.filename]);
   
             case ({'complex','complex[int]'})
                 valuer = data(:,indexdata);
                 indexdata = indexdata + 1;
                 valuei = data(:,indexdata);
                 indexdata = indexdata + 1;
                 pdestruct.(namefield)= valuer+1i*valuei;
                 SF_core_log('dd', ['Reading complex tab. ',namefield,' in column-type file ',pdestruct.filename]);
          
                 otherwise
                     error('wrong type of data in file !')
              end
     end
     end
     
end
     

%% Auxiliary functions

function [Rootnames,nscalars] = GetRoot(names)

% This function extracts the root "P2P2P1' from a string like "ReP2P2P1.1" 
% (useful to import vectorial data and unscramble them using the routines of Markus)

split = strsplit(names,'.');
Rootnames=split{1};
if(length(split)>1)
    nscalars = split{2};
else
    nscalars = 0;
end

if strcmp(names(1:2),'Re')
         Rootnames = Rootnames(3:end);
elseif strcmp(names(1:2),'Cx')
         Rootnames = Rootnames(3:end);
end

end



function struct = SplitNames(names)

% This function splits a string such as "ReP2P2P1.1" into { 'P2', 'P2', P1'}
% (useful to import vectorial data and unscramble them using the routines of Markus)

if ~ischar(names) 
    error('Error in SplitNames')
end
names = GetRoot(names); % to remove "Re" or "Cx" at beginning and ".N" at end
if ~isempty(names)
  i=1;
  while ~isempty(names)
    if (length(names)>2)&&(strcmp(names(1:3),'P1b'))
        struct{i} = 'P1b';
        names = names(4:end);
        i = i+1;
    elseif strcmp(names(1:2),'P1')
        struct{i} = 'P1';
         names = names(3:end);
         i = i+1;
    elseif strcmp(names(1:2),'P2')
        struct{i} = 'P2';
        names = names(3:end);
        i = i+1;
     elseif strcmp(names(1:2),'P0')
        struct{i} = 'P0';
        names = names(3:end);
        i = i+1;
    else 
        SF_core_log('w','problem in detecting datastoragemode');
    end
  end
else
    struct = [];
end

end
