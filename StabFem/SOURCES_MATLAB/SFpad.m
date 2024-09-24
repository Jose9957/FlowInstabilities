function str = SFpad(str, n)
%PAD Insert leading and trailing spaces
%
% This function is missing in Octave so we add it here.
%        
        if length(str)<n
        str = [str blanks(n-length(str))];
        end
       
end
