
folder = fileparts(which(mfilename));
addpath(genpath(folder));
% note this is not the best as it adds a bunch of .git folders to the path, for larger projects use
% set_up_project_path in core_bec

%%
mkdir('test')

fclose('all');
%%test slog class
time_open=tic;
a=lab_slog_write;

a.teir='development';
a.log_dir='./test/';
a.git_dir='.'; % retreive info from the .git folder (branch name, commit hash, url)
a.auto_flush=false;
a.open_log;
time_open=toc(time_open);
fprintf('log open time %f\n',time_open)
time_prep_entry=tic;

%a.log_time %optional
%a.teir='model';%test that error is not returned when an error is not returned
a.level='error';
a.operation='writing out somenumbers';
a.parameters.thing_1=linspace(5,3,1e2);
a.parameters.thing_2=rand(1,10);
a.get_time;
time_prep_entry=toc(time_prep_entry);
fprintf('log prep entry time %f\n',time_prep_entry)
%a.write_log;

a.close_log;

%%

a=lab_slog_read;
a.dir='./test/';
files=a.log_files

single_log=a.read_single_log(1);


%%

fclose('all');
%%test slog class
time_open=tic;
a=lab_slog_write;

a.teir='development';
a.log_dir='./test/';
a.git_dir='.'; % retreive info from the .git folder (branch name, commit hash, url)
a.auto_flush=false;
a.open_log;
time_open=toc(time_open);
fprintf('log open time %f\n',time_open)
time_prep_entry=tic;

%a.log_time %optional
%a.teir='model';%test that error is not returned when an error is not returned
a.level='error';
a.operation='writing out somenumbers';
a.parameters.thing_1=linspace(5,3,1e2);
a.parameters.thing_2=rand(1,10);
a.get_time;
time_prep_entry=toc(time_prep_entry);
fprintf('log prep entry time %f\n',time_prep_entry)

time_log_write=tic;
a.write_log;
time_single_entry=toc(time_log_write);
fprintf('time to write single entry %f \n',time_single_entry)

log_times=[];
for ii=1:1.5e4
time_log_write=tic;
a.level='log';
a.operation='writing out some other numbers';
a.parameters.thing_1=linspace(5,3,1e2);
a.parameters.thing_2=rand(1,10);
a.write_log;
time_single_entry=toc(time_log_write);
log_times=cat(1,log_times,time_single_entry);
end

a.close_log;

fprintf('log write time min %f, mean %f, median %f, max %f  \n',...
    min(log_times),mean(log_times),median(log_times),max(log_times))

fprintf('log write freq  min %f, mean %f, median %f, max %f  \n',...
    min(1./log_times),mean(1./log_times),median(1./log_times),max(1./log_times))


