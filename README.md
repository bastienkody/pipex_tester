# pipex_tester
Tester for pipex (42 project) - Testeur du projet 42 pipex

# Installation
In your pipex repo, git clone the tester repo : 
	`git clone git@github.com:bastienkody/pipex_tester.git`

Copy the tester into your main pipex repo (beside Makefile) :
	`cp pipex_tester/tester_pipex.sh ./`

# Usage
Run all tests : `bash tester_pipex.sh`

Run mandatory tests : `bash tester_pipex -m`

Run mandatory + bonus tests : `bash tester_pipex -mb`

# Details - requirement
* the exec must be in the main repo (beside the makefile) and be named **'pipex'**

* you handle bonus cases but have no bonus rule? The tester will try bonuses with the exec 'pipex' outputed from rule 'make pipex'

* If you have bonus names, you may specify these at the beginning of tester_pipex.sh :
	* exec name default : `pipex_bonus=pipex` (modified example: `pipex_bonus=pipex_bonus`)
	* bonus rule default : `rule_bonus=pipex` (modified example: `rule_bonus=bonus`)

* undefined behaviours if not run with bash

* works on unix systems (at least mac and debian/ubu)

* valgrind tests only if linux kernel

* on mac os, there is no command 'timeout' by default ; the tester will try to install it (coreutils) if you have Homebrew 

# Problems
* if segfault, the script writes on std err and it destoys display. should i redirect script std-err? then i cant get the "segfault" error on the appropriate test to ... 

# Tests
## Mandatory ##
* **Norminette** on .c and .h files

* **Makefile** : checks **error** (on stderr) + **relinks** on rule "make" and "make bonus" (if exists)

* Checks the exec name : 'pipex'

* **Basics** : 
	* two commands no parameter + with parameters
	* commands with absolute path + custom exec a.out
	* unexisting commands + unexisting absolute path commands
	* empty commands (only spaces)
	* commands with no execution right
	* infile with no reading right
	* outfile with no writing right
	* outfile created before any command execution
	* concurrency of commands (vs one after another)
	* empty environnement (env -i) + no PATH (unset PATH)
	* valgrind : leaks + extra opened fd on all process

![alt text](https://github.com/bastienkody/pipex_tester/blob/main/imgs/mandatory_tests.png)

## Bonus ##
**Warning: by default your bonus exec must be named 'pipex'.**
* **Multi cmd**
* **heredoc**

_Could not find a way to send EOF to the pipex here_doc to simulate ctrl+d (wich is not a signal) via a script. Please make an issue if you can!_

![alt text](https://github.com/bastienkody/pipex_tester/blob/main/imgs/bonus_tests.png)

## Additional tests ##
_These tests are not all required to pass to validate pipex. Altough you should not **segfault**_
* **Single quotes** parsing : single quotes used in commands arguments
* **Spaces** parsing : can you manage spaces in arguments (single quotes must be managed)
* **Backslash** parsing : how backlashes are treated in arguments (single q + spaces must be managed)
* **Fd limit** : how many pipes are created - do you segfault at or after 1024 fd ?

![alt text](https://github.com/bastienkody/pipex_tester/blob/main/imgs/additionnal_tests.png)
