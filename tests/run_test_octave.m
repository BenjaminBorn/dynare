## Copyright (C) 2009-2011 Dynare Team
##
## This file is part of Dynare.
##
## Dynare is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## Dynare is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

## Implementation notes:
##
## Before every call to Dynare, the contents of the workspace is saved in
## 'wsOct', and reloaded after Dynare has finished (this is necessary since
## Dynare does a 'clear -all').

top_test_dir = pwd;
addpath(top_test_dir);
addpath([top_test_dir '/../matlab']);

## Test Dynare Version
if !strcmp(dynare_version(), getenv("DYNARE_VERSION"))
  error("Incorrect version of Dynare is being tested")
endif

## Ask gnuplot to create graphics in text mode
## Note that setenv() was introduced in Octave 3.0.2, for compatibility
## with MATLAB
putenv("GNUTERM", "dumb")

## Test MOD files listed in Makefile.am
name = strsplit(getenv("MODFILES"), " ");

failedBase = {};

for i=1:size(name,2)
  [directory, testfile, ext] = fileparts([top_test_dir '/' name{i}]);
  cd(directory);
  printf("\n***  TESTING: %s ***\n", name{i});
  try
    save wsOct
    dynare([testfile ext])
    load wsOct
  catch
    load wsOct
    failedBase{size(failedBase,2)+1} = name{i};
    printMakeCheckOctaveErrMsg(name{i}, lasterror);
  end_try_catch
  delete('wsOct');
  cd(top_test_dir);
end

## Test block_bytecode/ls2003.mod with various combinations of
## block/bytecode/solve_algo/stack_solve_algo
failedBlock = {};
num_block_tests = 0;
cd([top_test_dir '/block_bytecode']);
for blockFlag = 0:1
  for bytecodeFlag = 0:1
    ## Recall that solve_algo=7 and stack_solve_algo=2 are not supported
    ## under Octave
    default_solve_algo = 2;
    default_stack_solve_algo = 0;
    if !blockFlag && !bytecodeFlag
      solve_algos = 0:4;
      stack_solve_algos = 0;
    elseif blockFlag && !bytecodeFlag
      solve_algos = [0:4 6 8];
      stack_solve_algos = [0 1 3 4];
    else
      solve_algos = [0:6 8];
      stack_solve_algos = [0 1 3:5];
    endif

    for i = 1:length(solve_algos)
      num_block_tests = num_block_tests + 1;
      if !blockFlag && !bytecodeFlag && (i == 1)
        ## This is the reference simulation path against which all
        ## other simulations will be tested
        try
          save wsOct
          run_ls2003(blockFlag, bytecodeFlag, solve_algos(i), default_stack_solve_algo)
          load wsOct
          y_ref = oo_.endo_simul;
          save('test.mat','y_ref');
        catch
          load wsOct
          failedBlock{size(failedBlock,2)+1} = ['block_bytecode/run_ls2003.m(' num2str(blockFlag) ', ' num2str(bytecodeFlag) ', ' num2str(solve_algos(i)) ', ' num2str(default_stack_solve_algo) ')'];
          printMakeCheckOctaveErrMsg(['block_bytecode/run_ls2003.m(' num2str(blockFlag) ', ' num2str(bytecodeFlag) ', ' num2str(solve_algos(i)) ', ' num2str(default_stack_solve_algo) ')'], lasterror);
        end_try_catch
      else
        try
          save wsOct
          run_ls2003(blockFlag, bytecodeFlag, solve_algos(i), default_stack_solve_algo)
          load wsOct
          ## Test against the reference simulation path
          load('test.mat','y_ref');
          diff = oo_.endo_simul - y_ref;
          if(abs(diff) > options_.dynatol)
            failedBlock{size(failedBlock,2)+1} = ['block_bytecode/run_ls2003.m(' num2str(blockFlag) ', ' num2str(bytecodeFlag) ', ' num2str(solve_algos(i)) ', ' num2str(default_stack_solve_algo) ')'];
            differr.message = ["ERROR: simulation path differs from the reference path" ];
            printMakeCheckOctaveErrMsg(['block_bytecode/run_ls2003.m(' num2str(blockFlag) ', ' num2str(bytecodeFlag) ', ' num2str(solve_algos(i)) ', ' num2str(default_stack_solve_algo) ')'], differr);
          endif
        catch
          load wsOct
          failedBlock{size(failedBlock,2)+1} = ['block_bytecode/run_ls2003.m(' num2str(blockFlag) ', ' num2str(bytecodeFlag) ', ' num2str(solve_algos(i)) ', ' num2str(default_stack_solve_algo) ')'];
          printMakeCheckOctaveErrMsg(['block_bytecode/run_ls2003.m(' num2str(blockFlag) ', ' num2str(bytecodeFlag) ', ' num2str(solve_algos(i)) ', ' num2str(default_stack_solve_algo) ')'], lasterror);
        end_try_catch
      endif
    endfor
    for i = 1:length(stack_solve_algos)
      num_block_tests = num_block_tests + 1;
      try
        save wsOct
        run_ls2003(blockFlag, bytecodeFlag, default_solve_algo, stack_solve_algos(i))
        load wsOct
        ## Test against the reference simulation path
        load('test.mat','y_ref');
        diff = oo_.endo_simul - y_ref;
        if(abs(diff) > options_.dynatol)
          failedBlock{size(failedBlock,2)+1} = ['block_bytecode/run_ls2003.m(' num2str(blockFlag) ', ' num2str(bytecodeFlag) ', ' num2str(default_solve_algo) ', ' num2str(stack_solve_algos(i)) ')'];
          differr.message = ["ERROR: simulation path differs from the reference path" ];
          printMakeCheckOctaveErrMsg(['block_bytecode/run_ls2003.m(' num2str(blockFlag) ', ' num2str(bytecodeFlag) ', ' num2str(default_solve_algo) ', ' num2str(stack_solve_algos(i)) ')'], differr);
        endif
      catch
        load wsOct
        failedBlock{size(failedBlock,2)+1} = ['block_bytecode/run_ls2003.m(' num2str(blockFlag) ', ' num2str(bytecodeFlag) ', ' num2str(solve_algos(i)) ', ' num2str(default_stack_solve_algo) ')'];
        printMakeCheckOctaveErrMsg(['block_bytecode/run_ls2003.m(' num2str(blockFlag) ', ' num2str(bytecodeFlag) ', ' num2str(solve_algos(i)) ', ' num2str(default_stack_solve_algo) ')'], lasterror);
      end_try_catch
    endfor
  endfor
