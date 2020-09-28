%test_slog_read


folder = fileparts(which(mfilename));
addpath(genpath(folder));
% note this is not the best as it adds a bunch of .git folders to the path, for larger projects use
% set_up_project_path in Core_BEC_Analysis

%%

rs=lab_slog_read;
rs.dir='./test';
%%
% read in a single file
b=rs.read_single_log(1)

%%
b=rs.read_all_logs

