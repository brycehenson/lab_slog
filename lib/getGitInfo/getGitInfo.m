function gitInfo=getGitInfo(varargin)
% Get information about the Git repository in the current directory, including: 
%          - branch name of the current Git Repo 
%          - Git SHA1 HASH of the most recent commit
%          - url of corresponding remote repository, if one exists
%
% This version has been improved by Bryce Henson 
% 
% - allow the .git folder in a particular directory to be read.
%   - The previous version found any .git in the path which is problmatic if there are lot of git's in your path.
% - deal with submodules



% inputs
% git_path  -  set the directory of the git which you want to retreive the
% information from (optional, default is current dir)


% The function first checks to see if a .git/ directory is present. If so it
% reads the .git/HEAD file to identify the branch name and then it looks up
% the corresponding commit.
%
% It then reads the .git/config file to find out the url of the
% corresponding remote repository. This is all stored in a gitInfo struct.
%
% Note this uses only file information, it makes no external program 
% calls at all. 
%
% This function must be in the base directory of the git repository
%
% Released under a BSD open source license. Based on a concept by Marc
% Gershow.
%
% Andrew Leifer
% Harvard University
% Program in Biophysics, Center for Brain Science, 
% and Department of Physics
% leifer@fas.harvard.edu
% http://www.andrewleifer.com
% 12 September 2011
%
% Bryce Henson
% He* BEC Group, Laser Physic Centre, Australian National University
% March 2020

%
% TODO
% -[x] add dir as input
% -[ ] do testing to see how submodules branch name changes
% -[ ] standard function header format


p = inputParser;
addOptional(p,'git_path',pwd,@(x) ischar(x) || isstring(x) )
addOptional(p,'verbose',0,@isnumeric)

parse(p,varargin{:})
git_path=p.Results.git_path;
verbose=p.Results.verbose;

submodule=false;

gitInfo=[];
% if it is a submodule the git folder exists somewhere given in the contents of file .git
if isfile(fullfile(git_path,'.git'))
    str_git_file=fileread(fullfile(git_path,'.git'));
    str_git_file=split(str_git_file,newline);
    str_git_file=str_git_file{1};
    start_of_file='gitdir: ';
    if strcmp(str_git_file(1:numel(start_of_file)),start_of_file)
        str_git_file=str_git_file(numel(start_of_file)+1:end);
        git_path=fullfile(git_path,str_git_file);
        submodule=true;
    else
        error('could not parse git submodule')
    end
else
    git_path=fullfile(git_path,'.git');
end


if ~isfolder(git_path)  || ~isfile(fullfile(git_path,'HEAD'))
    %Git is not present
    warning('git not present at \n %s \n returing empty output',git_path)
    return
end

% read in the head file
% if detached this will contain the hash
% if attached it will contain the branch
headtext=fileread(fullfile(git_path,'HEAD'));
headparsed=textscan(headtext,'%s');
git_detached=false;

if ~strcmp(headparsed{1}{1},'ref:') && length(headparsed{1}{1})==40
    git_detached=true;
    git_hash=headparsed{1}{1};  
    branch_name='HEAD detached';
elseif  strcmp(headparsed{1}{1},'ref:')
    git_detached=false;
    path=headparsed{1}{2};
    [branch_path, branch_name, branch_ext]=fileparts(path);
    if ~isempty(branch_ext)
        error('the beanch extension from the head file should be empty')
    end
elseif ~ (length(headparsed{1})>1)
    warning('git head file at \n %s \n is empty',fullfile(git_path,'HEAD'))
end

%Read in config file
config=fileread(fullfile(git_path,'config'));
%Find everything space delimited
tempparsed=textscan(config,'%s','delimiter','\n');
config_lines=tempparsed{1};
        

if ~git_detached
    % use the previously read in branch_path to  tell us the location of the file
    %containing the SHA1
    %Read in SHA1
    SHA1text=fileread(fullfile(git_path,branch_path,branch_name));
    SHA1=textscan(SHA1text,'%s');
    git_hash=SHA1{1}{1};

    % process the config_lines
    remote='';
    %Lets find the name of the remote corresponding to our branchName
    for k=1:length(config_lines)
        %Are we at the section describing our branch?
        if strcmp(config_lines{k},['[branch "' branch_name '"]'])
            m=k+1;
            %While we haven't run out of lines
            %And while we haven't run into another section (which starts with
            % an open bracket)
            while (m<=length(config_lines) && ~strcmp(config_lines{m}(1),'[') )
                tempparsed=textscan(config_lines{m},'%s');
                if length(tempparsed{1})>=3
                    if strcmp(tempparsed{1}{1},'remote') && strcmp(tempparsed{1}{2},'=')
                        %This is the line that tells us the name of the remote 
                        remote=tempparsed{1}{3};
                    end
                end
                m=m+1;
            end
        end
    end
    
else
    
    remote='';
    %Lets find the name of any remote because we dont have a branch name
    for k=1:length(config_lines)
        %Are we at the section describing our branch?
        %['[branch "' branchName '"]']
        line_start='[branch "';
        line_end='"]';
        if numel(config_lines{k})>numel(line_start) && ...
                strcmp(config_lines{k}(1:numel(line_start)),line_start)
            % we could override branch_name with the branch nae found here
            % but this is not correct as it is only a branch we could attach too
            %branch_name=config_lines{k}(numel(line_start)+1:end-numel(line_end));
            m=k+1;
            %While we haven't run out of lines
            %And while we haven't run into another section (which starts with
            % an open bracket)
            while (m<=length(config_lines) && ~strcmp(config_lines{m}(1),'[') )
                tempparsed=textscan(config_lines{m},'%s');
                if length(tempparsed{1})>=3
                    if strcmp(tempparsed{1}{1},'remote') && strcmp(tempparsed{1}{2},'=')
                        %This is the line that tells us the name of the remote 
                        remote=tempparsed{1}{3};
                    end
                end
                m=m+1;
            end
        end
    end  
end

url='';
%Find the remote's url
for k=1:length(config_lines)
    %Are we at the section describing our branch?
    if strcmp(config_lines{k},['[remote "' remote '"]'])
        m=k+1;
        %While we haven't run out of lines
        %And while we haven't run into another section (which starts with
        % an open bracket)
        while (m<=length(config_lines) && ~strcmp(config_lines{m}(1),'[') )
            tempparsed=textscan(config_lines{m},'%s');
            if length(tempparsed{1})>=3
                if strcmp(tempparsed{1}{1},'url') && strcmp(tempparsed{1}{2},'=')
                    %This is the line that tells us the name of the remote 
                    url=tempparsed{1}{3};
                end
            end
            m=m+1;
        end
    end
end


gitInfo.branch=branch_name;
gitInfo.hash=git_hash;
gitInfo.remote=remote;
gitInfo.url=url;
gitInfo.is_submodule=submodule;

end



% Copyright 2011 Andrew Leifer. All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without modification, are
% permitted provided that the following conditions are met:
% 
%    1. Redistributions of source code must retain the above copyright notice, this list of
%       conditions and the following disclaimer.
% 
%    2. Redistributions in binary form must reproduce the above copyright notice, this list
%       of conditions and the following disclaimer in the documentation and/or other materials
%       provided with the distribution.
% 
% THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ''AS IS'' AND ANY EXPRESS OR IMPLIED
% WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
% ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
% ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% The views and conclusions contained in the software and documentation are those of the
% authors and should not be interpreted as representing official policies, either expressed
% or implied, of <copyright holder>.



