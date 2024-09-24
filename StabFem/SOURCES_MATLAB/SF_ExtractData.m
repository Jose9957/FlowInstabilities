
function values = SF_ExtractData(ffdata,varargin)
%
% This function interpolated data from a P1-ordered field of a ffdata,
% on prescribed X and Y vectors.
%
% Usage : 
%
% A/ (recommended)  
% values = SF_ExtractData(ffdata,X,Y)
%
% X and Y are expected as 1D-vectors of same length 
% (but if either X or Y is a single constant, the program understands that
% you require a vertical or horizontal line, respectively). 
% 
% In recommended mode the return value is a structure with all valid interpolated 
% data as fields. (e.g. values.ux, values.uy, etc...)
% 
% Examples of usage : 
% Yline = [0:.01:10];
% Line = SF_ExtractData(em,'all',0,Y); -> values on the x-axis 
% plot(Yline,Line.ux,Tline,Line.uy);
%
%
% B/ (legacy) 
% values = SF_ExtractData(ffdata,fieldname,X,Y)
%
% Un legacy mode fieldname is expected a valid field name a nd the return
% value is a single vector.
%
% Examples :
% UXaxis = SF_ExtractData(bf,'ux',[0:.01:10],0); -> values on the x-axis 
% Vortline = SF_ExtractData(em,'vort1',[0:.01:10],[0:.01:10]); -> values of the vorticity on a diagonal line  
%                      -> values of all fields on a vertical line  
% 
% Adapted from ffplottri2gridint from Chloros, 2018. 
% Incorporated into the StabFem project by D. F on nov. 1, 2018.
% Redesigned on March 2019 based on ffinterpolate and in may 2020
% (using VhSeq for P1, P2, P1b and vectorized fields)
%

if(length(varargin)==3)
    field =varargin{1};
    X = varargin{2};
    Y = varargin{3};
elseif (length(varargin)==2)
    field ='all';
    X = varargin{1};
    Y = varargin{2};
else
    error('Wrong number of arguments');
end    

if isfield(ffdata,'status')&&strcmp(ffdata.status,'unloaded')
    ffdata = SF_LoadFields(ffdata);
    SF_core_log('n',[' Loading dataset from file ', ffdata.filename ' because not previously loaded']);
    SF_core_log('n', 'To do this permanently : use SF_LoadFields (see documentation or help SF_LoadFields)')
    ffdata.status = 'loaded';
end


if(length(X)==1)
    X = X*ones(size(Y));
end

if(length(Y)==1)
    Y = Y*ones(size(X));
end
if isfield(ffdata,field)
switch(length(ffdata.(field)))
    case (ffdata.mesh.np)   % P1
        vhseq = reshape(ffdata.mesh.tri(1:3,:),size(ffdata.mesh.tri,2)*3,1)-1; 
    case (ffdata.mesh.nt) % P0 : Treated as P1dc (could be done in a better way)
        vhseq = [0 : 3*ffdata.mesh.nt-1];    
        ffdata.(field) = repelem(ffdata.(field),3);
    case (3*ffdata.mesh.nt) % P1dc
        vhseq = [0 : 3*ffdata.mesh.nt-1];
    case (4*ffdata.mesh.nt) % P1bdc ?
        vhseq = [0 : 4*ffdata.mesh.nt-1];
    case (6*ffdata.mesh.nt) % P2dc
        vhseq = [0 : 6*ffdata.mesh.nt-1];
    case (ffdata.mesh.np2)  % P2
        vhseq = ffdata.mesh.Vh_P2;
    case (ffdata.mesh.np1b) % P1b
        vhseq = ffdata.mesh.Vh_P1b;
    otherwise
        SF_core_log('w','Error in SF_ExtractData : field has incorrect size')
 end
   
 values = ffinterpolate(ffdata.mesh.points,ffdata.mesh.bounds,ffdata.mesh.tri,vhseq,X,Y,ffdata.(field));

elseif strcmp(field,'all')
    SF_core_log('n','In ExtractData : extracting all field')
    thefields = fieldnames(ffdata);
 for i = 1:length(thefields)
     thefield = thefields{i};
     if isnumeric(ffdata.(thefield))&&length(ffdata.(thefield))>=ffdata.mesh.np
         values.(thefield) = SF_ExtractData(ffdata,thefield,X,Y);
     end
 end
else
   field
    SF_core_log('e','Error in SF_ExtractData : unrecognized field')
end
    
end
