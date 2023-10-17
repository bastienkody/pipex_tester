#! /bin/bash

# bonus info config (CHANGE HERE if your bonus exec/rule is not 'pipex')
pipex_bonus=pipex
rule_bonus=pipex

# const
vlgppx='/usr/bin/valgrind --trace-children=yes --leak-check=full --track-fds=yes'
ITA="\033[3m"
UNDERL="\033[4m"
GREEN="\033[32m"
RED="\033[31m"
YEL="\033[33m"
END="\033[m"
BLU_BG="\033[44m"
YEL_BG="\033[43;1m"
RED_BG="\033[41;1m"

# machine spec
bin_path=/usr/bin
uname -s | grep -qi darwin && os=mac && ls_path=/bin && cat_path=/bin
uname -s | grep -qi linux && os=linux && cat_path=/usr/bin && ls_path=/usr/bin

# mac os : timeout command install via homebrew 
if [[ $os == "mac" && ! $(which timeout) ]] ; then
echo -e "Missing command 'timeout' on mac os. Trying to install via homebrew ..."
[[ ! $(which brew) ]] && echo "Missing homebrew (needed for timeout installation). Please install Homebrew and restarts the tester" && exit 1
echo -e "Homebrew found - starting installation ..."
brew install coreutils
which timeout && echo -e "Timeout is installed. Tester starting ..." || { echo -e "Timeout still not found. Please restarts the sell and try again. If the error persists please install timeout by yourself." ; exit 2 ; }
fi

# bonus rule ?
cat Makefile | grep -q "bonus:" && bonus=1 || bonus=0

# print intro
echo "------------------------------------"
echo "------------------------------------"
echo -e "\tPIPEX TESTER"
echo -e "Started at $(date +%R) - $(date +"%d %B %Y")"
echo -e "by $USER on $os os"
echo -e "made by bguillau (@bastienkody)"
echo "------------------------------------"
echo "------------------------------------"
[[ $os != "linux" ]] && echo -e "${ITA}No valgrind testing (uncompatible os)${END}"

# -----------------------------------------------------------------------------------------------------------------------------------------
# MANDATORY TESTS
# -----------------------------------------------------------------------------------------------------------------------------------------
echo -e "${YEL_BG}Mandatory tests${END}"

#norminette
echo -ne "${BLU_BG}Test norminette:${END} \t\t\t\t\t\t\t-->"
norm=$(find . | egrep ".*(\.c|\.h)$" | norminette)
if [[ $(echo "$norm" | egrep -v "OK\!$") ]] ;
then
	echo -e "${RED} norme errors:${END}"
	echo -e "$norm" | egrep -v "OK\!$"
else
	echo -e "${GREEN} norm ok${END}"
fi

#makefile 
echo -ne "${BLU_BG}Test Makefile:${END} \t\t\t\t\t\t\t\t-->"
make re 1>/dev/null 2> stderrmake.txt
make > stdoutmakebis.txt 2>&1
[[ -s stderrmake.txt ]] && echo -ne "${RED} make wrote on std err${END}" || echo -ne "${GREEN} no make error${END}" 
echo -n " -- "
cat stdoutmakebis.txt | egrep -viq "(nothin|already|date)" && echo -ne "${RED}makefile relink?${END}" || echo -ne "${GREEN}no relink${END}"
echo -n " -- "
[[ -f pipex && -x pipex ]] && echo -e "${GREEN}exec named pipex${END}" || echo -e "${RED}no exec file found named pipex${END}"
rm -rf stderrmake.txt stdoutmakebis.txt

#makefile bonus
if [[ $bonus == 1 ]] ; then
echo -ne "${BLU_BG}Test Makefile bonus:${END} \t\t\t\t\t\t\t-->"
make ${rule_bonus} 1>/dev/null 2> stderrmake.txt
make ${rule_bonus} > stdoutmakebis.txt 2>&1
[[ -s stderrmake.txt ]] && echo -ne "${RED} make ${rule_bonus} wrote on std err${END}" || echo -ne "${GREEN} no make ${rule_bonus} error${END}" 
echo -ne " -- "
cat stdoutmakebis.txt | egrep -viq "(nothin|already|date)" && echo -ne "${RED}makefile relinks on bonus?${END}" || echo -ne "${GREEN}no relink on bonus${END}"
echo -ne " -- "
[[ -f $pipex_bonus && -x $pipex_bonus ]] && echo -e "${GREEN}exec named $pipex_bonus${END}" || echo -e "${RED}no exec file found named $pipex_bonus${END}"
rm -rf stderrmake.txt stdoutmakebis.txt
( make fclean && make ) >/dev/null 2>&1 
fi

[[ ! -f pipex ]] && { echo -e "${RED_BG}No file 'pipex'. Tester exiting.${END}" ; make fclean >/dev/null 2>&1 ; exit ; }
[[ ! -x pipex ]] && { echo -e "${RED_BG}$USER has not execution rights on 'pipex'. Tester exiting.${END}" ; make fclean >/dev/null 2>&1 ; exit ; }

#arg nb problem
echo -ne "${BLU_BG}Test arg nb (<4):${END} \t\t\t\t\t\t\t-->"
echo -e "yo\nyi" > infile
./pipex > no_arg.txt 2> no_arg_err.txt
./pipex infile > one_arg.txt 2> one_arg_err.txt
./pipex infile "echo yo" > two_arg.txt 2> two_arg_err.txt
./pipex infile "echo yo" "echo yi" > three_arg.txt 2> three_arg_err.txt
./pipex infile "echo yo" "echo yi" outfile > four_arg.txt 2> four_arg_err.txt
if [[ -s no_arg.txt && -s one_arg.txt && -s two_arg.txt && -s three_arg.txt ]] ; then
	echo -ne "${YEL} pipex wrote on std out (fd 1)${END} "
fi
if [[ -s no_arg_err.txt || -s one_arg_err.txt || -s two_arg_err.txt || -s three_arg_err.txt ]] ; then
	echo -ne "${GREEN} pipex wrote on std err (fd 2)${END} "
fi
if [[ $(cat no_arg.txt no_arg_err.txt one_arg.txt one_arg_err.txt two_arg.txt two_arg_err.txt three_arg.txt three_arg_err.txt | egrep "(yi|yo)") ]] ; then
	echo -ne "${RED} pipex executes cmds ...${END}"
fi
rm -rf *arg*.txt outfile infile

#basics tests
echo -e "\n${BLU_BG}Basics:${END}"

