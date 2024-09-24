function res = SF_Add(ffdata,varargin)
%>
%>  Function SF_Add
%>  Addition of two (or more) fields
%>
%>  USAGE :
%>  addition = SF_Add({field1,field2,...,fieldN},'Coefs',[ c1, c2, ..., cN],...
%>             'Params',[d1,d2, ..., dS]);
%>
%>  this will create the sum of the fields
%>
%> Currently we have a basic driver to add N fields.
%> Author : D. Fabre, 2018-2019. Redone by J. Sierra 2020.
%>
%> This program is part of the StabFem project distributed under GNU licence.

ffdatadir = SF_core_getopt('ffdatadir');

NScalarStW = 0; % fix after Javier

%% Input parser
% If ffdata is not a cell transform to one
if(class(ffdata) ~= "cell")
    for i=[1:length(ffdata)]
        tmp{i} = ffdata(i);
    end
    ffdata = tmp;
end
% Parse optional inputs
p = inputParser;
% Add coefficients to be used to multiply each field
addParameter(p, 'Coefs', []);
% Add storagemode to write the field
SFcore_addParameter(p, ffdata{1},'datastoragemode', 'ReP2P2P1', @ischar);
% Additional parameters to be written at the end of the txt file
addParameter(p, 'Params', []);
% List of strings. Name of the auxiliary scalars to be outputted in res
addParameter(p, 'NameParams', []);
% Legacy inputs (TODO: To be removed)
addParameter(p, 'Amp1',1.0);
addParameter(p, 'Amp2',1e-3);
parse(p, varargin{:});
% Storage mode of the written file
datastoragemodeWrite = p.Results.datastoragemode;
[~,dataFieldStW,dataScalarStW] = fileparts(datastoragemodeWrite);
if isempty(dataScalarStW) % very ugly fix
    dataScalarStW = '.0';
    SF_core_log('l','Very ugly fix in case there is no scalar associated to this field');
end

% Mesh of the output structure
res.mesh = ffdata{1}.mesh;
% Number of fields
N = length(ffdata);
% Determine fields (compatible with legacy inputs)
if(~isempty(p.Results.Coefs))
    Amp = p.Results.Coefs;
else
    Amp(1) = p.Results.Amp1;
    Amp(2) = p.Results.Amp2;
end
% Auxiliary scalars
userScalars = p.Results.Params;
% Initialise to empty the list of parameter names
NameParams = [];
% If the number of fields is different to the structure of Coefs
if(N~=length(Amp))
    error('Error : The number of coefficients and fields is not the same')
end

% Determine if the datastoragemode of input files is valid
for i=1:N
    [~,tmpdataS,tmpScalar] = fileparts((ffdata{i}.datastoragemode));
    datastoragemodeN{i} = (tmpdataS);
    if(~isempty(tmpScalar))
        scalarsN(i) = str2num(tmpScalar(2));
    else
        scalarsN(i) = 0;
    end
    tmp = char(datastoragemodeN{i});
    tmp = tmp(3:max(3,end));
    dataStorageN{i} = (tmp);
end

% Parse input data and datastorageWrite
if ~strcmp(dataStorageN(1),dataStorageN(end) )
    SF_core_log('e','Storage modes of data not compatible !');
    return;
end


% Read files
fid = fopen(ffdata{i}.filename);
sizeN(1) = fscanf(fid,'%d',1);
fclose(fid);
dataN = zeros(N,sizeN(1));
if(min(scalarsN) ~= 0)
    dataSN = zeros(N,scalarsN(1));
end

% Read the N files and determine the data of the FEM fields + scalars
for i=1:N
    SF_core_log('nn',['Reading file: ',num2str(i)]);
    fid = fopen(ffdata{i}.filename);
    % Read number of DOF
    sizeN(i) = fscanf(fid,'%d',1);
    % Read FEM fields
    if(strcmp(ffdata{i}.datastoragemode(1:2),'Re'))
        dataraw = fscanf(fid,'%f',sizeN(i));
        dataN(i,:) = dataraw(1:1:end);
    else
        dataraw = fscanf(fid,' (%f,%f)',2*sizeN(i));
        dataN(i,:) = dataraw(1:2:end-1)+1i*dataraw(2:2:end);
    end
    % Read auxiliar scalars only in the first file
    if(str2num(dataScalarStW(2)) > 0 && i == 1 )
        dataraw = fscanf(fid,'%f',scalarsN(i));
        dataSN(i,:) = dataraw(1:1:end);
    end
    fclose(fid);
end

if max(sizeN) ~= min(sizeN)
    SF_core_log('e','The fields have different structures and cannot be added !');
    return;
end

% Determine the scalars to be written in the .txt file
% Either the scalars provided by the user if the correct length
% Or the params of the first field
NScalarStW = 0;
if(~isempty(userScalars))
    if(min(scalarsN) == length(userScalars))
        dataScalars = userScalars;
        NScalarStW = length(userScalars);
        if(length(p.Results.NameParams) == NScalarStW && isstring(p.Results.NameParams))
            NameParams = p.Results.NameParams;
        end
    else
        dataScalars = dataSN(1,:);
        datastoragemodeWrite = ffdata{1}.datastoragemode;
        NScalarStW = length(dataScalars);
        SF_core_log('w',['The number of additional scalars ',num2str(NScalarStW),' does not match ',...
            'the number of parameters entered by the user ',num2str(length(userScalars)),...
            ' The default action is to choose the structure of the first field. Therefore the first field must contain the user input fields. ']);
    end
