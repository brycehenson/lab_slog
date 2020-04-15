function result = stresc(string)
% function result = stresc(string)
%   returns a string with special characters "escaped"
%
%   i.e., the string "Randy's wonton\n % delicious!" becomes
%         "Randy''s wonton \\n %% delicious!". 
%
%   Thus, the resulting string is suitable to be printed out and
%   interpreted by MATLAB. This function is especially useful if you are
%   writing code intended to produce code. Interpreted strings can be
%   freely placed into your code without worry of strings breaking code.
%
%   The following conversions are made:
%       % becomes %%
%       \ becomes \\
%       ' becomes ''
%       
%   Example Usage:
%       myString = inputdlg('Please enter a string you want printed',...
%           'Test StrEsc');
%       fprintf('%s\n', stresc(myString{1})); % original string, escaped
%       fprintf('fprintf(''%s'');\n', myString{1}); % won't work for all strings
%       fprintf('fprintf(''%s'');\n', stresc(myString{1}));

result = regexprep(string, '%', '%%');
result = regexprep(result, '\\', '\\\');
result = regexprep(result, '''', '''''');

end