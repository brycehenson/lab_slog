classdef slog_read_class < handle & matlab.mixin.Copyable % inherit from handle class, and make it copyable

    properties
        %interfacing vars
        dir='.'
        assume_done_time=1e2; % in seconds
    end
    % read only vars
    properties (SetAccess  = protected)
        %interfacing vars
        log_files={};
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
            dir_search=dir(fullfile(obj.dir,'*.slog'));
            dir_search_struct=tensor_of_struct_to_struct_of_tensor(dir_search,false)
            fnames= {dir_search.name};
            info_structs=cellfun(@name_to_info_struct,fnames)
            %dir_search.Names
            value=dir_search;
            
        end
        
        
        
    end %methods
    methods (Access  = protected)

    end %private methods
    
end


function struct_out=name_to_info_struct(fname_in)
%unnamed_log__brycelap__20200330T171035.090+1100_to_20200330T171036.851+1100.slog
struct_out=[];
extension='.slog';
if ~strcmp(fname_in(end-numel(extension)+1:end),extension)
    error('estension is not %s as expected',extension)
end
struct_out.extension=extension;
fname_proc=fname_in(1:end-numel(extension))
fname_split=split(fname_proc,'__');
if numel(fname_split)>3
    error('the file name contains more than 2 double underscores "__"')
end
struct_out.log_name=fname_split{1};
struct_out.computer_name=fname_split{2};
times_raw=fname_split{3};
times_split=split(times_raw,'_to_');

times_start_str=times_split{1};
times_end_str=times_split{2};

time_start_obj=datetime(times_start_str(1:end-5),...
    'Format', 'yyyyMMdd''T''HHmmss.SSS','TimeZone',times_start_str(end-5+1:end));
times_start_posix=posixtime(time_start_obj);

time_end_obj=datetime(times_end_str(1:end-5),...
    'Format', 'yyyyMMdd''T''HHmmss.SSS','TimeZone',times_end_str(end-5+1:end));
times_end_posix=posixtime(time_end_obj);

struct_out.time_start_str=times_start_str;
struct_out.time_start_posix=times_start_posix;
struct_out.time_end_str=times_end_str;
struct_out.time_end_posix=times_end_posix;


end


