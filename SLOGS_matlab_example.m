folder = fileparts(which(mfilename));
% Add that folder plus all subfolders to the path.
addpath(genpath(folder));


%%
log_dir='.';
log_file_str=fullfile(log_dir,...
    sprintf('example_log_%s.slog',datestr(datetime('now'),'yyyymmddTHHMMSS')));
flog=fopen(log_file_str,'A'); %or a for auto flushing
nowdt=datetime('now','TimeZone','local','Format', 'yyyy-MM-dd HH:mm:ss.SSSxxxxx');
log=[];
log.time_iso=strrep(char(nowdt),' ','T');
log.time_posix=posixtime(nowdt);
%log level, can be 'log','ERROR','data','analysis'
log.level='log';

log.environment.tier='development'; %'development','testing,'model','production'
log.environment.architecture=computer('arch');
log.environment.computer_name=getComputerName();
%log.environment.macs=MACAddress(1);
[~,log.environment.network_interfaces]=MACAddress(1);

log.operation='demonstrating how to use SLOGS';
log.parameters.photodiode_power=rand(1);
log.parameters.drive_voltage=log.parameters.photodiode_power^2+rand(1);
log.parameters.feedback_error=log.parameters.photodiode_power-1;
log.parameters.feedback_loop_time=rand(1)/10;

log_str=sprintf('%s\n',jsonencode(log)); %so that can print to standard out
fprintf(flog,log_str);

fclose(flog);

