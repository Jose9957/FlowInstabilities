function Struct = SFcore_MergeStructures(Struct1,Struct2)
%
% This function merges two structures.
% NB if a field is present in both structures two possibilities :
% 1/ if datastoragemode is 'columns' the data are appended
%    
% 2/ Otherwise the value of the first structure will be kept.
%
% This program belongs to the StabFem project, freely distributed under GNU licence.
% copyright D. Fabre  2019
if ~isempty(Struct2)    
    f = fieldnames(Struct2);
        for i = 1:length(f)
            if (isfield(Struct1,f{i}))
                mydisp(10,' Warning  in SFcore_MergeStructures :')
                mydisp(10,['field ' f{i} ' is present in both structures !'])
    
                if isfield(Struct1,'datastoragemode')&&strcmp(Struct1.datastoragemode,'columns')&&isnumeric(Struct1.(f{i}))
                    Struct1.(f{i}) = [ Struct1.(f{i}); Struct2.(f{i})];
                    mydisp(10,'   => Appending both values') ;
                end
            else
                if (~strcmpi(f{i},'mesh'))
                    Struct1.(f{i}) = Struct2.(f{i});
                else
                   mydisp(10,' in SFcore_MergeStructures : do not add mesh to fields (most likely already a mesh')
                end
            end
        end        
       Struct = Struct1; 
    if isfield(Struct1,'datastoragemode')&&strcmp(Struct1.datastoragemode,'columns')
           Struct.DataDescription = [Struct.DataDescription, ' ( OBTAINED FROM MERGING SEVERAL FILES )'];
    end
else
    Struct = Struct1;
    SF_core_log('dd','Warning in SFcore_MergeStructures : empty structure')
end