echo -ne "Test 1 : ./pipex Makefile ls ls t1_output \t\t\t\t--> "
touch t1_output t1_expected #both created here bc of ls cmd
./pipex "Makefile" "ls" "ls" "t1_output" >/dev/null 2>&1 
code=$(echo $?)
ls > t1_expected
diff t1_expected t1_output >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED} KO${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f t1_*

echo -ne "Test 2 : ./pipex Makefile cat cat t2_output \t\t\t\t--> "
touch t2_output
./pipex "Makefile" "cat" "cat" "t2_output" >/dev/null 2>&1 
code=$(echo $?)
diff Makefile t2_output >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f t2_*

echo -ne "Test 3 : ./pipex Makefile \"cat -e\" \"head -n3\" t3_output\t\t\t--> "
touch t3_output t3_expected
./pipex "Makefile" "cat -e" "head -n3" "t3_output" >/dev/null 2>&1 
code=$(echo $?)
cat -e Makefile | head -n3 > t3_expected
diff t3_expected t3_output >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO (cmd one after another instead of parallel) ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f t3_* 

#cmd with absolute path
echo -e "${BLU_BG}Absolut path cmd:${END}"

echo -ne "Test 1 : ./pipex Makefile ${ls_path}/ls ${bin_path}/cat t1_output \t\t\t--> "
touch t1_output t1_expected
./pipex "Makefile" "${ls_path}/ls" "${cat_path}/cat" "t1_output" >/dev/null 2>&1 
code=$(echo $?)
${ls_path}/ls < Makefile | ${cat_path}/cat > t1_expected 2>/dev/null
diff t1_expected t1_output >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f t1_*

echo -ne "Test 2 : ./pipex Makefile \"${bin_path}/tail -n15\" \"${bin_path}/head -n6\" t1_output\t--> "
touch t1_output t1_expected
./pipex "Makefile" "${bin_path}/tail -n15" "${bin_path}/head -n6" "t1_output" >/dev/null 2>&1 
code=$(echo $?)
${bin_path}/tail -n15 < Makefile | ${bin_path}/head -n6 > t1_expected 2>/dev/null
diff t1_expected t1_output >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f t1_*

#non existing cmd w/ abs. path
echo -e "${BLU_BG}Absolut path cmd not found:${END}"

echo -ne "Test 1 : ./pipex Makefile ${bin_path}/lsoip ${bin_path}/cati outf \t\t--> "
${bin_path}/lsoip < Makefile 2>/dev/null | ${bin_path}/cati > outf 2>/dev/null
./pipex "Makefile" "${bin_path}/lsoip" "${bin_path}/cati" "outf" > stdout.txt 2> stderr.txt
code=$(echo $?)
[[ -s stderr.txt ]] && echo -ne "${GREEN}OK Stderr: output. ${END}" || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}" || echo -ne "${GREEN}Stdout: no output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | egrep -i "(file|directory)") ]] && echo -ne "${GREEN}(err msg) ${END}" || echo -ne "${YEL}(err msg without \"No such file or directory\") ${END}"
[[ $code -eq 127 ]] && echo -e "${GREEN}(return status == 127)${END}" || echo -e "${YEL}(return status != 127)${END}"
rm -f stderr.txt stdout.txt outf

echo -ne "Test 2 : ./pipex Makefile \"touch OUI\" ${bin_path}/cati outf \t\t--> "
./pipex "Makefile" "touch OUI" "${bin_path}/cati" "outf" > stdout.txt 2> stderr.txt
code=$(echo $?)
ls -l | grep -q OUI && echo -ne "${GREEN}OK. ${END}" || echo -ne "${RED}KO. ${END}"
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | egrep -i "(file|directory)") ]] && echo -ne "${GREEN}(err msg ok) ${END}" || echo -ne "${YEL}(err msg without \"No such file or directory\") ${END}"
[[ $code -eq 127 ]] && echo -e "${GREEN}(return status == 127)${END}" || echo -e "${YEL}(return status != 127)${END}"
rm -f stderr.txt stdout.txt outf OUI

echo -ne "Test 3 : ./pipex Makefile ${bin_path}/cati \"touch OUI\" outf \t\t--> "
./pipex "Makefile" "${bin_path}/cati" "touch OUI" "outf" > stdout.txt 2> stderr.txt
code=$(echo $?)
ls -l | grep -q OUI && echo -ne "${GREEN}OK. ${END}" || echo -ne "${RED}KO. ${END}"
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | egrep -i "(file|directory)") ]] && echo -ne "${GREEN}(err msg ok) ${END}" || echo -ne "${YEL}(err msg without \"No such file or directory\") ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(- return status != 0)${END}"
rm -f stderr.txt stdout.txt outf OUI

#non existing cmd w/ rel. path
echo -e "${BLU_BG}Cmd not found:${END}"

echo -ne "Test 1 : ./pipex Makefile lsoip cati outf \t\t\t\t--> "
lsoip < Makefile 2>/dev/null | cati > t1_expected 2>/dev/null
./pipex "Makefile" "lsoip" "cati" "outf" >stdout.txt 2> stderr.txt
code=$(echo $?)
[[ -s stderr.txt ]] && echo -ne "${GREEN}OK Stderr: output. ${END}" || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}" || echo -ne "${GREEN}Stdout: no output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | egrep -i "(command|found)") ]] && echo -ne "${GREEN}(err msg) ${END}" || echo -ne "${YEL}(err msg without \"Command not found\") ${END}"
[[ $code -eq 127 ]] && echo -e "${GREEN}(return status == 127)${END}" || echo -e "${YEL}(return status != 127)${END}"
rm stderr.txt stdout.txt t1_expected outf

echo -ne "Test 2 : ./pipex Makefile \"touch OUI\" cati outf \t\t\t--> "
./pipex "Makefile" "touch OUI" "cati" "outf" >stdout.txt 2> stderr.txt
code=$(echo $?)
ls -l | grep -q OUI && echo -ne "${GREEN}OK. ${END}"  || echo -ne "${RED}KO. ${END}"
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | egrep -i "(command|found)") ]] && echo -ne "${GREEN}(err msg) ${END}" || echo -ne "${YEL}(err msg without \"Command not found\") ${END}"
[[ $code -eq 127 ]] && echo -e "${GREEN}(return status == 127)${END}" || echo -e "${YEL}(return status != 127)${END}"
rm -f stderr.txt stdout.txt outf OUI

echo -ne "Test 3 : ./pipex Makefile cati \"touch OUI\" outf \t\t\t--> "
./pipex "Makefile" "cati" "touch OUI" "outf" >stdout.txt 2> stderr.txt
code=$(echo $?)
ls -l | grep -q OUI && echo -ne "${GREEN}OK. ${END}" || echo -ne "${RED}KO. ${END}"
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | egrep -i "(command|found)") ]] && echo -ne "${GREEN}(err msg) ${END}" || echo -ne "${YEL}(err msg without \"Command not found\") ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0) ${END}"
rm -f stderr.txt stdout.txt outf OUI

#empty commands
echo -e "${BLU_BG}Empty cmd:${END}"

echo -ne "Test 1 : ./pipex Makefile \" \" \" \" outf \t\t\t\t\t--> "
./pipex Makefile " " " " outf >stdout.txt 2> stderr.txt
code=$(echo $?)
[[ -s stderr.txt ]] && echo -ne "${GREEN}OK Stderr: output. ${END}" || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}" || echo -ne "${GREEN}Stdout: no output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | egrep -ic "command not found") -eq 2 ]] && echo -ne "${GREEN}(err msg) ${END}" || echo -ne "${YEL}(not 2 err msg with \"Command not found\") ${END}"
[[ $code -eq 127 ]] && echo -e "${GREEN}(return status == 127)${END}" || echo -e "${YEL}(return status != 127)${END}"
rm -f outf stderr.txt stdout.txt

echo -ne "Test 2 : ./pipex Makefile \"touch OUI\" \" \" outf \t\t\t\t--> "
./pipex Makefile "touch OUI" " " outf >stdout.txt 2> stderr.txt
code=$(echo $?)
ls -l | grep -q OUI && echo -ne "${GREEN}OK. ${END}" || echo -ne "${RED}KO. ${END}"
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
cat stderr.txt stdout.txt 2>/dev/null | egrep -qi "command not found" && echo -ne "${GREEN}(err msg) ${END}" || echo -ne "${YEL}(err msg without \"Command not found\") ${END}"
[[ $code -eq 127 ]] && echo -e "${GREEN}(return status == 127)${END}" || echo -e "${YEL}(return status != 127)${END}"
rm -f outf stderr.txt stdout.txt outf OUI

echo -ne "Test 3 : ./pipex Makefile \" \" \"touch OUI\" outf \t\t\t\t--> "
./pipex Makefile " " "touch OUI" outf >stdout.txt 2> stderr.txt
code=$(echo $?)
ls -l | grep -q OUI && echo -ne "${GREEN}OK. ${END}" || echo -ne "${RED}KO. ${END}"
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
cat stderr.txt stdout.txt 2>/dev/null | egrep -qi "command not found" && echo -ne "${GREEN}(err msg) ${END}" || echo -ne "${YEL}(err msg without \"Command not found\") ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf stderr.txt stdout.txt outf OUI

