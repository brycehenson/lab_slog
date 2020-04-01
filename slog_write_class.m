classdef slog_write_class < handle & matlab.mixin.Copyable % inherit from handle class, and make it copyable
    % the level propety is a little complicated becasue matalb does not allow a seperate private set method
    % which I want so that the 
    properties
        %interfacing vars
        level='log'; %this can change
        teir='development'; %dont want this to change when log is open
        log_dir='.'
        git_dir=[]; %path to the git directory
        code_version=[];
        auto_flush=false;
        new_log_file_entries=1e4;
        new_log_file_bytes=1*(2^20); %50*2^20;
        new_log_logical=false; %provides a way to force a new log file, this is a good idea if the controling program has some time to wait
        % set below to private
        slog_num_entries=0;
        log_open=false;  
        log_time_iso='';
        log_time_posix=NaN; 
        
    end
    properties (NonCopyable)
        log_name=[];
        operation 
        parameters
        slog_fid 
        log_entry 
        log_environment=[];
    end
    properties (Dependent)
    	level_dep %this will be equal to the public level class level_private 
                   % is not empty in which case it will be equal to level_private 
    end
    properties (SetAccess  = protected)
    	level_private=[];
        log_file=[];
        hold_open=false;
    end
    methods
        function value = get.level_dep(obj)
            % this is a workaround because matlab does not allow both private/internal and public set methods
            if isempty(obj.level_private)
                value = obj.level;
            else
                value=obj.level_private;
            end
        end
 
        function set.level_private(obj,value)
            value=lower(value); %lowercase because fuck caps
            if sum(cellfun(@(x) isequal(x,value),{'slog log','slog error',[]}))==1
                obj.level_private=value;
            else
                error('SLOG class internal error, log level must be "slog log","slog error" or empty')
            end
        end
        
        function open_log(obj) %single input argument, auto_flush
            
            if isempty(obj.log_name)
                tmp_log_name='unnamed_log';
            else
                tmp_log_name=obj.log_name;
            end
            obj.log_file.log_name=tmp_log_name;
            
            %get the enviorment vars, will use comp name in log fname
            obj.get_envionment;
            
            nowdt=datetime('now','TimeZone','local','Format', 'yyyy-MM-dd''T''HH:mm:ss.SSSxxxxx');
            time_str_tmp=char(nowdt);
            %time_str_tmp=strrep(time_str_tmp,' ','T');
            time_str_tmp=strrep(time_str_tmp,':','');
            time_str_tmp=strrep(time_str_tmp,'-','');
            obj.log_file.time_str_start=time_str_tmp;
            obj.log_file.time_str_end='inf';
            obj.log_file.comp_name=obj.log_environment.computer_name;
            obj.log_file.fname_str=sprintf('%s__%s__%s_to_%s.slog',...
                obj.log_file.log_name,obj.log_file.comp_name,...
                obj.log_file.time_str_start,obj.log_file.time_str_end);
            if count(obj.log_file.fname_str,'__')>2
                error('file name has more than 2 double unnderscores, this will prevent reading')
            end
            obj.log_file.log_dir=obj.log_dir;
            obj.log_file.path_str=fullfile(obj.log_file.log_dir,obj.log_file.fname_str);
            if obj.auto_flush
                obj.slog_fid=fopen(obj.log_file.path_str,'a'); %auto flushing
            else
                obj.slog_fid=fopen(obj.log_file.path_str,'A'); %do not auto fush
            end
            obj.log_open=true;
            obj.operation='start log';
            obj.level_private='slog log';
            %obj.get_time;
            obj.write_log_private('write_environment',true);
        end
        
        function get_envionment(obj)
            obj.log_environment=[];
            obj.log_environment.tier=obj.teir; %'development','testing,'model','production'
            obj.log_environment.computer_name=getComputerName();
            obj.log_environment.architecture=computer('arch');      
            obj.log_environment.programming_language='matlab';
            %get the matlab version number
            obj.log_environment.language_version=version;
            % if a git dir has not been specified and there is one in the current dir then return the info for that
            if isempty(obj.git_dir) && isfolder(fullfile(pwd,'.git'))
                    obj.git_dir='.';
            end
            if ~isempty(obj.git_dir)
                obj.log_environment.git_info=getGitInfo(obj.git_dir);
            end
            if ~isempty(obj.code_version)
                obj.log_environment.code_version=obj.code_version;
            end
            [~,obj.log_environment.network_interfaces]=MACAddress(1);
            obj.log_environment.current_folder=pwd;
        end
        
        function get_time(obj)
            nowdt=datetime('now','TimeZone','local','Format', 'yyyy-MM-dd''T''HH:mm:ss.SSSxxxxx');
            %obj.log_time_iso=strrep(char(nowdt),' ','T');
            obj.log_time_posix=posixtime(nowdt);
            
        end
        
        function write_log(obj)
            obj.write_log_private
        end
        
        function close_log(obj)
            
            % write an entry closing the log
            obj.operation='end log';
            obj.level_private='slog log';
            %obj.get_time;
            obj.get_envionment; %will do auto in write log if write environment
            obj.write_log_private('write_environment',true,'invoked_by_close',true);
            
            fclose(obj.slog_fid);
            obj.slog_fid=[];
            % now rename the file to give the end of the log time range
            
            nowdt=datetime('now','TimeZone','local','Format', 'yyyy-MM-dd''T''HH:mm:ss.SSSxxxxx');
            time_str_tmp=char(nowdt);
            %time_str_tmp=strrep(time_str_tmp,' ','T');
            time_str_tmp=strrep(time_str_tmp,':','');
            time_str_tmp=strrep(time_str_tmp,'-','');
            obj.log_file.time_str_end=time_str_tmp;
            
            log_file_old=obj.log_file.path_str;
            obj.log_file.fname_str=sprintf('%s__%s__%s_to_%s.slog',...
                obj.log_file.log_name,obj.log_file.comp_name,...
                obj.log_file.time_str_start,obj.log_file.time_str_end);
            log_file_new=fullfile(obj.log_file.log_dir, obj.log_file.fname_str);
            
            movefile(log_file_old,log_file_new)
            
            obj.log_open=false;
            obj.slog_num_entries=0;
        end

        function set.teir(obj,value)
            value=lower(value); %lowercase
            if obj.log_open && ~isequal(obj.teir,value)
                error('cannot change teir while log is open')
            elseif sum(cellfun(@(x) isequal(x,value),{'development','testing','staging','production'}))==1
                obj.teir=value;
            else
                error('teir must be must be "development","testing","staging","production"')
            end
        end
        
        function set.log_name(obj,value)
            value=lower(value); %lowercase because fuck caps
            if obj.log_open && ~isequal(obj.log_name,value)
                error('cannot change teir while log is open')
            else
                obj.log_name=value;
            end
        end
        
        function set.auto_flush(obj,value)
            if ~islogical(value)
                error('value must be logical')
            end
            if obj.log_open && ~isequal(obj.auto_flush,value)
                error('cannot change auto_flush while log is open')
            else
                obj.auto_flush=value;
            end
        end
        
        function set.new_log_logical(obj,value)
            if ~islogical(value)
                error('value must be logical')
            end
            if ~obj.log_open && ~isequal(obj.new_log_logical,value)
                error('cannot change auto_flush while log is not open')
            else
                obj.new_log_logical=value;
            end
        end
        
        function set.level(obj,value)
            value=lower(value); %lowercase because fuck caps
            if sum(cellfun(@(x) isequal(x,value),{'log','error','data','analysis'}))==1
                obj.level=value;
            else
                error('log level must be "log","error","data" or "analysis"')
            end
        end
        
        function set.log_dir(obj,value)
            if isfolder(value)
                obj.log_dir=value;
            else
                error('log_dir is not a folder')
            end
        end
        
        function set.git_dir(obj,value)
            if isfolder(value)
                obj.git_dir=value;
            else
                error('log_dir is not a folder')
            end
        end
        
        function delete(obj)
            if obj.log_open && ~obj.hold_open
                obj.close_log;
            end
        end 
        
        
        
    end %methods
    methods (Access  = protected)
        function write_log_private(obj,varargin)
            p = inputParser;
            addOptional(p,'write_environment',false,@islogical)
            addOptional(p,'invoked_by_close',false,@islogical)
            parse(p,varargin{:})
            write_environment=p.Results.write_environment;
            invoked_by_close=p.Results.invoked_by_close;
            

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
                if write_environment && ~isempty(obj.log_environment)
                    obj.get_envionment;
                end
                if ~isempty(obj.log_environment)
                    obj.log_entry.environment=obj.log_environment;
                    obj.log_environment=[]; %clear it bc it could change
                end
                obj.log_entry.level=obj.level_dep;
                obj.log_entry.operation=obj.operation;
                if ~isempty(obj.parameters)
                    obj.log_entry.parameters=obj.parameters;
                end
                log_str=sprintf('%s\n',jsonencode(obj.log_entry)); %so that can print to standard out
                fprintf(obj.slog_fid,log_str);
                %increment the entry counter;
                obj.slog_num_entries=obj.slog_num_entries+1;
                %clean up what was written for the log
                obj.level_private=[];
                obj.log_entry=[];
                obj.parameters=[];
                obj.operation=[];
                obj.log_time_iso='';
                obj.log_time_posix=NaN;
                
                if ~invoked_by_close && ...
                        ( (ftell(obj.slog_fid)> obj.new_log_file_bytes) || ...
                            (obj.slog_num_entries> obj.new_log_file_entries) ...
                        )
                	obj.new_log_logical=true;
                end
                if obj.new_log_logical
                    obj.new_log_logical=false;
                    % manual copy
                    %bad idea just seeing if any speed can be had
