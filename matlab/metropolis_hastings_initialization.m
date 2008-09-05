function [ ix2, ilogpo2, ModelName, MhDirectoryName, fblck, fline, npar, nblck, nruns, NewFile, MAX_nruns, d ] = ...
        metropolis_hastings_initialization(TargetFun, xparam1, vv, mh_bounds, varargin)
% Metropolis-Hastings initialization.
% 
% INPUTS 
%   o TargetFun  [char]     string specifying the name of the objective
%                           function (posterior kernel).
%   o xparam1    [double]   (p*1) vector of parameters to be estimated (initial values).
%   o vv         [double]   (p*p) matrix, posterior covariance matrix (at the mode).
%   o mh_bounds  [double]   (p*2) matrix defining lower and upper bounds for the parameters. 
%   o varargin              list of argument following mh_bounds
%  
% OUTPUTS 
%   None  
%
% SPECIAL REQUIREMENTS
%   None.

% Copyright (C) 2006-2008 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

global M_ options_ bayestopt_

ModelName = M_.fname;

if ~isempty(M_.bvar)
    ModelName = [M_.fname '_bvar'];
end

bayestopt_.penalty = 1e8;

MhDirectoryName = CheckPath('metropolis');

nblck = options_.mh_nblck;
nruns = ones(nblck,1)*options_.mh_replic;
npar  = length(xparam1);
MAX_nruns = ceil(options_.MaxNumberOfBytes/(npar+2)/8);
d = chol(vv);

