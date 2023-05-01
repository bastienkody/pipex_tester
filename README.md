# pipex_tester
42 project 'pipex' tester - testeur du projet 42 'pipex'

# Download
Git clone the project into your pipex repo : `git clone git@github.com:bastienkody/pipex_tester.git`

# Usage
Run all tests : `bash tester_pipex.sh`

Run mandatory tests : `bash tester_pipex -m`

Run mandatory + bonus tests : `bash tester_pipex -mb`

# Details
* undefined behaviours if not run with bash (ko with sh, few err with zsh)

* works on unix systems (at least mac and debian/ubu)

* valgrind tests only if linux kernel

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

_Could not find a way to send EOF to the pipex here_doc to simulate ctrl+d (wich is not a signal). Please make an issue if you can!_

![alt text](https://github.com/bastienkody/pipex_tester/blob/main/imgs/bonus_tests.png)

## Additional tests ##
_These tests are not all required to pass to validate pipex. Altough you should not **segfault**, especially on the last ones_
* Single quotes parsing
* Spaces parsing
* Backslash parsing
* Fd limit 

![alt text](https://github.com/bastienkody/pipex_tester/blob/main/imgs/additionnal_tests.png)