%                     temp_new_obj=slog_write_class;
%                     temp_new_obj.level=obj.level;
%                     temp_new_obj.teir=obj.teir;
%                     temp_new_obj.log_dir=obj.log_dir;
%                     temp_new_obj.git_dir=obj.git_dir;
%                     temp_new_obj.code_version=obj.code_version;
%                     temp_new_obj.auto_flush=obj.auto_flush;
%                     temp_new_obj.new_log_file_entries=obj.new_log_file_entries;
%                     temp_new_obj.new_log_file_bytes=obj.new_log_file_bytes;

                    % auto copy
                    temp_new_obj=copy(obj);
                    temp_new_obj.fake_close_private; %pretend to close the file
                    open_log(temp_new_obj)
                    

                    % write an entry giving the file name of the new log
                    obj.operation='open new log';
                    obj.level_private='slog log';
                    obj.parameters.new_log=temp_new_obj.log_file;
                    if (ftell(obj.slog_fid)> obj.new_log_file_bytes)
                    	obj.parameters.new_log_reason='log file size';
                    elseif  (obj.slog_num_entries> obj.new_log_file_entries) 
                    	obj.parameters.new_log_reason='log num entries ';
                    else 
                        error('this condition should not be reached')
                    end
                    %obj.get_time;
                    obj.write_log_private('invoked_by_close',true);
                    
                    close_log(obj)
                    
                    obj.log_file=temp_new_obj.log_file;
                    obj.log_open=temp_new_obj.log_open;
                    obj.slog_fid=temp_new_obj.slog_fid;
                    obj.slog_num_entries=temp_new_obj.slog_num_entries;
                    temp_new_obj.hold_open=true; %prevents closing the new file when temp_new_obj is deleted
                    delete(temp_new_obj)
                    
                end
                
            else
                %would like to open the log if it not already open, however it is a bit messy to make this
                %open comand not change the class
                error('you must open the log first with obj.open_log')
                %warning('log not open, it will now be opened')
                %obj.open_log;
                %obj.write_log;
            end
        end
        function fake_close_private(obj)
            %used to mock clsing a copy of the class to open the new log
            % which can then be entered in the old log
             obj.log_open=false;
            obj.slog_num_entries=0;
        end
    end %private methods
    
end