if ~options_.load_mh_file & ~options_.mh_recover
    %% Here we start a new metropolis-hastings, previous draws are not
    %% considered.
    if nblck > 1
        disp('MH: Multiple chains mode.')
    else
        disp('MH: One Chain mode.')
    end
    %% Delete old mh files...
    files = dir([ MhDirectoryName '/' ModelName '_mh*_blck*.mat']);
    if length(files)
        delete([ MhDirectoryName '/' ModelName '_mh*_blck*.mat']);
        disp('MH: Old _mh files successfully erased!')
    end
    file = dir([ MhDirectoryName '/metropolis.log']);
    if length(file)
        delete([ MhDirectoryName '/metropolis.log']);
        disp('MH: Old metropolis.log file successfully erased!')
        disp('MH: Creation of a new metropolis.log file.')
    end
    fidlog = fopen([MhDirectoryName '/metropolis.log'],'w');
    fprintf(fidlog,'%% MH log file (Dynare).\n');
    fprintf(fidlog,['%% ' datestr(now,0) '.\n']);
    fprintf(fidlog,' \n\n');
    fprintf(fidlog,'%% Session 1.\n');
    fprintf(fidlog,' \n');
    fprintf(fidlog,['  Number of blocks...............: ' int2str(nblck) '\n']);
    fprintf(fidlog,['  Number of simulations per block: ' int2str(nruns(1)) '\n']);
    fprintf(fidlog,' \n');
    %% Initial values...
    if nblck > 1% Case 1: multiple chains
        fprintf(fidlog,['  Initial values of the parameters:\n']);
        disp('MH: Searching for initial values...')
        ix2 = zeros(nblck,npar);
        ilogpo2 = zeros(nblck,1);
        for j=1:nblck
            validate	= 0;
            init_iter	= 0;
            trial = 1;
            while validate == 0 & trial <= 10
                candidate = rand_multivariate_normal( transpose(xparam1), d * options_.mh_init_scale, npar);
                if all(candidate(:) > mh_bounds(:,1)) & all(candidate(:) < mh_bounds(:,2)) 
                    ix2(j,:) = candidate;
                    ilogpo2(j) = - feval(TargetFun,ix2(j,:)',varargin{:});
                    fprintf(fidlog,['    Blck ' int2str(j) ':\n']);
                    for i=1:length(ix2(1,:))
                        fprintf(fidlog,['      params:' int2str(i) ': ' num2str(ix2(j,i)) '\n']);
                    end
                    fprintf(fidlog,['      logpo2: ' num2str(ilogpo2(j)) '\n']);
                    j = j+1;
                    validate = 1;
                end
                init_iter = init_iter + 1;
                if init_iter > 100 & validate == 0
                    disp(['MH: I couldn''t get a valid initial value in 100 trials.'])
                    disp(['MH: You should Reduce mh_init_scale...'])
                    disp(sprintf('MH: Parameter mh_init_scale is equal to %f.',options_.mh_init_scale))
                    options_.mh_init_scale = input('MH: Enter a new value...  ');
                    trial = trial+1;
                end
            end
            if trial > 10 & ~validate
                disp(['MH: I''m unable to find a starting value for block ' int2str(j)])
                return
            end
        end
        fprintf(fidlog,' \n');
        disp('MH: Initial values found!')
        disp(' ')
    else% Case 2: one chain (we start from the posterior mode)
        fprintf(fidlog,['  Initial values of the parameters:\n']);
        candidate = transpose(xparam1);
        if all(candidate' > mh_bounds(:,1)) & all(candidate' < mh_bounds(:,2)) 
            ix2 = candidate;
            ilogpo2 = - feval(TargetFun,ix2',varargin{:});
            disp('MH: Initialization at the posterior mode.')
            disp(' ')
            fprintf(fidlog,['    Blck ' int2str(1) 'params:\n']);
            for i=1:length(ix2(1,:))
                fprintf(fidlog,['      ' int2str(i)  ':' num2str(ix2(1,i)) '\n']);
            end
            fprintf(fidlog,['    Blck ' int2str(1) 'logpo2:' num2str(ilogpo2) '\n']);
        else
            disp('MH: Initialization failed...')
            disp('MH: The posterior mode lies outside the prior bounds.')
            return
        end
        fprintf(fidlog,' \n');
    end
    fprintf(fidlog,' \n');
    fblck = 1;
    fline = ones(nblck,1);
    NewFile = ones(nblck,1);
    %%
    %% Creation of the mh-history file:
    %%
    file = dir([MhDirectoryName '/'  ModelName '_mh_history.mat']);
    if length(files)
        delete([ MhDirectoryName '/' ModelName '_mh_history.mat']);
        disp('MH: Old mh_history file successfully erased!')
    end
    AnticipatedNumberOfFiles = ceil(nruns(1)/MAX_nruns);
    AnticipatedNumberOfLinesInTheLastFile = nruns(1) - (AnticipatedNumberOfFiles-1)*MAX_nruns;
    record.Nblck = nblck;
    record.MhDraws = zeros(1,3);
    record.MhDraws(1,1) = nruns(1);
    record.MhDraws(1,2) = AnticipatedNumberOfFiles;
    record.MhDraws(1,3) = AnticipatedNumberOfLinesInTheLastFile;
    record.AcceptationRates = zeros(1,nblck);
    record.Seeds.Normal = randn('state');
    record.Seeds.Unifor = rand('state');
    record.InitialParameters = ix2;
    record.InitialLogLiK = ilogpo2;
    record.LastParameters = zeros(nblck,npar);
    record.LastLogLiK = zeros(nblck,1);
    record.LastFileNumber = AnticipatedNumberOfFiles ;
    record.LastLineNumber = AnticipatedNumberOfLinesInTheLastFile;
    save([MhDirectoryName '/' ModelName '_mh_history.mat'],'record');  
    fprintf(fidlog,['  CREATION OF THE MH HISTORY FILE!\n\n']);
    fprintf(fidlog,['    Expected number of files per block.......: ' int2str(AnticipatedNumberOfFiles) '.\n']);
    fprintf(fidlog,['    Expected number of lines in the last file: ' ...
                    int2str(AnticipatedNumberOfLinesInTheLastFile) '.\n']);
    fprintf(fidlog,['\n']);
    fprintf(fidlog,['    Initial seed (randn):\n']);
    for i=1:length(record.Seeds.Normal)
        fprintf(fidlog,['      ' num2str(record.Seeds.Normal(i)') '\n']);
    end
    fprintf(fidlog,['    Initial seed (rand).:\n']);
    for i=1:length(record.Seeds.Unifor)
        fprintf(fidlog,['      ' num2str(record.Seeds.Unifor(i)') '\n']);
    end
    fprintf(fidlog,' \n');
    fclose(fidlog);
elseif options_.load_mh_file & ~options_.mh_recover
    %% Here we consider previous mh files (previous mh did not crash).
    disp('MH: I''m loading past metropolis-hastings simulations...')
    file = dir([ MhDirectoryName '/'  ModelName '_mh_history.mat' ]);
    files = dir([ MhDirectoryName '/' ModelName '_mh*.mat']);
    if ~length(files)
        disp('MH:: FAILURE! there is no MH file to load here!')
        return
    end
    if ~length(file)
        disp('MH:: FAILURE! there is no MH-history file!')
        return
    else
        load([ MhDirectoryName '/'  ModelName '_mh_history.mat'])
    end
    fidlog = fopen([MhDirectoryName '/metropolis.log'],'a');
    fprintf(fidlog,'\n');
    fprintf(fidlog,['%% Session ' int2str(length(record.MhDraws(:,1))+1) '.\n']);
    fprintf(fidlog,' \n');
    fprintf(fidlog,['  Number of blocks...............: ' int2str(nblck) '\n']);
    fprintf(fidlog,['  Number of simulations per block: ' int2str(nruns(1)) '\n']);
    fprintf(fidlog,' \n');
    past_number_of_blocks = record.Nblck;
    if past_number_of_blocks ~= nblck
        disp('MH:: The specified number of blocks doesn''t match with the previous number of blocks!')
        disp(['MH:: You declared ' int2str(nblck) ' blocks, but the previous number of blocks was ' ...
              int2str(past_number_of_blocks) '.'])
        disp(['MH:: I will run the Metropolis-Hastings with ' int2str(past_number_of_blocks) ' blocks.' ])
        nblck = past_number_of_blocks;
        options_.mh_nblck = nblck;
    end
    % I read the last line of the last mh-file for initialization 
    % of the new metropolis-hastings simulations:
    LastFileNumber = record.LastFileNumber;
    LastLineNumber = record.LastLineNumber;
    if LastLineNumber < MAX_nruns
        NewFile = ones(nblck,1)*LastFileNumber;
    else
        NewFile = ones(nblck,1)*(LastFileNumber+1);
    end
    ilogpo2 = record.LastLogLiK;
    ix2 = record.LastParameters;
    fblck = 1;
    fline = ones(nblck,1)*(LastLineNumber+1);
    NumberOfPreviousSimulations = sum(record.MhDraws(:,1),1);
    record.MhDraws = [record.MhDraws;zeros(1,3)];
    NumberOfDrawsWrittenInThePastLastFile = MAX_nruns - LastLineNumber;
    NumberOfDrawsToBeSaved = nruns(1) - NumberOfDrawsWrittenInThePastLastFile;
    AnticipatedNumberOfFiles = ceil(NumberOfDrawsToBeSaved/MAX_nruns);
    AnticipatedNumberOfLinesInTheLastFile = NumberOfDrawsToBeSaved - (AnticipatedNumberOfFiles-1)*MAX_nruns;  
    record.LastFileNumber = LastFileNumber + AnticipatedNumberOfFiles;
    record.LastLineNumber = AnticipatedNumberOfLinesInTheLastFile;
    record.MhDraws(end,1) = nruns(1);
    record.MhDraws(end,2) = AnticipatedNumberOfFiles;
    record.MhDraws(end,3) = AnticipatedNumberOfLinesInTheLastFile;
    randn('state',record.Seeds.Normal);
    rand('state',record.Seeds.Unifor);
    save([MhDirectoryName '/' ModelName '_mh_history.mat'],'record');
    disp(['MH: ... It''s done. I''ve loaded ' int2str(NumberOfPreviousSimulations) ' simulations.'])
    disp(' ')
    fclose(fidlog);
elseif options_.mh_recover
    %% The previous metropolis-hastings crashed before the end! I try to
    %% recover the saved draws...
    disp('MH: Recover mode!')
    disp(' ')
    file = dir([MhDirectoryName '/'  ModelName '_mh_history.mat']);
    if ~length(file)
        disp('MH:: FAILURE! there is no MH-history file!')
        return
    else
        load([ MhDirectoryName '/'  ModelName '_mh_history.mat'])
    end
    nblck = record.Nblck;
    options_.mh_nblck = nblck;
    if size(record.MhDraws,1) == 1
        OldMh = 0;% The crashed metropolis was the first session.
    else
        OldMh = 1;% The crashed metropolis wasn't the first session.
    end
    %% Default initialization:
    if OldMh
        ilogpo2 = record.LastLogLiK;
        ix2 = record.LastParameters;
    else
        ilogpo2 = record.InitialLogLiK;
        ix2 = record.InitialParameters;
    end
    %% Set "NewFile":
    if OldMh
        LastLineNumberInThePreviousMh = record.MhDraws(end-1,3);
        LastFileNumberInThePreviousMh = sum(record.MhDraws(1:end-1,2),1);
        if LastLineNumberInThePreviousMh < MAX_nruns
            NewFile = ones(nblck,1)*LastFileNumberInThePreviousMh;
        else
            NewFile = ones(nblck,1)*(LastFileNumberInThePreviousMh+1);
        end
    else
        NewFile = ones(nblck,1);
    end
    %% Set fline (First line):
    if OldMh
        fline = ones(nblck,1)*(LastLineNumberInThePreviousMh+1);
    else
        fline = ones(nblck,1);
    end
    %% Set fblck (First block):
    fblck = 1;
    %% How many mh files should we have ?
    ExpectedNumberOfMhFilesPerBlock = sum(record.MhDraws(:,2),1);
    ExpectedNumberOfMhFiles = ExpectedNumberOfMhFilesPerBlock*nblck;
    %% I count the total number of saved mh files...
    AllMhFiles = dir([MhDirectoryName '/' ModelName '_mh*_blck*.mat']);
    TotalNumberOfMhFiles = length(AllMhFiles);
    %% I count the number of saved mh files per block
    NumberOfMhFilesPerBlock = zeros(nblck,1);
    for i = 1:nblck
        BlckMhFiles = dir([ MhDirectoryName '/' ModelName '_mh*_blck' int2str(i) '.mat']);
        NumberOfMhFilesPerBlock(i) = length(BlckMhFiles);
    end
    tmp = NumberOfMhFilesPerBlock(1);
    %% Is there a chain with less mh files than expected ? 
    CrashedBlck = 1; b = 1;
    while b <= nblck
        if  NumberOfMhFilesPerBlock(b) < ExpectedNumberOfMhFilesPerBlock
            CrashedBlck = b;% YES, chain b!
            disp(['MH: Chain ' int2str(b) ' is uncomplete!'])
            break
        else
            disp(['MH: Chain ' int2str(b) ' is complete!'])
        end
        b = b+1;
    end
    if b>nblck
        disp('MH: You probably don''t need to recover a previous crashed metropolis...')
        disp('    or Dynare is unable to recover it.')
        error('I stop. You should modify your mod file...')
    end
    %% The new metropolis-hastings should start from chain... (fblck=CrashedBlck)
    fblck = CrashedBlck;
    %% How many mh-files are saved in this block ?
    NumberOfSavedMhFilesInTheCrashedBlck = NumberOfMhFilesPerBlock(CrashedBlck);
    %% How many mh-files were saved in this block during the last session
    %% (if there was a complete session before the crash)
    if OldMh
        ante = sum(record.MhDraws(1:end-1,2),1);
        NumberOfSavedMhFilesInTheCrashedBlck = NumberOfSavedMhFilesInTheCrashedBlck - ante;
    end
    %% Is the last mh-file of the previous session full ?
    %% (if there was a complete session before the crash)
    if OldMh && ~NumberOfSavedMhFilesInTheCrashedBlck
        load([MhDirectoryName '/' ModelName '_mh' int2str(ante) '_blck' int2str(CrashedBlck) '.mat'],'logpo2');
        if length(logpo2) == MAX_nruns
            IsTheLastFileOfThePreviousMhFull = 1;
            NumberOfCompletedMhFiles = NumberOfMhFilesPerBlock(CrashedBlck);
            reste = 0;
        else
            IsTheLastFileOfThePreviousMhFull = 0;
            NumberOfCompletedMhFiles = ante-1;
            reste = MAX_nruns-LastLineNumberInThePreviousMh; 
        end
    elseif OldMh && NumberOfSavedMhFilesInTheCrashedBlck
        IsTheLastFileOfThePreviousMhFull = 1;
        NumberOfCompletedMhFiles = NumberOfMhFilesPerBlock(CrashedBlck);
        reste = 0;
    elseif ~OldMh && NumberOfSavedMhFilesInTheCrashedBlck
        IsTheLastFileOfThePreviousMhFull = 0;
        NumberOfCompletedMhFiles = NumberOfMhFilesPerBlock(CrashedBlck);
        reste = 0;
    elseif ~OldMh && NumberOfSavedMhFilesInTheCrashedBlck    
        IsTheLastFileOfThePreviousMhFull = 0;
        NumberOfCompletedMhFiles = 0;
        reste = 0;
    end
    %% How many runs were saved ?
    NumberOfSavedDraws = MAX_nruns*NumberOfCompletedMhFiles + reste;
    %% Here is the number of draws we still need to complete the block:
    if OldMh
        nruns(CrashedBlck) = nruns(CrashedBlck)-(NumberOfSavedDraws-sum(record.MhDraws(1:end-1,1)));
    end
    %% I've got all the needed information... I can initialize the MH:
    if OldMh
        if NumberOfSavedMhFilesInTheCrashedBlck
            load([MhDirectoryName '/' ModelName '_mh' ...
                  int2str(NumberOfCompletedMhFiles) '_blck' int2str(CrashedBlck) '.mat']);
            fline(CrashedBlck,1) = 1;
            NewFile(CrashedBlck) = NumberOfCompletedMhFiles+1;% NumberOfSavedMhFilesInTheCrashedBlck+1;
        else
            load([MhDirectoryName '/' ModelName '_mh' ...
                  int2str(ante) '_blck' int2str(CrashedBlck) '.mat']);
            if reste
                fline(CrashedBlck,1) = length(logpo2)+1;
                NewFile(CrashedBlck) = LastFileNumberInThePreviousMh;
            else
                fline(CrashedBlck,1) = 1;
                NewFile(CrashedBlck) = LastFileNumberInThePreviousMh+1;
            end
        end
        ilogpo2(CrashedBlck) = logpo2(end);
        ix2(CrashedBlck,:) = x2(end,:);       
    end
end% of (if options_.load_mh_file == {0,1 or -1})