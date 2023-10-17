# Pipex_tester
Tester for Pipex (project at Ecole 42, implementation of unix pipes)  

# Installation
Get the tester.sh in your pipex repo, beside the Makefile :  
`cd pipex`  
`git clone git@github.com:bastienkody/pipex_tester.git`  
`cp pipex_tester/tester_pipex.sh ./`  

# Usage 
Run mandatory tests : `bash tester_pipex -m`  
Run mandatory + bonus tests : `bash tester_pipex -mb`  
Run all tests (incl. additional tests) : `bash tester_pipex.sh`

# Details - requirement
* works on unix systems (made for ubuntu and mac)
* must be run with **bash**
* default bonuses : exec 'pipex' outputed from rule 'make pipex'
* **bonus** have names? specify in tester_pipex.sh (lines 4-5) :
	* exec example: `pipex_bonus=pipex_bonus`
	* bonus rule example : `rule_bonus=bonus`
* valgrind tests only if linux kernel
* on mac os if timeout command is missing tester will try to install it (coreutils) if you have Homebrew 

# Problems
* if segfault, the script writes on std err and it destoys display.  

# Tests
## Mandatory ##
* **Norminette** on .c and .h files

* **Makefile** : checks **error** (on stderr) + **relinks** on rule "make" and "make bonus" (if exists)

* Checks the exec name : 'pipex'

* **Basics** : 
	* two commands no parameter + with parameters
	* commands with absolute and relative path
	* custom exec ./a.out in current and relative dir
	* unexisting commands + unexisting absolute path commands
	* empty commands (only spaces)
	* commands with no execution right
	* infile with no reading right
	* outfile with no writing right
	* outfile created before any command execution
	* concurrency of commands (vs one after another)
	* empty environnement (env -i) + no PATH (unset PATH)
	* valgrind : leaks + extra opened fd on all process
	* zombie process before pipex returned

![alt text](https://github.com/bastienkody/pipex_tester/blob/main/imgs/mandatory_tests.png)

## Bonus ##
***Warning: by default your bonus exec must be named 'pipex'.***  
* **Multi cmd**  
* **heredoc**  

_Could not find a way to send EOF to heredoc to simulate ctrl+d via a script. Please contact me if you have any suggestion!_

![alt text](https://github.com/bastienkody/pipex_tester/blob/main/imgs/bonus_tests.png)

## Additional tests ##
_These tests are not all required to pass to validate pipex. Altough you should not **segfault**_  
* **Single quotes** parsing : single quotes used in commands arguments  
* **Spaces** parsing : can you manage spaces in arguments (single quotes must be managed)  
* **Backslash** parsing : how backlashes are treated in arguments (single q + spaces must be managed)  
* **Fd limit** : how many pipes are created - do you segfault at or after 1024 fd ?  

![alt text](https://github.com/bastienkody/pipex_tester/blob/main/imgs/additionnal_tests.png)
