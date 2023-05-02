# pipex_tester
Tester for pipex (42 project) - Testeur du projet 42 pipex

# Installation
Git clone the repo into your pipex repo : 
	`git clone git@github.com:bastienkody/pipex_tester.git`

Copy the tester.sh into your main repo (beside Makefile) :
	`cp pipex_tester/tester_pipex.sh ./`

# Usage
Run all tests : `bash tester_pipex.sh`

Run mandatory tests : `bash tester_pipex -m`

Run mandatory + bonus tests : `bash tester_pipex -mb`

# Details - requirement
* the exec must be in the main repo (beside the makefile) and be named 'pipex'

* by default bonus exec is pipex and bonus rule is bonus. you can modifiy it at the beginning of tester_pipex.sh
** `pipex_bonus=pipex`
** `rule_bonus=bonus`

* undefined behaviours if not run with bash 

* works on unix systems (at least mac and debian/ubu)

* valgrind tests only if linux kernel

# Problems
* infinite loop if commands not run silmutaneously : must launch process and set a timeout

* if segfault, the script writes on std err and it destoyes display. should i redirect script std-err? then i cant get the "segfault" error on the appropriate test to ...

# Tests
## Mandatory ##
* Norminette on .c and .h files

* Makefile : checks error + relinks on rule "make" and "make bonus" (if exists)

* Checks the exec name : 'pipex'

* Basics : 
	* two commands no parameter
	* two commands with parameters
	* commands with absolute path
	* unexisting commands
	* unexisting commands with absolute path
	* empty commands (only spaces)
	* infile with no reading right
	* outfile with no writing right
	* outfile created before execution
	* concurrency of commands (vs one after another)
	* custom exec ./a.out in pipex repo
	* empty environnement (env -i)
	* no PATH (unset PATH)
	* leaks on all process
	* extra opened fd on all process

![alt text](https://github.com/bastienkody/pipex_tester/blob/main/imgs/mandatory_tests.png)

## Bonus ##
**Warning: your bonus exec must be named 'pipex'**
* Multi cmd
* heredoc

_Could not find a way to send EOF to the pipex here_doc to simulate ctrl+d (wich is not a signal) via a script. Please make an issue if you can!_

![alt text](https://github.com/bastienkody/pipex_tester/blob/main/imgs/bonus_tests.png)

## Additional tests ##
_These tests are not all required to pass to validate pipex. Altough you should not **segfault**_
* Single quotes parsing
* Spaces parsing
* Backslash parsing
* Fd limit 

![alt text](https://github.com/bastienkody/pipex_tester/blob/main/imgs/additionnal_tests.png)