endfor

delete('wsOct');

cd(top_test_dir);

total_tests = size(name,2)+num_block_tests;

% print output to screen and to file
fid = fopen("run_test_octave_output.txt", "w");

printf("\n\n\n");
fprintf(fid,'\n\n\n');
printf("***************************************\n");
fprintf(fid,"***************************************\n");
printf("*         DYNARE TEST RESULTS         *\n");
fprintf(fid,"*         DYNARE TEST RESULTS         *\n");
printf("*        for make check-octave        *\n");
fprintf(fid,"*        for make check-octave        *\n");
printf("***************************************\n");
fprintf(fid,"***************************************\n");
printf("  %d tests PASSED out of %d tests run\n", total_tests-size(failedBase,2)-size(failedBlock,2), total_tests);
fprintf(fid," %d tests PASSED out of %d tests run\n", total_tests-size(failedBase,2)-size(failedBlock,2), total_tests);
printf("***************************************\n");
fprintf(fid,"***************************************\n");
if size(failedBase,2) > 0 || size(failedBlock,2) > 0
  printf("List of %d tests FAILED:\n", size(failedBase,2)+size(failedBlock,2));
  fprintf(fid,"List of %d tests FAILED:\n", size(failedBase,2)+size(failedBlock,2));
  for i=1:size(failedBase,2)
    printf("   * %s\n",failedBase{i});
    fprintf(fid,"   * %s\n", failedBase{i});
  end
  for i=1:size(failedBlock,2)
    printf("   * %s\n",failedBlock{i});
    fprintf(fid,"   * %s\n", failedBlock{i});
  end
  printf("***************************************\n\n");
  fprintf(fid,"***************************************\n\n");
  clear -all
  error("make check-octave FAILED");
end
fclose(fid);

## Local variables:
## mode: Octave
## End:
