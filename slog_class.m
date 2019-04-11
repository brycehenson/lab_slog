classdef slog_class < handle
    
    properties
        %define default parameters
        slog_fid
        level='log'; %this can change
        teir='development'; %dont want this to change when log is open
        operation 
        parameters
        log_dir='.'
        log_entry
        log_open=false;
        log_time_iso=''; %will be private
        log_time_posix=NaN; %will be private
        log_enviornment=[];
    end
    methods
        function open_log(obj,vargin) %single input argument, auto_flush
            if nargin<2
                auto_flush=false;
            else
                auto_flush=vargin(1);
            end
          
            log_file_str=fullfile(obj.log_dir,...
            sprintf('example_log_%s.slog',datestr(datetime('now'),'yyyymmddTHHMMSS')));
            if auto_flush
                obj.slog_fid=fopen(log_file_str,'a'); %auto flushing
            else
                obj.slog_fid=fopen(log_file_str,'A'); %do not auto fush
            end
            obj.log_open=true;
            obj.operation='start_log';
            %obj.get_time;
            obj.get_envionment; %will do auto in write log if write enviornment
            obj.write_log(true);
            
        end
        function get_envionment(obj)
            obj.log_enviornment=[];
            obj.log_enviornment.tier=obj.teir; %'development','testing,'model','production'
            obj.log_enviornment.computer_name=getComputerName();
            obj.log_enviornment.architecture=computer('arch');        
            [~,obj.log_enviornment.network_interfaces]=MACAddress(1);
            obj.log_enviornment.current_folder=pwd;
        end
        function get_time(obj)
            nowdt=datetime('now','TimeZone','local','Format', 'yyyy-MM-dd HH:mm:ss.SSSxxxxx');
            obj.log_time_iso=strrep(char(nowdt),' ','T');
            obj.log_time_posix=posixtime(nowdt);
            
        end
        function write_log(obj,vargin)
            if nargin<2
                write_enviornment=false;
            else
                write_enviornment=vargin(1);
            end
            %if the time is not there already set the time
            if isnan(obj.log_time_posix) %|| isequal(obj.log_time_iso,'')
                obj.get_time
            end
            if isempty(obj.operation) || isequal(obj.operation,'')
                error('operation must be specified')
            end
            if obj.log_open
                obj.log_entry.time_iso=obj.log_time_iso;
                obj.log_entry.time_posix=obj.log_time_posix;
                if write_enviornment
                    if isempty(obj.log_enviornment)
                        obj.get_envionment;
                    end
                    obj.log_entry.enviornment=obj.log_enviornment;
                end
                obj.log_entry.operation=obj.operation;
                if ~isempty(obj.parameters)
                    obj.log_entry.parameters=obj.parameters;
                end
                log_str=sprintf('%s\n',jsonencode(obj.log_entry)); %so that can print to standard out
                fprintf(obj.slog_fid,log_str);
                %clean up what was written for the log
                obj.log_entry=[];
                obj.parameters=[];
                obj.operation=[];
                obj.log_time_iso='';
                obj.log_time_posix=NaN;
            else
                %would like to open the log if it not already open, however it is a bit messy to make this
                %open comand not change the class
                error('you must open the log first with obj.open_log')
                %warning('log not open, it will now be opened')
                %obj.open_log;
                %obj.write_log;
            end
        end
        function close_log(obj)
            fclose(obj.slog_fid);
            obj.slog_fid=[];
            obj.log_open=false;
        end

        function set.teir(obj,value)
            if obj.log_open && ~isequal(obj.teir,value)
                error('cannot change teir while log is open')
            elseif sum(cellfun(@(x) isequal(x,value),{'development','testing','model','production'}))==1
                obj.teir=value;
            else
                error('teir must be must be "development","testing","model","production"')
            end
        end
        function set.level(obj,value)
            if isequal('error',value)
                warning('error has been changed to all uppercase ERROR')
                value='ERROR';
            end
            if sum(cellfun(@(x) isequal(x,value),{'log','ERROR','data','analysis'}))==1
                obj.level=value;
            else
                error('log level must be "log","ERROR","data" or "analysis"')
            end
            %
        end
         function set.log_dir(obj,value)
            if isfolder(value)
                obj.log_dir=value;
            else
                error('log_dir is not a folder')
            end
        end
    end
    
end