#infile pb tests
echo -e "${BLU_BG}Infile no readable:${END}"
touch infile_r infile_no_r && chmod u-r infile_no_r

echo -ne "Test 1 : ./pipex infile_r \"touch truc\" \"touch truc2\" t1_output\t\t--> "
./pipex infile_r "touch truc" "touch truc2" t1_output >/dev/null 2>&1 
code=$(echo $?)
[[ $(ls -l | egrep -c "truc2?") -eq 2 ]] && echo -ne "${GREEN}OK. ${END}" || echo -ne "${RED}KO. ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f t1_* truc*

echo -ne "Test 2 : ./pipex infile_no_r \"touch NON\" \"touch OUI\" t2_output\t\t--> "
./pipex infile_no_r "touch NOT" "touch OUI" t2_output >stdout.txt 2> stderr.txt
code=$(echo $?)
[[ !$(ls -l | grep "NOT") && $(ls -l | grep "OUI") ]] && echo -ne "${GREEN}OK. ${END}" || echo -ne "${RED}KO. ${END}"
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | grep -i "permission denied") ]] && echo -ne "${GREEN}(err msg) ${END}" || echo -ne "${YEL}(err msg without \"Permission denied\") ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f stderr.txt t2_* OUI

echo -ne "Test 3 : ./pipex infile_no_r lsop \"echo yo\" t2_output\t\t\t--> "
./pipex infile_no_r "lsop" "echo yo" t2_output >stdout.txt 2> stderr.txt
code=$(echo $?)
[[ -f t2_output && $(cat t2_output) == "yo" ]] && echo -ne "${GREEN}OK. ${END}" || echo -ne "${RED}KO. ${END}"
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | grep -i "permission denied") ]] && echo -ne "${GREEN}(err msg) ${END}" || echo -ne "${YEL}(err msg without \"Permission denied\") ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f stderr.txt infile*  t2_*

#outfile pb tests
echo -e "${BLU_BG}Outfile no writable:${END}"
touch outfile_w outfile_no_w && chmod u-w outfile_no_w

echo -ne "Test 1 : ./pipex Makefile \"touch truc\" \"touch truc2\" outfile_w \t\t--> "
./pipex Makefile "touch truc" "touch truc2" outfile_w >/dev/null 2>&1 
code=$(echo $?)
[[ $(ls -l | egrep "truc2?" | wc -l) -eq 2 ]] && echo -ne "${GREEN}OK. ${END}" || echo -ne "${RED}KO. ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f truc*

echo -ne "Test 2 : ./pipex Makefile \"touch OUI\" \"touch NON\" outfile_no_w \t\t--> "
./pipex Makefile "touch OUI" "touch NON" outfile_no_w >stdout.txt 2> stderr.txt
code=$(echo $?)
[[ !$(ls -l | grep "NOT") && $(ls -l | grep "OUI") ]] && echo -ne "${GREEN}OK. ${END}" || echo -ne "${RED}KO. ${END}"
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | grep -i "permission denied") ]] && echo -ne "${GREEN}(err msg) ${END}" || echo -ne "${YEL}(err msg without \"Permission denied\") ${END}"
[[ $code -eq 1 ]] && echo -e "${GREEN}(return status == 1)${END}" || echo -e "${YEL}(return status != 1)${END}"
rm -f stderr.txt stdout.txt OUI

echo -ne "Test 3 : ./pipex Makefile \"touch OUI\" lsop outfile_no_w \t\t--> "
./pipex Makefile "touch OUI" "lsop" outfile_no_w >stdout.txt 2> stderr.txt
code=$(echo $?)
[[ $(ls -l | grep "OUI") ]] && echo -ne "${GREEN}OK. ${END}"  || echo -ne "${RED}KO. ${END}"
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | grep -i "permission denied") ]] && echo -ne "${GREEN}(err msg) ${END}" || echo -ne "${YEL}(err msg without \"Permission denied\") ${END}"
[[ $code -eq 1 ]] && echo -e "${GREEN}(return status == 1)${END}" || echo -e "${YEL}(return status != 1)${END}"
rm -f stderr.txt stdout.txt outfile* OUI 

# outfile created before executing ls
echo -e "${BLU_BG}Outfile created before exec:${END}"

echo -ne "Test 1 : ./pipex Makefile cat ls outf \t\t\t\t\t--> "
rm -f outf
./pipex Makefile "cat" "ls" outf 2>/dev/null
[[ -f outf ]] && cat outf | grep -q "outf" && echo -e "${GREEN}OK${END}" || echo -e "${RED}KO (missing "outf" in ls result)${END}"
rm -f outf

echo -ne "Test 2 : ./pipex Makefile ls cat outf \t\t\t\t\t--> "
rm -f outf
./pipex Makefile "ls" "cat" outf 2>/dev/null
[[ -f outf ]] && cat outf | grep -q "outf" && echo -e "${GREEN}OK${END}" || echo -e "${RED}KO (missing "outf" in ls result)${END}"
rm -f outf

#silmultaneous cmd test
echo -e "${BLU_BG}Concurrency of cmds:${END}"

echo -ne "Test 1 : ./pipex Makefile yes \"echo yo\" outf \t\t\t\t--> "
timeout --preserve-status 2 ./pipex Makefile "yes" "echo yo" outf >/dev/null 2>&1 
code=$(echo $?)
[[ -f outf && $(cat outf) -eq "yo" ]] && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf

echo -ne "Test 2 : ./pipex Makefile \"sleep 2\" \"sleep 1\" outf \t\t\t--> "
t1=$(date +%s)
./pipex Makefile "sleep 2" "sleep 1" outf 2>/dev/null
code=$(echo $?)
t2=$(date +%s)
[[ $((t2 - t1)) -eq 2 ]] && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf

echo -ne "Test 3 : ./pipex Makefile yes cati outf \t\t\t\t--> "
timeout --preserve-status 2 ./pipex Makefile "yes" "cati" outf >stdout.txt 2> stderr.txt
code=$(echo $?)
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | grep -i "command not found") ]] && echo -ne "${GREEN}(err msg Cmd not found ok) ${END}" || echo -ne "${YEL}(err msg without \"Command not found\") ${END}"
[[ $code -eq 127 ]] && echo -e "${GREEN}(return status == 127)${END}" || echo -e "${YEL}(return status != 127)${END}"
rm -f stderr.txt stdout.txt outf

echo -ne "Test 4 : ./pipex Makefile yes cati outfile_no_w \t\t\t--> "
touch outfile_no_w && chmod u-w outfile_no_w
timeout --preserve-status 2 ./pipex Makefile "yes" "cati" outfile_no_w >stdout.txt 2> stderr.txt
code=$(echo $?)
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
[[ $(cat stderr.txt stdout.txt 2>/dev/null | grep -i "permission denied") ]] && echo -ne "${GREEN}(err msg Perm denied ok) ${END}" || echo -ne "${YEL}(err msg without \"Permission denied\") ${END}"
[[ $code -eq 1 ]] && echo -e "${GREEN}(return status == 1)${END}" || echo -e "${YEL}(return status != 1)${END}"
rm -f stderr.txt outf*

# executable (+ pas les droits)
echo -e "${BLU_BG}Custom exec:${END}"

echo -e "#include <stdio.h>\nint main(void){printf(\"yo\");}" > main.c 
mkdir -p dir1/dir2 ; gcc main.c ; gcc -o ls main.c ; gcc -o dir1/dir2/ls main.c
rm main.c

echo -ne "Test 1 : ./pipex Makefile ./a.out cat outf \t\t\t\t--> "
./pipex Makefile "./a.out" "cat" outf 2> stderr.txt
code=$(echo $?)
[[ -f outf && $(cat outf) == "yo" ]] && echo -ne "${GREEN}OK ${END}"|| echo -ne "${RED}KO ${END}"
[[ -s stderr.txt ]] && echo -ne "${RED}(you wrote on stderr) ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f stderr.txt outf

