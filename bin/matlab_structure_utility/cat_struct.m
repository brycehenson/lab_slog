function C = cat_struct(dim, varargin)
%% CAT_STRUCT Concatenation of (non-similar) structures
%
% Syntax:
%     C = CAT_STRUCT(dim, A, B)
%     C = CAT_STRUCT(dim, A1, A2, A3, A4, ...)
%
% Input:
%     dim      - dimension to concatenate along, positive integer
%     A,B...   - structures to concatenate
%
% Output:
%     C        - concatenated output struct
%
% Comments:
%     Combines multiple structures into a single structure array. Missing
%     fieldnames in the structures are set empty.
%
% See also cat, struct, fieldnames

%   Created by: Johan Winges
%   $Revision: 1.0$  $Date: 2014-10-16 10:00:00$

%% Concatenate structures:

% Find fieldnames of all structures:
struct2fieldnames = cellfun(@(structIn) fieldnames(structIn), varargin,'un',0);
uniqueFieldnames  = unique(cat(1, struct2fieldnames{:}));

% Find which fields are present in which structures:
struct2IsUniqName = cellfun(@(fname) ismember(uniqueFieldnames, fname), ...
    struct2fieldnames,'un',0);

% Add unique fieldnames to all strucutres which do not have them:
nStruct     = length(varargin);
for iStruct = 1:nStruct
   % Find any unique fieldnames, for each non-existing name, add it:
   tmpIdxNotUniq = find(~struct2IsUniqName{iStruct});
   for iIdx = 1:length(tmpIdxNotUniq)
      % Loop over numel in input structs to handle array structures:
      tmpNumel = numel(varargin{iStruct});
      for iNumel = 1:tmpNumel
         varargin{iStruct}(iNumel).(uniqueFieldnames{tmpIdxNotUniq(iIdx)}) = [];
      end
   end
end

% Use cat to concatenate the now similar structures:
C = cat(dim, varargin{:});
% Note, input dimension control is done by cat. 