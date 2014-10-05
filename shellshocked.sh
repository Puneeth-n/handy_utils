#!/bin/bash

echo -e "\e[1m\e[44m  Shell Shocked?\e[0m\e[44m by Puneeth\e[49m "
echo -e "\e[1m"
echo "  This script will quickly check if your system is vulernable to the "
echo "  Shellshock and Aftershock bugs."
echo -e " "
echo -e "  \e[1mBash version  \e[0m: `bash --version | head -n1`"
echo -e "  \e[1mKernel release\e[0m: `uname -r`"
echo -e "  \e[1mKernel version\e[0m: `uname -v`"
echo -e "  \e[1mProcessor     \e[0m: `uname -p`"
echo -e "\n\n"

warn() {
	if [ "$scary" == "1" ]; then
		echo -e "  \033[91mVulnerable to $1\033[39m"
	else
		echo -e "  \033[93mFound non-exploitable $1\033[39m"
    fi
}

good() {
	echo -e "  \033[92mNot vulnerable to $1\033[39m"
}

[ -n "$1" ] && bash=$(which $1) || bash=$(which bash)

#r=`a="() { echo x;}" $bash -c a 2>/dev/null`
if [ -n "$(env 'a'="() { echo x;}" $bash -c a 2>/dev/null)" ]; then
	echo -e "  \033[91mVariable function parser active, maybe vulnerable to unknown parser bugs\033[39m"
	scary=1
elif [ -n "$(env 'BASH_FUNC_a%%'="() { echo x;}" $bash -c a 2>/dev/null)" ]; then
	echo -e "  \033[92mVariable function parser pre/suffixed [%%, upstream], bugs not exploitable\033[39m"
	scary=0
elif [ -n "$(env 'BASH_FUNC_a()'="() { echo x;}" $bash -c a 2>/dev/null)" ]; then
	echo -e "  \033[92mVariable function parser pre/suffixed [(), redhat], bugs not exploitable\033[39m"
	scary=0
elif [ -n "$(env 'BASH_FUNC_<a>%%'="() { echo x;}" $bash -c a 2>/dev/null)" ]; then
	echo -e "  \033[92mVariable function parser pre/suffixed [<..>%%, apple], bugs not exploitable\033[39m"
	scary=0
else
	echo -e "  \033[92mVariable function parser inactive, bugs not exploitable\033[39m"
	scary=0
fi


r=`env x="() { :; }; echo x" $bash -c "" 2>/dev/null`
if [ -n "$r" ]; then
	warn "CVE-2014-6271 (original shellshock)"
else
	good "CVE-2014-6271 (original shellshock)"
fi

cd /tmp;rm echo 2>/dev/null
env x='() { function a a>\' $bash -c echo 2>/dev/null > /dev/null
if [ -e echo ]; then
	warn "CVE-2014-7169 (taviso bug)"
else
	good "CVE-2014-7169 (taviso bug)"
fi

$($bash -c "true $(printf '<<EOF %.0s' {1..80})" 2>/tmp/bashcheck.tmp)
ret=$?
grep -q AddressSanitizer /tmp/bashcheck.tmp
if [ $? == 0 ] || [ $ret == 139 ]; then
	warn "CVE-2014-7186 (redir_stack bug)"
else
	good "CVE-2014-7186 (redir_stack bug)"
fi


$bash -c "`for i in {1..200}; do echo -n "for x$i in; do :;"; done; for i in {1..200}; do echo -n "done;";done`" 2>/dev/null
if [ $? != 0 ]; then
	warn "CVE-2014-7187 (nested loops off by one)"
else
	echo -e "  \033[96mTest for CVE-2014-7187 not reliable without address sanitizer\033[39m"
fi

$($bash -c "f(){ x(){ _;};x(){ _;}<<a;}" 2>/dev/null)
if [ $? != 0 ]; then
	warn "CVE-2014-6277 (lcamtuf bug #1)"
else
	good "CVE-2014-6277 (lcamtuf bug #1)"
fi

if [ -n "$(env x='() { _;}>_[$($())] { echo x;}' $bash -c : 2>/dev/null)" ]; then
	warn "CVE-2014-6278 (lcamtuf bug #2)"
elif [ -n "$(env BASH_FUNC_x%%='() { _;}>_[$($())] { echo x;}' $bash -c : 2>/dev/null)" ]; then
	warn "CVE-2014-6278 (lcamtuf bug #2)"
elif [ -n "$(env 'BASH_FUNC_x()'='() { _;}>_[$($())] { echo x;}' $bash -c : 2>/dev/null)" ]; then
	warn "CVE-2014-6278 (lcamtuf bug #2)"
else
	good "CVE-2014-6278 (lcamtuf bug #2)"
fi

if [ "$scary" == 1 ]
then
  echo " "
  echo -e "  \e[1mThe version of Bash running on your system is vulnerable. It is "
  echo "  important that you update it as soon as possible"
  echo -e "\e[0m "

else
  echo " "
  echo "  It looks as though your version of Bash is up to date and safe."
  echo " "
fi

exit