echo -ne "Test 2 : ./pipex Makefile ls ./ls outf \t\t\t\t\t--> "
./pipex Makefile "ls" "./ls" outf 2> stderr.txt
code=$(echo $?)
[[  -f outf && $(cat outf) == "yo" ]] && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ -s stderr.txt ]] && echo -ne "${RED}KO : you wrote on stderr ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f stderr.txt ls outf

echo -ne "Test 3 : ./pipex Makefile date dir1/dir2/ls outf\t\t\t--> "
./pipex Makefile "date" "dir1/dir2/ls" outf 2> stderr.txt
code=$(echo $?)
[[ -f outf && $(cat outf) == "yo" ]] && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ -s stderr.txt ]] && echo -ne "${RED}(you wrote on stderr) ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0) ${END}" || echo -e "${YEL}(return status != 0) ${END}"
rm -rf stderr.txt dir1/ outf

echo -ne "Test 4 : ./pipex Makefile ls ./a.out (chmod u-x) outf \t\t\t--> "
chmod u-x a.out
./pipex Makefile "ls" "./a.out" outf > stdout.txt 2> stderr.txt
code=$(echo $?)
[[ $code -eq 126 ]] && $([[ -f stderr.txt ]] && cat stderr.txt | grep -qi "permission denied") && echo -ne "${GREEN}OK (code 126 bien ouej) ${END}"
[[ $code -ne 126 ]] && echo -ne "${YEL}KO (code != 126). ${END}"
[[ -s stderr.txt ]] || echo -ne "${YEL}Stderr: no output. ${END}"
[[ -s stdout.txt ]] && echo -ne "${YEL}Stdout: unexpected output. ${END}"
cat stderr.txt stdout.txt 2>/dev/null | grep -qi "permission denied" && echo -e "${GREEN}(err msg permission denied)${END}" || echo -e "${YEL}(err msg != Permission denied)${END}"
rm -f stderr.txt stdout.txt a.out outf

# env -i
echo -e "${BLU_BG}Empty environnement:${END}"

echo -ne "Test 1 : env -i ./pipex Makefile cat ls outf \t\t\t\t--> "
env -i ./pipex Makefile "cat" "echo yo" outf > stderr.txt 2>&1
code=$(echo $?)
[[ -f outf ]] && cat outf | grep -q yo && ( echo -ne "${GREEN}OK - WOW t'es chaud, explique moi stp! ${END}" && [[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0) ${END}" || echo -e "${YEL}(return status != 0) ${END}" )
[[ -f stderr.txt && $(cat stderr.txt | grep -ic "command not found") -eq 2 ]] && echo -ne "${GREEN}OK ${END}"
[[ -f stderr.txt && $(cat stderr.txt | egrep -i "seg,*fault|dump" |wc -l|tr -d "[:blank:]") -gt 0  ]] && echo -ne "${RED}KO segfault ${END}"
[[ -f outf ]] && cat outf | grep -q yo ||( [[ $code -eq 127 ]] && echo -e "${GREEN}(return status == 127)${END}" || echo -e "${YEL}(return status != 127)${END}" )
rm -f outf stderr.txt

echo -ne "Test 2 : env -i ./pipex Makefile ${cat_path}/cat ${cat_path}/cat outf\t\t--> "
env -i ./pipex Makefile "${cat_path}/cat" "${cat_path}/cat" outf > stderr.txt 2>&1
code=$(echo $?)
diff Makefile outf >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ -f stderr.txt && $(cat stderr.txt | egrep -i "seg.*fault|dump" |wc -l|tr -d "[:blank:]") -gt 0 ]] && echo -ne "${RED}KO segfault ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf stderr.txt

# unset $PATH (with absolute cmd)
echo -e "${BLU_BG}\$PATH unset:${END}"
tmp_PATH=$PATH

echo -ne "Test 1 : unset PATH && ./pipex Makefile cat ls outf \t\t\t--> "
unset PATH
./pipex Makefile "ls" "cat" outf > stderr.txt 2>&1
code=$(echo $?)
PATH=$tmp_PATH && export PATH
[[ -f stderr.txt && $(cat stderr.txt | grep -ic "command not found") -eq 2 ]] && echo -ne "${GREEN}OK ${END}"
[[ -f stderr.txt && $(cat stderr.txt | wc -l) -ne 2 ]] && echo -ne "${YEL}KO (not two lines written to stderr)${END}"
[[ -f stderr.txt && $(cat stderr.txt | egrep -i "seg,*fault|dump" |wc -l|tr -d "[:blank:]") -gt 0  ]] && echo -ne "${RED}KO segfault ${END}"
[[ $code -eq 127 ]] && echo -e "${GREEN}(return status == 127)${END}" || echo -e "${YEL}(return status != 127)${END}"
rm -f outf stderr.txt

echo -ne "Test 2 : unset PATH && ./pipex Makefile ${cat_path}/cat ${cat_path}/cat outf \t--> "
unset PATH
./pipex Makefile "${cat_path}/cat" "${cat_path}/cat" outf > stderr.txt 2>&1
code=$(echo $?)
PATH=$tmp_PATH && export PATH
diff Makefile outf >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ -f stderr.txt && $(cat stderr.txt | egrep -i "seg,*fault|dump" |wc -l|tr -d "[:blank:]") -gt 0  ]] && echo -ne "${RED}KO segfault ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf stderr.txt

# valgrind
if [[ $os == "linux" ]] ; then

echo -e "${BLU_BG}Leaks via valgrind:${END}"

