function sout=parse_logs_into_struct(imported_logs)

verbose=1;

sout=struct();

num_logs=numel(imported_logs);
for ii=1:num_logs
    this_log=imported_logs{ii};
    num_lines=numel(this_log);
    sout_layer1_feilds=fieldnames(sout);
    
    this_line=this_log{1};
    this_comp_name=this_line.environment.computer_name;
    if ~isvarname(this_comp_name)
        this_comp_name=make_valid_var_name(this_comp_name);
        if ~any(strcmp(this_comp_name,sout_layer1_feilds))
            warning('computer name was not a valid struct field name it has been changed to \n%s\n',this_comp_name)
        end
    end
    if ~any(strcmp(this_comp_name,sout_layer1_feilds))
        sout.(this_comp_name)=struct();
    end
    
    if ~isempty(fieldnames(sout.(this_comp_name)))
        % check if the env is the same
    else
        sout.(this_comp_name).environment=this_line.environment;
    end
        

    
    for jj=2:num_lines
        sout_layer2_feilds=fieldnames(sout.(this_comp_name));
        this_line=this_log{jj};
        this_loglevel=this_line.level;
        
        if ~isvarname(this_loglevel)
            this_loglevel=make_valid_var_name(this_loglevel);
            %warning('level name was not a valid struct feild name it has been changed to \n%s\n',this_loglevel)
        end
        
        if ~strcmp(this_loglevel,'slog_log')
            if ~any(strcmp(this_loglevel,sout_layer2_feilds))
                sout.(this_comp_name).(this_loglevel)=struct();
            end

            sout_layer3_feilds=fieldnames(sout.(this_comp_name).(this_loglevel));
            this_operation=this_line.operation;

            if ~isvarname(this_operation)
                this_operation=make_valid_var_name(this_operation);
                %warning('operation name was not a valid struct feild name it has been changed to \n%s\n',this_loglevel)
            end

            if ~any(strcmp(this_operation,sout_layer3_feilds))
                sout.(this_comp_name).(this_loglevel).(this_operation)=struct();
            end

            if ~isempty(fieldnames( sout.(this_comp_name).(this_loglevel).(this_operation) ))
                %append to the arrays
                num_times=numel(sout.(this_comp_name).(this_loglevel).(this_operation).time_posix);
                sout.(this_comp_name).(this_loglevel).(this_operation).time_posix(num_times+1)=this_line.time_posix;
                num_params=numel(sout.(this_comp_name).(this_loglevel).(this_operation).parameters);
                if num_times~=num_params
                    error('num entries should match')
                end
                sout.(this_comp_name).(this_loglevel).(this_operation).parameters{num_params+1}=this_line.parameters;
            else
                 sout.(this_comp_name).(this_loglevel).(this_operation).time_posix=this_line.time_posix;
                 sout.(this_comp_name).(this_loglevel).(this_operation).parameters=cell(1,1);
                 sout.(this_comp_name).(this_loglevel).(this_operation).parameters{1}=this_line.parameters;
            end
        end
        
    end
end