function DB = SF_SortDataBase(DB,field)
%
% This function is designed to sort the index of one folder in the database
% according to one field.
%
% Example :
% >> sfs = SF_Status;
% >> BF = sfs.Baseflow;
%     BF = 
%
%
% >> BF = SF_SortDataBase(BF,'Re');
%  the data fields will be reorders in ascending Re.

 if ~isstruct(DB)
    SF_core_log('e','SF_sortDataBase : invalid DB object. ')
 end

if (length(DB)>1)
 % DB is an array of structs
if ~isfield(DB(1),field)||~isnumeric(DB(1).(field))
    SF_core_log('e','SF_sortDataBase : Specified field is not valid')
end
SF_core_log('n',['sorting database (array of structs)  according to field ',field ]);
T = [ DB.(field) ];  
[~,I] = sort(T);

DB = DB(I);


else
 % DB is a struct of arrays
 if ~isfield(DB,field)||~isnumeric(DB.(field))
    SF_core_log('e','SF_sortDataBase : Specified field is not valid')
 end
  SF_core_log('n',['sorting database (struct of arrays) according to field ',field]);
[~,I] = sort(DB.(field));
fff = fieldnames(DB);
for j = 1:length(fff)
    ff = fff(j);
    ff = ff{1};
    DB.(ff) = DB.(ff)(I);
end

end
 
end
