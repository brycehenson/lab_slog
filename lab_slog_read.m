classdef lab_slog_read < handle & matlab.mixin.Copyable % inherit from handle class, and make it copyable

    properties
        %interfacing vars
        dir='.'
        assume_done_time=1e2; % in seconds
        verbose=3;
    end
    % read only vars
    properties (SetAccess  = protected)
        %interfacing vars
        log_files={};
        log_files_cache={};
    end    
    methods
        
        function set.dir(obj,value)
            if isfolder(value)
                obj.dir=value;
            else
                error('log_dir is not a folder')
            end
        end
        
        function value=get.log_files(obj)
            dir_search=dir(fullfile(obj.dir,'*.labslog'));
            dir_search_struct=struct_tensor_to_struct_of_tensor(dir_search,0);
            dir_search_struct.bytes=cell2mat(dir_search_struct.bytes);
            dir_search_struct.isdir=cell2mat(dir_search_struct.isdir);
            is_dir_mask=~dir_search_struct.isdir;
            dir_search_struct=structfun(@(x) x(is_dir_mask),dir_search_struct,'UniformOutput',false);
            info_struct=cellfun(@name_to_info_struct,dir_search_struct.name,'UniformOutput',0);
            info_struct=cell_tensor_of_struct_to_struct_of_tensor(info_struct,0);
            info_struct.valid=cell2mat(info_struct.valid);
            
            info_struct.bytes=dir_search_struct.bytes;
            info_struct.folder=dir_search_struct.folder;
            if any(~info_struct.valid)
                warning('(%u) file(s) with .slog extension with an invalid filename has been removed from results',sum(~info_struct.valid))
                is_valid_mask=~~info_struct.valid;
                info_struct=recursive_structfun(@(x) x(is_valid_mask),info_struct);
            end
            %dir_search.Names
            value=info_struct;
            obj.log_files_cache=info_struct;
        end
        
        function value=get.log_files_cache(obj)
            if isempty(obj.log_files_cache)
                obj.log_files;
            end
            value=obj.log_files_cache;
        end
        
        
        function formated_lines=read_single_log(obj,selection)
            % todo
            % add .slog to end if not there
            
            if isnumeric(selection)
                if selection>numel(obj.log_files_cache.raw_name) 
                    error('out of allowed index')
                end
                selection=obj.log_files_cache.raw_name{selection};
            elseif ~( isstring(selection) || ischar(selection))
                error('selection not recognised')
            end
            % load all the log entries
            file_path=fullfile(obj.dir,selection);
            fid = fopen(file_path,'r');
            raw_lines=textscan(fid,'%s','Delimiter','\n');
            fclose(fid);
            num_lines=size(raw_lines{1},1);
            formated_lines=cell(num_lines,1);
            if obj.verbose>1
                output_chars=fprintf('line %u of %u',0,num_lines);
            end
            for ii=1:num_lines
                if obj.verbose>1 && mod(ii,100)==0
                    fprintf(repmat('\b',[1,output_chars]));
                    output_chars=fprintf('reading in log line  %4u of %4u',ii,num_lines);
                end
                raw_line_single=raw_lines{1}{ii};
                formated_lines{ii}=jsondecode(raw_line_single);
            end
            fprintf('\n')
        end
        
        function cell_of_logs=read_all_logs(obj)
            num_valid_files=sum(obj.log_files_cache.valid);
            valid_indicies=find(obj.log_files_cache.valid);
            cell_of_logs=cell(num_valid_files,1);
            for ii=1:num_valid_files
                if obj.verbose>1
                    fprintf('reading in log file %4u of %4u \n',ii,num_valid_files);
                end
                cell_of_logs{ii}=obj.read_single_log(valid_indicies(ii));
            end    
            if obj.verbose>1
                fprintf('\ndone\n')
            end
        end
        
    end %methods
    methods (Access  = protected)

    end %private methods
    
end


function struct_out=name_to_info_struct(fname_in)
%unnamed_log__brycelap__20200330T171035.090+1100_to_20200330T171036.851+1100.slog
struct_out=[];
struct_out.valid=true;
struct_out.raw_name=fname_in;

expected_extension='.labslog';
[filepath,fname_proc,struct_out.extension]=fileparts(fname_in);
if ~isempty(filepath)
    error('file path should be empty')
end

if ~strcmp(struct_out.extension,expected_extension)
    error('estension is not %s as expected',struct_out.extension)
    struct_out.valid=false;
end
fname_split=split(fname_proc,'__');
if numel(fname_split)>3
    warning('the file name :\n %s \n contains more than 2 double underscores "__"',struct_out.raw_name)
    struct_out.valid=false;
end
if numel(fname_split)<2
    warning('the file name :\n %s \n contains less than 2 double underscores "__"',struct_out.raw_name)
    struct_out.valid=false;
end
if struct_out.valid
    struct_out.log_name=fname_split{1};
    struct_out.computer_name=fname_split{2};

    times_raw=fname_split{3};
    times_split=split(times_raw,'_to_');

    times_start_str=times_split{1};
    times_end_str=times_split{2};
    struct_out.time.start.str=times_start_str;
        struct_out.time.end.str=times_end_str;
    try % if   the datecode cant be proecessed set it to nan
        time.start_obj=datetime(times_start_str(1:end-5),...
            'Format', 'yyyyMMdd''T''HHmmss.SSS','TimeZone',times_start_str(end-5+1:end));
         struct_out.time.start.posix=posixtime(time.start_obj);
    catch
         struct_out.time.start.posix=nan;
        struct_out.valid=false;
    end

    if strcmp(times_end_str,'inf') % catch the inf case which means that the log has not been closed properly
        struct_out.time.end.posix=inf;
    else
        try
            time.end_obj=datetime(times_end_str(1:end-5),...
                'Format', 'yyyyMMdd''T''HHmmss.SSS','TimeZone',times_end_str(end-5+1:end));
            struct_out.time.end.posix=posixtime(time.end_obj);
        catch
            struct_out.time.end.posix=nan;
            struct_out.valid=false;
        end
    end
end


end


