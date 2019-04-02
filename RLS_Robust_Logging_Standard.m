folder = fileparts(which(mfilename));
% Add that folder plus all subfolders to the path.
addpath(genpath(folder));


%%
log_dir='.';
log_file_str=fullfile(log_dir,...
    sprintf('example_log_%s.txt',datestr(datetime('now'),'yyyymmddTHHMMSS')));
flog=fopen(log_file_str,'A'); %or a for auto flushing
nowdt=datetime('now','TimeZone','local','Format', 'yyyy-MM-dd HH:mm:ss.SSSxxxxx');
log=[];
log.time_iso=strrep(char(nowdt),' ','T');
log.time_posix=posixtime(nowdt);
%log level, can be 'log','ERROR','data','analysis'
log.level='log';

log.env.tier='development'; %'development','testing,'model','production'
log.env.arch=computer('arch');
log.env.computer_name=getComputerName();
%log.env.macs=MACAddress(1);
[~,log.env.network_interfaces]=MACAddress(1);

log.operation='making logs easy';
log.parameters.thing=rand(1);

log_str=sprintf('%s\n',jsonencode(log)); %so that can print to standard out
fprintf(flog,log_str);

fclose(flog);