echo -ne "Test 1 : valgrind ./pipex Makefile cat cat outf \t\t\t--> "
$vlgppx ./pipex Makefile "cat" "cat" outf > vlg.txt 2>&1
first_proc=$(cat vlg.txt | grep -m1 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
second_proc=$(cat vlg.txt | grep -m2 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
main_proc=$(cat vlg.txt | grep -m3 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
fd=$(cat vlg.txt | grep -o  "Open file descriptor [0-9]*:" | sort | uniq | wc -l | tr -d "[:blank:]")
main_fd_open=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* open" | egrep -o "[0-9]*")
main_fd_std=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* std" | egrep -o "[0-9]*")
main_fd=$(( $main_fd_open - $main_fd_std ))
[[ $first_proc -eq 0 ]] && echo -ne "${GREEN}no leak cat${END}" || echo -ne "${RED}$first_proc leaks first cat${END}"
[[ $second_proc -eq 0 ]] && echo -ne "${GREEN} - no leak cat${END}" || echo -ne "${RED} - $second_proc leaks second cat${END}"
[[ $main_proc -eq 0 ]] && echo -ne "${GREEN} - no leak main${END}" || echo -ne "${RED} - $main_proc leaks main${END}"
[[ $fd -eq 0 ]] && echo -ne "${GREEN} - no extra fd (main+child)${END}" || echo -ne "${YEL} - $fd extra fd (main+child)${END}"
[[ $main_fd -eq 0 ]] && echo -e "${GREEN} - no extra fd on main${END}" || echo -e "${RED} - $fd extra fd on main${END}"
rm -f outf vlg.txt

echo -ne "Test 2 : valgrind ./pipex Makefile yes head outf \t\t\t--> "
timeout --preserve-status 2 $vlgppx ./pipex Makefile "yes" "head" outf > vlg.txt 2>&1
first_proc=$(cat vlg.txt | grep -m1 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
second_proc=$(cat vlg.txt | grep -m2 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
main_proc=$(cat vlg.txt | grep -m3 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
fd=$(cat vlg.txt | grep -o  "Open file descriptor [0-9]*:" | sort | uniq | wc -l | tr -d "[:blank:]")
main_fd_open=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* open" | egrep -o "[0-9]*")
main_fd_std=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* std" | egrep -o "[0-9]*")
main_fd=$(( $main_fd_open - $main_fd_std ))
echo -ne "${GREEN}$first_proc leaks yes (it's ok)${END}"
[[ $second_proc -eq 0 ]] && echo -ne "${GREEN} - no leak head${END}" || echo -ne "${RED} - $second_proc leaks head${END}"
[[ $main_proc -eq 0 ]] && echo -ne "${GREEN} - no leak main${END}" || echo -ne "${RED} - $main_proc leaks main${END}"
[[ $fd -eq 0 ]] && echo -ne "${GREEN} - no extra fd (main+child)${END}" || echo -ne "${YEL} - $fd extra fd (main+child)${END}"
[[ $main_fd -eq 0 ]] && echo -e "${GREEN} - no extra fd on main${END}" || echo -e "${RED} - $fd extra fd on main${END}"
rm -f outf vlg.txt

echo -ne "Test 3 : valgrind ./pipex Makefile ${bin_path}/cat ${bin_path}/head outf \t--> "
$vlgppx ./pipex Makefile ${bin_path}/cat ${bin_path}/head outf > vlg.txt 2>&1
first_proc=$(cat vlg.txt | grep -m1 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
second_proc=$(cat vlg.txt | grep -m2 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
main_proc=$(cat vlg.txt | grep -m3 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
fd=$(cat vlg.txt | grep -o  "Open file descriptor [0-9]*:" | sort | uniq | wc -l | tr -d "[:blank:]")
main_fd_open=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* open" | egrep -o "[0-9]*")
main_fd_std=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* std" | egrep -o "[0-9]*")
main_fd=$(( $main_fd_open - $main_fd_std ))
[[ $first_proc -eq 0 ]] && echo -ne "${GREEN}no leak cat${END}" || echo -ne "${RED}$second_proc leaks cat${END}"
[[ $second_proc -eq 0 ]] && echo -ne "${GREEN} - no leak head${END}" || echo -ne "${RED} - $second_proc leaks head${END}"
[[ $main_proc -eq 0 ]] && echo -ne "${GREEN} - no leak main${END}" || echo -ne "${RED} - $main_proc leaks main${END}"
[[ $fd -eq 0 ]] && echo -ne "${GREEN} - no extra fd (main+child)${END}" || echo -ne "${YEL} - $fd extra fd (main+child)${END}"
[[ $main_fd -eq 0 ]] && echo -e "${GREEN} - no extra fd on main${END}" || echo -e "${RED} - $fd extra fd on main${END}"
rm -f outf vlg.txt

echo -ne "Test 4 : valgrind ./pipex infile_no_r cat \"echo yo\" outfile_no_w \t--> "
touch infile_no_r outfile_no_w && chmod u-r infile_no_r && chmod u-w outfile_no_w
$vlgppx ./pipex infile_no_r "cat" "echo yo" outfile_no_w > vlg.txt 2>&1
first_proc=$(cat vlg.txt | grep -m1 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
second_proc=$(cat vlg.txt | grep -m2 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
main_proc=$(cat vlg.txt | grep -m3 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
fd=$(cat vlg.txt | grep -o  "Open file descriptor [0-9]*:" | sort | uniq | wc -l | tr -d "[:blank:]")
main_fd_open=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* open" | egrep -o "[0-9]*")
main_fd_std=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* std" | egrep -o "[0-9]*")
main_fd=$(( $main_fd_open - $main_fd_std ))
[[ $first_proc -eq 0 ]] && echo -ne "${GREEN}no leak cat${END}" || echo -ne "${RED}$first_proc leaks  cat${END}"
[[ $second_proc -eq 0 ]] && echo -ne "${GREEN} - no leak echo${END}" || echo -ne "${RED} - $second_proc leaks echo${END}"
[[ $main_proc -eq 0 ]] && echo -ne "${GREEN} - no leak main${END}" || echo -ne "${RED} - $main_proc leaks main${END}"
[[ $fd -eq 0 ]] && echo -ne "${GREEN} - no extra fd (main+child)${END}" || echo -ne "${YEL} - $fd extra fd (main+child)${END}"
[[ $main_fd -eq 0 ]] && echo -e "${GREEN} - no extra fd on main${END}" || echo -e "${RED} - $fd extra fd on main${END}"
rm -f infile* outfile* vlg.txt

echo -ne "Test 5 : valgrind ./pipex Makefile catiop \" \" outf \t\t\t--> "
$vlgppx ./pipex Makefile "catiop" " " outf > vlg.txt 2>&1
first_proc=$(cat vlg.txt | grep -m1 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
second_proc=$(cat vlg.txt | grep -m2 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
main_proc=$(cat vlg.txt | grep -m3 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
fd=$(cat vlg.txt | grep -o  "Open file descriptor [0-9]*:" | sort | uniq | wc -l | tr -d "[:blank:]")
main_fd_open=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* open" | egrep -o "[0-9]*")
main_fd_std=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* std" | egrep -o "[0-9]*")
main_fd=$(( $main_fd_open - $main_fd_std ))
[[ $first_proc -eq 0 ]] && echo -ne "${GREEN}no leak catiop${END}" || echo -ne "${RED}$first_proc leaks  catiop${END}"
[[ $second_proc -eq 0 ]] && echo -ne "${GREEN} - no leak empty cmd${END}" || echo -ne "${RED} - $second_proc leaks empty cmd${END}"
[[ $main_proc -eq 0 ]] && echo -ne "${GREEN} - no leak main${END}" || echo -ne "${RED} - $main_proc leaks main${END}"
[[ $fd -eq 0 ]] && echo -ne "${GREEN} - no extra fd (main+child)${END}" || echo -ne "${YEL} - $fd extra fd (main+child)${END}"
[[ $main_fd -eq 0 ]] && echo -e "${GREEN} - no extra fd on main${END}" || echo -e "${RED} - $fd extra fd on main${END}"
rm -f outf vlg.txt

echo -ne "Test 6 : valgrind ./pipex Makefile ./a.out (chmod u-x) \"echo yo\" outf \t--> "
echo -e "#include <stdio.h>\nint main(void){printf(\"yo\");}" > main.c && gcc main.c && rm main.c
chmod u-x a.out
$vlgppx ./pipex Makefile "./a.out" "echo yo" outf > vlg.txt 2>&1
first_proc=$(cat vlg.txt | grep -m1 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
second_proc=$(cat vlg.txt | grep -m2 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
main_proc=$(cat vlg.txt | grep -m3 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
fd=$(cat vlg.txt | grep -o  "Open file descriptor [0-9]*:" | sort | uniq | wc -l | tr -d "[:blank:]")
main_fd_open=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* open" | egrep -o "[0-9]*")
main_fd_std=$(cat vlg.txt | grep -m3 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* std" | egrep -o "[0-9]*")
main_fd=$(( $main_fd_open - $main_fd_std ))
[[ $first_proc -eq 0 ]] && echo -ne "${GREEN}no leak a.out${END}" || echo -ne "${RED}$first_proc leaks a.out${END}"
[[ $second_proc -eq 0 ]] && echo -ne "${GREEN} - no leak echo${END}" || echo -ne "${RED} - $second_proc leaks echo${END}"
[[ $main_proc -eq 0 ]] && echo -ne "${GREEN} - no leak main${END}" || echo -ne "${RED} - $main_proc leaks main${END}"
[[ $fd -eq 0 ]] && echo -ne "${GREEN} - no extra fd (main+child)${END}" || echo -ne "${YEL} - $fd extra fd (main+child)${END}"
[[ $main_fd -eq 0 ]] && echo -e "${GREEN} - no extra fd on main${END}" || echo -e "${RED} - $fd extra fd on main${END}"
rm -f outf a.out vlg.txt

fi

# process and zombies 
: << END_COMMENT 
Zombies only exists while child has returned and parent has not. As soon as parent returned,
child is adopted by the 'init' process (pid 1), collecting its status and removing it from process table.
We can find zombie with : 
	-> ps -e (or a|u|x) looking for <defunct> or Z+ in stat column
	-> top -bn1 looking for zombie nb on the second line, or Z in stat
we'll use second line of top. First check the nb, do the test, recheck the nb before pipex returned : if increased then pipex creates zombie
we need to get one child returned and not pipex so lets have a ./pipex sleep 3 sleep 1 and we be checking if sleep 1 became a z
about killing : seems like singint doesnot kill children of specified process, sigterm and sigkill do kill children
sigkill output on stdout, sigterm and singint dont
$! refers to the pid of the last pipeline launched in bg
END_COMMENT

echo -e "${BLU_BG}Zombies (children process not waited by pipex):${END}"
rm -rf *top_result zombies_test*

gcc -o popo popo.c

echo -ne "Test 1 : ./pipex Makefile \"sleep 3\" \"sleep 1\" outf \t\t\t--> "
start_Z_nb=$(top -bn1 | head -n2 | egrep -o "[0-9]* zombie$" | egrep -o "[0-9]*")
./pipex Makefile "sleep 3" "sleep 1" outf &
sleep 1
exec_Z_nb=$(top -bn1 | head -n2 | egrep -o "[0-9]* zombie$" | egrep -o "[0-9]*")
ps -aux | grep Z | grep -vi grep > zombie_test1
kill -s SIGTERM $! > /dev/null 2>&1 || kill -s SIGKILL $! > /dev/null 2>&1
[[ $(( $exec_Z_nb - $start_Z_nb )) -eq 0 ]] && echo -e "${GREEN}OK (sleep 1 did not became a zombie)${END}" && rm -f zombie_test1
[[ $(( $exec_Z_nb - $start_Z_nb )) -gt 0 ]] && echo -e "${YEL}KO: $(( $exec_Z_nb - $start_Z_nb )) process became zombie before pipex returned (most probably sleep 1, please check 'zombie_test1')${END}"
rm -f outf

echo -ne "Test 2 : ./pipex Makefile \"sleep 1\" \"sleep 3\" outf \t\t\t--> "
start_Z_nb=$(top -bn1 | head -n2 | egrep -o "[0-9]* zombie$" | egrep -o "[0-9]*")
./pipex Makefile "sleep 1" "sleep 3" outf &
sleep 1 
exec_Z_nb=$(top -bn1 | head -n2 | egrep -o "[0-9]* zombie$" | egrep -o "[0-9]*")
ps -aux | grep Z | grep -vi grep > zombie_test2
kill -s SIGTERM $! > /dev/null 2>&1 || kill -s SIGKILL $! > /dev/null 2>&1
[[ $(( $exec_Z_nb - $start_Z_nb )) -eq 0 ]] && echo -e "${GREEN}OK (sleep 1 did not became a zombie)${END}" && rm -f zombie_test2
[[ $(( $exec_Z_nb - $start_Z_nb )) -gt 0 ]] && echo -e "${YEL}KO: $(( $exec_Z_nb - $start_Z_nb )) process became a zombie before pipex returned (most probably sleep 1, please check 'zombie_test2')${END}"
rm -f outf

echo -ne "Test 3 : ./pipex bad_infile ls \"sleep 2\" outf \t\t\t\t--> "
start_Z_nb=$(top -bn1 | head -n2 | egrep -o "[0-9]* zombie$" | egrep -o "[0-9]*")
./pipex bad_infile ls "sleep 2" outf > /dev/null 2>&1 &
sleep 1
exec_Z_nb=$(top -bn1 | head -n2 | egrep -o "[0-9]* zombie$" | egrep -o "[0-9]*")
ps -aux | grep Z | grep -vi grep > zombie_test3
kill -s SIGTERM $! > /dev/null 2>&1 || kill -s SIGKILL $! > /dev/null 2>&1
[[ $(( $exec_Z_nb - $start_Z_nb )) -eq 0 ]] && echo -e "${GREEN}OK (ls did not became a zombie)${END}" && rm -f zombie_test3
[[ $(( $exec_Z_nb - $start_Z_nb )) -gt 0 ]] && echo -e "${YEL}KO: $(( $exec_Z_nb - $start_Z_nb )) process became a zombie before pipex returned (most probably ls, please check 'zombie_test3')${END}"
rm -f outf

echo -ne "Test 4 : ./pipex Makefile bad_cmd \"sleep 1\" outf \t\t\t--> "
start_Z_nb=$(top -bn1 | head -n2 | egrep -o "[0-9]* zombie$" | egrep -o "[0-9]*")
./pipex Makefile bad_cmd "sleep 1" outf > /dev/null 2>&1 & 
exec_Z_nb=$(top -bn1 | head -n2 | egrep -o "[0-9]* zombie$" | egrep -o "[0-9]*")
ps -aux | grep Z | grep -vi grep > zombie_test4
kill -s SIGTERM $! > /dev/null 2>&1 || kill -s SIGKILL $! > /dev/null 2>&1
[[ $(( $exec_Z_nb - $start_Z_nb )) -eq 0 ]] && echo -e "${GREEN}OK (bad_cmd did not became a zombie)${END}" && rm -f zombie_test4
[[ $(( $exec_Z_nb - $start_Z_nb )) -gt 0 ]] && echo -e "${YEL}KO: $(( $exec_Z_nb - $start_Z_nb )) process became a zombie before pipex returned (most probably bad_cmd, please check 'zombie_test4')${END}"
rm -f outf


# -----------------------------------------------------------------------------------------------------------------------------------------
# BONUS TESTS : 
# -----------------------------------------------------------------------------------------------------------------------------------------
if [[ ! $1 =~ -m$|-mandatory$ ]] ; then

[[ $bonus -eq 1 ]] && make ${rule_bonus} >/dev/null 2>&1 

echo -e "${YEL_BG}Bonus tests${END}"

# multi cmd
echo -e "${BLU_BG}Bonus multi cmds:${END}"

echo -ne "Test 1 : ./${pipex_bonus} Makefile cat cat cat t2_output\t\t\t\t\t--> "
touch t2_output
./${pipex_bonus} "Makefile" "cat" "cat" "cat" "t2_output" >/dev/null 2>&1 
code=$(echo $?)
diff Makefile t2_output >/dev/null 2>&1 && echo -ne "${GREEN}OK${END}" || echo -ne "${RED}KO${END}"
[[ $code -eq 0 ]] && echo -e " ${GREEN}(+ return status == 0)${END}" || echo -e "${YEL}(- return status != 0)${END}"
rm -f t2_*

echo -ne "Test 2 : ./${pipex_bonus} Makefile ls cat cat cat cat cat cat cat cat cat cat t2_output\t--> "
touch t2_output t2_expected
./${pipex_bonus} Makefile ls cat cat cat cat cat cat cat cat cat cat t2_output >/dev/null 2>&1
code=$(echo $?)
ls > t2_expected
diff t2_expected t2_output >/dev/null 2>&1 && echo -ne "${GREEN}OK${END}" || echo -ne "${RED}KO${END}"
[[ $code -eq 0 ]] && echo -e " ${GREEN}(+ return status == 0)${END}" || echo -e "${YEL}(- return status != 0)${END}"
rm -f t2_*

echo -ne "Test 3 : ./${pipex_bonus} Makefile yes headi pwd \"cat -e\" t2_output\t\t\t--> "
touch t2_output t2_expected
timeout --preserve-status 2 ./${pipex_bonus} Makefile yes headi pwd "cat -e" t2_output > stderr.txt 2>&1
code=$(echo $?)
pwd | cat -e > t2_expected
diff t2_expected t2_output >/dev/null 2>&1 && echo -ne "${GREEN}OK${END}" || echo -ne "${RED}KO${END}"
[[ -f stderr.txt && $(cat stderr.txt | grep -i "command not found") ]] && echo -ne "${GREEN} (+ err msg)${END}" || echo -ne "${YEL} (- err msg without \"Command not found\")${END}"
[[ $code -eq 0 ]] && echo -e " ${GREEN}(+ return status == 0)${END}" || echo -e "${YEL}(- return status != 0)${END}"
rm -f t2_* stderr.txt

echo -ne "Test 4 : ./${pipex_bonus} Makefile date \"man env\" cat \"grep -i exit\" t2_output\t\t--> "
touch t2_output t2_expected
./${pipex_bonus} Makefile date "man env" cat "grep -i exit" t2_output >/dev/null 2>&1
code=$(echo $?)
date | man env | cat | grep -i exit > t2_expected 2>/dev/null
diff t2_expected t2_output >/dev/null 2>&1 && echo -ne "${GREEN}OK${END}" || echo -ne "${RED}KO${END}"
[[ $code -eq 0 ]] && echo -e " ${GREEN}(+ return status == 0)${END}" || echo -e "${YEL}(- return status != 0)${END}"
rm -f t2_* 

echo -ne "Test 5 : ./${pipex_bonus} Makefile cat ls \"sleep 3\" date env ls outf \t\t\t--> "
start_Z_nb=$(top -bn1 | head -n2 | egrep -o "[0-9]* zombie$" | egrep -o "[0-9]*")
./${pipex_bonus} Makefile cat ls "sleep 3" date env ls outf >/dev/null 2>&1 &
sleep 1
exec_Z_nb=$(top -bn1 | head -n2 | egrep -o "[0-9]* zombie$" | egrep -o "[0-9]*")
ps -aux | grep Z | grep -vi grep > zombie_test5
kill -s SIGTERM $! > /dev/null 2>&1 || kill -s SIGKILL $! > /dev/null 2>&1
[[ $(( $exec_Z_nb - $start_Z_nb )) -eq 0 ]] && echo -e "${GREEN}OK (no zombie)${END}" && rm -f zombie_test5
[[ $(( $exec_Z_nb - $start_Z_nb )) -gt 0 ]] && echo -e "${YEL}KO: $(( $exec_Z_nb - $start_Z_nb )) process became zombie before pipex returned (please check 'zombie_test5)${END}"
rm -f outf

if [[ $os == "linux" ]] ; then
echo -ne "Test 6 : valgrind ./${pipex_bonus} Makefile cat cat cat cat cat cat outf\t\t\t--> "
$vlgppx ./${pipex_bonus} Makefile cat cat cat cat cat cat outf > vlg.txt 2>&1
leaks=$(cat vlg.txt | grep -A 1 "HEAP SUMMARY" | tail -n1 | grep -o "[0-9]* bytes" | cut -d' ' -f1)
fd=$(cat vlg.txt | grep -o  "Open file descriptor [0-9]*:" | sort | uniq | wc -l | tr -d "[:blank:]")
main_fd_open=$(cat vlg.txt | grep -m7 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* open" | egrep -o "[0-9]*")
main_fd_std=$(cat vlg.txt | grep -m7 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* std" | egrep -o "[0-9]*")
main_fd=$(( $main_fd_open - $main_fd_std ))
[[ $leaks -eq 0 ]] && echo -ne "${GREEN}no leak${END}" || echo -ne "${RED}$leaks leaks${END}"
[[ $fd -eq 0 ]] && echo -ne "${GREEN} - no extra fd (main+child)${END}" || echo -ne "${YEL} - $fd extra fd (main+child)${END}"
[[ $main_fd -eq 0 ]] && echo -e "${GREEN} - no extra fd on main${END}" || echo -e "${RED} - $fd extra fd on main${END}"
rm -f outf vlg.txt
fi

# here doc (ctrl d : can't figure out how to send EOF to pipex here_doc via a script)
echo -e "${BLU_BG}Bonus here_doc:${END}"
echo -ne "Test 1 : ./${pipex_bonus} here_doc lim cat cat outf (to create + tests limiteur)\t\t--> "
echo -e "yolim\nyi lim\nlime\nlim" | ./${pipex_bonus} here_doc lim cat cat outf >/dev/null 2>&1
code=$(echo $?)
echo -e "yolim\nyi lim\nlime" > outf_expected 2>/dev/null
diff outf outf_expected  >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"

echo -ne "Test 2 : ./${pipex_bonus} here_doc lim cat cat outf (to append)\t\t\t\t--> "
echo -e "yo\nyip\nlim" | ./${pipex_bonus} here_doc lim cat cat outf >/dev/null 2>&1
code=$(echo $?)
echo -e "yo\nyip" >> outf_expected 2>/dev/null
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf outf_expected

echo -ne "Test 3 : ./${pipex_bonus} here_doc lim cat outf (arg<5)\t\t\t\t\t--> "
echo -e "mambo jambo\nlim"| ./${pipex_bonus} here_doc lim cat outf >err.txt 2>&1
code=$(echo $?)
[[ ! -f outf ]] && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO (outf has been created)${END}"
[[ $code -gt 0 ]] && echo -e "${GREEN}(return status > 0)${END}" || echo -e "${YEL}(return status == 0)${END}"
rm -f outf err.txt

echo -ne "Test 4 : ./${pipex_bonus} here_doc lim cat cat \"head -n2\" outf (multicmd)\t\t--> "
echo -e "yo\nyi\nyop\nlim" | ./${pipex_bonus} here_doc lim cat cat "head -n2" outf >/dev/null 2>&1
code=$(echo $?)
echo -e "yo\nyi\nyop" | head -n2 > outf_expected 2>/dev/null
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf outf_expected

echo -ne "Test 5 : ./${pipex_bonus} here_doc lim cat cat outf_no_w\t\t\t\t\t--> "
touch outf_no_w && chmod u-w outf_no_w
echo -e "yo\nyi\nlim" | ./${pipex_bonus} here_doc lim cat cat outf_no_w >/dev/null 2>&1
code=$(echo $?)
egrep -q "yo|yi" outf_no_w && echo -ne "${RED}KO ${END}" || echo -ne "${GREEN}OK ${END}"
[[ $code -eq 1 ]] && echo -e "${GREEN}(return status == 1)${END}" || echo -e " ${YEL}(return status != 1)${END}"
rm -f outf_no_w

echo -ne "Test 6 : ./${pipex_bonus} here_doc lim lsopi \"echo yo\" outf \t\t\t\t--> "
echo "salut" > outf && echo "salut" > outf_expected
echo -e "yayaya\nlim" | ./${pipex_bonus} here_doc lim lsopi "echo yo" outf >/dev/null 2>&1
code=$(echo $?)
echo yo >> outf_expected
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf*

if [[ $os == "linux" ]] ; then
echo -ne "Test 7 : valgrind ./${pipex_bonus} here_doc lim cat cat outf \t\t\t\t--> "
echo -e "yolim\nyop lim\nlim" | $vlgppx ./${pipex_bonus} here_doc lim cat cat outf > vlg.txt 2>&1
first_proc=$(cat vlg.txt | grep -m1 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
second_proc=$(cat vlg.txt | grep -m2 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
main_proc=$(cat vlg.txt | grep -m4 -A 1 "HEAP SUMMARY" | tail -n1 | egrep -o "[0-9]*,?[0-9]* bytes" | cut -d' ' -f1)
fd=$(cat vlg.txt | grep -o  "Open file descriptor [0-9]*:" | sort | uniq | wc -l | tr -d "[:blank:]")
main_fd_open=$(cat vlg.txt | grep -m4 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* open" | egrep -o "[0-9]*") # -m4 (not m3) if process fork for heredoc
main_fd_std=$(cat vlg.txt | grep -m4 "FILE DESCRIPTORS:" | tail -n1 | egrep -o "[0-9]* std" | egrep -o "[0-9]*")
main_fd=$(( $main_fd_open - $main_fd_std ))
[[ $first_proc -eq 0 ]] && echo -ne "${GREEN}no leak cat${END}" || echo -ne "${RED}$first_proc leaks  cat${END}"
[[ $second_proc -eq 0 ]] && echo -ne "${GREEN} - no leak cat${END}" || echo -ne "${RED} - $second_proc leaks cat${END}"
[[ $main_proc -eq 0 ]] && echo -ne "${GREEN} - no leak main${END}" || echo -ne "${RED} - $main_proc leaks main${END}"
[[ $fd -eq 0 ]] && echo -ne "${GREEN} - no extra fd (main+child)${END}" || echo -ne "${YEL} - $fd extra fd (main+child)${END}"
[[ $main_fd -eq 0 ]] && echo -e "${GREEN} - no extra fd on main${END}" || echo -e "${RED} - $fd extra fd on main${END}"
rm -f outf vlg.txt
fi

fi


# -----------------------------------------------------------------------------------------------------------------------------------------
# ADDITIONNAL TESTS : mostly about parsing. Note that double quotes cannot be parsed using bash grammar bc of project's argument format
# -----------------------------------------------------------------------------------------------------------------------------------------
if [[ ! $1 =~ -m$|-mandatory$ && ! $1 =~ -mb$ ]] ; then

echo -e "${YEL_BG}Additional tests (not all required to pass to validate pipex)${END}"

# quotes
echo -e "${BLU_BG}Single quotes parsing:${END}"

echo -ne "Test 1 : ./pipex Makefile \"echo yo\" \"echo 'a' 'b' 'c'\" outf \t\t--> "
./pipex Makefile "echo yo" "echo 'a' 'b' 'c'" outf 2>/dev/null
code=$(echo $?)
echo 'a' 'b' 'c' > outf_expected
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf*

echo -ne "Test 2 : ./pipex Makefile cat \"grep 'clean'\" outf \t\t\t--> "
./pipex Makefile "cat" "grep 'clean'" outf 2>/dev/null
code=$(echo $?)
cat Makefile | grep 'clean' > outf_expected
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf*

echo -ne "Test 3 : ./pipex Makefile cat \"cut -d'=' -f1\" outf \t\t\t--> "
./pipex Makefile "cat" "cut -d'=' -f1" outf 2>/dev/null
code=$(echo $?)
cat Makefile | cut -d'=' -f1 > outf_expected
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf*

echo -ne "Test 4 : ./pipex Makefile cat \"echo ''yo'\" outf \t\t\t--> "
./pipex Makefile "cat" "echo ''yo'" outf 2>/dev/null
code=$(echo $?)
echo outf | grep -q yo && echo -ne "${RED}KO (odd nb of quotes) ${END}" || echo -ne "${GREEN}OK ${END}" 
[[ $code -ne 0 ]] && echo -e "${GREEN}(return status != 0)${END}" || echo -e "${YEL}(return status == 0)${END}"
rm -f outf*

# <spaces> (if pb, stop using ft_split with space as separator. Think about a char (not unsigned?!) value you would never receive in argv. Think about spaces enclosed in single quotes too)
echo -e "${BLU_BG}Spaces parsing:${END}"

echo -ne "Test 1 : ./pipex Makefile \"echo yo\" \"echo ' '\" outf \t\t\t--> "
./pipex Makefile "echo yo" "echo ' '" outf 2>/dev/null
code=$(echo $?)
echo ' ' > outf_expected
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf*

echo -ne "Test 2 : ./pipex Makefile \"echo yo\" \"echo ' hello '\" outf \t\t--> "
./pipex Makefile "echo yo" "echo ' hello '" outf 2>/dev/null
code=$(echo $?)
echo ' hello ' > outf_expected
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf*

echo -ne "Test 3 : ./pipex Makefile cat \"cut -d' ' -f1\" outf \t\t\t--> "
./pipex Makefile "cat" "cut -d' ' -f1" outf 2>/dev/null
code=$(echo $?)
cat Makefile | cut -d' ' -f1 > outf_expected
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf*

echo -ne "Test 4 : touch \"t file\" && ./pipex Makefile cat \"ls 't file'\" outf \t--> "
touch "t file"
./pipex Makefile "cat" "ls -l 't file'" outf 2>/dev/null
code=$(echo $?)
ls -l 't file' > outf_expected
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf* 't file'

# backslash (cancels interpretation on the following metachar ; it is not even required in minishell ...)
echo -e "${BLU_BG}Backlash parsing:${END}"

echo -ne "Test 1 : touch t\ file && ./pipex Makefile cat \"ls t\ file\" outf \t--> "
touch "t file"
./pipex Makefile "cat" "ls -l t\ file" outf 2>/dev/null
code=$(echo $?)
ls -l t\ file > outf_expected
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf* 't file'

echo -ne "Test 2 : touch 't\ file' && ./pipex Makefile cat \"ls 't\ file'\" outf \t--> "
touch 't\ file'
./pipex Makefile cat "ls 'test\ file'" outf 2>/dev/null
code=$(echo $?)
ls 't\ file' > outf_expected
diff outf outf_expected >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -e "${GREEN}(return status == 0)${END}" || echo -e "${YEL}(return status != 0)${END}"
rm -f outf* 't\ file'

# fd limit (multi cmd bonus must be done)
# lets asumme : 2 fd (for in/outfile) + 2 fd * (nb of cmd -1) --> 510 cmd ok ; 511 cmds == 1024 fd
[[ $bonus -eq 1 ]] && make ${rule_bonus} >/dev/null 2>&1
echo -e "${BLU_BG}Reaching 1024 fd openned:${END}"

echo -ne "Test 1 : ./$pipex_bonus Makefile cat (510 times) outf \t\t\t\t--> "
./${pipex_bonus} Makefile cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat outf >err 2>&1
code=$(echo $?)
diff Makefile outf >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${RED}KO ${END}"
[[ $code -eq 0 ]] && echo -ne "${GREEN}(return status == 0) ${END}" || echo -ne "${YEL}(return status != 0) ${END}"
cat err | egrep -qi "segfault|segmentation|core ?dump" && echo -e "${RED}SUPER KO segfault${END}" || echo -e "${GREEN}(no segfault)${END}"
rm -f outf err

echo -ne "Test 2 : ./$pipex_bonus Makefile cat (511 times) outf \t\t\t\t--> "
./$pipex_bonus Makefile cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat outf >err 2>&1
code=$(echo $?)
diff Makefile outf >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${YEL}KO ${END}"
[[ $code -eq 0 ]] && echo -ne "${GREEN}(return status == 0) ${END}" || echo -ne "${YEL}(return status != 0) ${END}"
cat err | grep -i "open" | grep -qi "files" && echo -ne "${GREEN}(err msg with open files) ${END}"
cat err | egrep -qi "segfault|segmentation|core ?dump" && echo -e "${RED}SUPER KO segfault${END}" || echo -e "${GREEN}(no segfault)${END}"
rm -f outf err

echo -ne "Test 3 : ./$pipex_bonus Makefile cat (521 times) outf \t\t\t\t--> "
./$pipex_bonus Makefile cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat \
 cat cat cat cat cat cat cat outf >err 2>&1
code=$(echo $?)
diff Makefile outf >/dev/null 2>&1 && echo -ne "${GREEN}OK ${END}" || echo -ne "${YEL}KO ${END}"
[[ $code -eq 0 ]] && echo -ne "${GREEN}(return status == 0) ${END}" || echo -ne "${YEL}(return status != 0) ${END}"
cat err | grep -i "open" | grep -qi "files" && echo -ne "${GREEN}(err msg with open files) ${END}"
cat err | egrep -qi "segfault|segmentation|core ?dump" && echo -e "${RED}SUPER KO segfault${END}" || echo -e "${GREEN}(no segfault)${END}"
rm -f outf err

fi

# end
make fclean >/dev/null 2>&1