else
    if(NScalarStW > 0 && i == 1)
        dataScalars = dataSN(1,:);
    end
end

% Define dataStorageWrite as dataFieldStW and NScalarStW
if(NScalarStW ~= 0)
    datastoragemodeWrite = ([dataFieldStW,'.',num2str(NScalarStW)]);
else
    datastoragemodeWrite = dataFieldStW;
end


% Generation of part of the header for auxiliary variables
datadescriptors = char(ffdata{1}.datadescriptors);
datadescriptosrsparts = strsplit(datadescriptors,',');
NfieldsFEM = length(strfind(datastoragemodeWrite,'P')); % Suppose all are P2,P1,P1b,P3...
%datadescriptors = join(datadescriptosrsparts(1:NfieldsFEM+NScalarStW),',');
datadescriptors=datadescriptosrsparts(1);
for ii=2:NfieldsFEM+NScalarStW
    datadescriptors = [char(datadescriptors),',',char(datadescriptosrsparts(ii))];
end

%datadescriptors = datadescriptors{1};


%% Generation of the .txt file
% Initialise the data structure for writting
data3 = Amp(1)*dataN(1,:);
for i=2:N
    data3 = data3 + Amp(i)*dataN(i,:);
end
% Generate data structure for complex/real structures
if(strcmp(datastoragemodeWrite(1:2),'Cx'))
    dataWrite = zeros(2*length(data3),1);
    dataWrite(1:2:end-1) = real(data3);
    dataWrite(2:2:end) = imag(data3);
else
    dataWrite = real(data3);
end


SF_core_log('nnn','Creating field by adding two fields');
res.filename = [ ffdatadir 'Addition.txt'];
res.datatype= 'Addition';
res.DataDescription = ['Addition of ',num2str(N),' fields from files '];
res.datastoragemode = datastoragemodeWrite;

fid3 = fopen(res.filename,'w');
fprintf(fid3,'%d \n',sizeN(1));
if(strcmp(datastoragemodeWrite(1:2),'Re'))
    fprintf(fid3,' %f \n',dataWrite);
else
    fprintf(fid3,' (%f,%f) \n',dataWrite);
end
% Write scalar auxiliar fields
if(NScalarStW > 0)
    fprintf(fid3,' %f \n',dataScalars);
end
fclose(fid3);
SF_core_log('nnn','SF_Add : successfully written .txt . file for sum of two fields')

%% Generation of the ff2m file
% Fill name of data descriptors for the matlab structure if NScalarStW>0
if(~isempty(NameParams))
    % Eliminate the scalars fields of the original field
    datadescriptorsSplit = split(datadescriptors,',');
    datadescriptors = char(join(datadescriptorsSplit(1:end-scalarsN(1)),','));
    for i=1:NScalarStW
        datadescriptors = [datadescriptors, ',', char(NameParams(i))];
    end
end
% Write ff2m file
SFcore_Writeff2mFile('Addition.ff2m','datatype','Addition',...
    'datastoragemode',char(datastoragemodeWrite),'datadescriptors',datadescriptors);
% We import using the new method
SFcore_AddMESHFilenameToFF2M('Addition.ff2m',char(ffdata{1}.mesh.filename));
if isempty(SF_core_getopt('ffdatadir'))||strcmp(SF_core_getopt('ffdatadir'),'./')
    SF_core_log('w',' When using SF_Add it is advised to define a database folder.  ')
    filename = 'Addition.ff2m';
else
    filename = SFcore_MoveDataFiles('Addition.ff2m','MISC');
end
if iscell(datadescriptors)
    datadescriptors=datadescriptors{1}; % reason unknown
end
SF_core_log('n',[' in SF_Add : processsing data from txt files :  ',datadescriptors]);

res = SFcore_ImportData(ffdata{1}.mesh,char(filename));


%% Now reconstruct auxiliary fields
fields = fieldnames(ffdata{1});
for jj = 1:length(fields)
    try
        field = fields{jj};
        if isnumeric(ffdata{1}.(field))&&length(ffdata{1}.(field))>1&&~isfield(res,field)
            data3 = Amp(1)*ffdata{1}.(field);
            for i=2:N
                data3 = data3 + Amp(i)*ffdata{i}.(field);
            end
            res.(field) = data3;
            SF_core_log('n',[' in SF_Add : processsing auxiliary field ',field]);
        end
    catch
        SF_core_log('w',[' in SF_Add : could not process with auxiliary field ',field]);
    end
    
end

SF_core_log('nn',['Adding data completed']);

end


%% PATCH DAVID ;: need define function join for octave
%function res = join(a,b)
%res = =a(1);
%for ii=2:length(a)
%        res  = [res,b,a(ii)];
%end
%end


