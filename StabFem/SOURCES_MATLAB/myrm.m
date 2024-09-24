function myrm(file)
% This is a platform-independent tool to delete a file

if(exist(file)||length(strfind(file,'*'))>0)
	if (isunix || ismac)
	    command = ['rm ', file];
	    system(command);
	end

	if (ispc)
	    c1 = ['del /q '];
	    c2 = [file];
	    c2 = strrep(c2, '/', '\');
	    command = [c1, c2];
	    system(command);
	end
else
    mydisp(10,['Warning in myrm : file ',file,'does not exist'])  
end

end