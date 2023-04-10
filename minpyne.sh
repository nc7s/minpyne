#!/bin/sh

NAME='minpyne'
INSTALLED_CHECK_VERSIONS=$(echo '3.11 3.10 3.9 3.8 3.7' | tr ' ' '\n')

py_bin=''
venv_base=''
ver_file=''

show_help() {
	cat << EOF
Usage: $NAME COMMAND

COMMANDs:
    local   Set up or re-set up a virtualenv with the specified version or
            Python, or if no argument given, shows which Python is used.
            The argument may be a Python version number in X.Y format or path 
            to a Python executable.

    python  Find the appropriate Python version,
    pip     its pip or
    venv    its venv module,
            then run and pass all arguments to it.
EOF
}

recursive_find() {
	cur="$PWD"
	while [ "$cur" != '/' ]; do
		if [ -e "$cur/$1" ]; then
			ver_file="$cur/$1"
			return
		fi
		cur=$(dirname "$cur")
	done
	return 1
}

# venv's pyvenv.cfg
check_pyvenv_cfg() {
	if recursive_find pyvenv.cfg; then
		# `version = X.Y.Z`
		venv_base=$(dirname "$ver_file")
		py_bin="$venv_base/bin/python"
	else
		return 1
	fi
}

# Look for the highest version installed in PATH
check_path() {
	for v in $INSTALLED_CHECK_VERSIONS; do
		path=$(which python$v)
		if [ -n "$path" ]; then
			py_bin="$path"
			break
		fi
	done
	return 1
}

check_ver() {
	check_pyvenv_cfg || check_path
	if [ -z $py_bin ]; then
		echo "No available Python executable found. Please install one."
		exit 1
	fi
}

run_python() {
	$py_bin $@
}

run_pip() {
	run_python -m pip $@
}

run_venv() {
	run_python -m venv $@
}

cmd_local() {
	if [ -z "$1" ]; then
		run_python -V
		if [ -e "$(dirname $py_bin)/../pyvenv.cfg" ]; then
			link=$(readlink -f $py_bin)
			if [ -n "$link" ]; then
				echo "$py_bin (virtualenv, links to $link)"
			else
				echo "$py_bin (virtualenv, copied)"
			fi
		else
			echo "$py_bin"
		fi
	else
		if [ -e "$1" ]; then
			py_bin="$1"
		else
			bin=$(which python$1)
			if [ -n "$bin" ]; then
				py_bin=$bin
			else
				echo "Can not find Python $1 executable."
				exit 1
			fi
		fi
		rm -r bin/ || true
		run_venv .
	fi
}

as_myself() {
	command=$1
	shift
	case $command in
		local) cmd_local $1;;

		python) run_python $@;;
		pip) run_pip $@;;
		venv) run_venv $@;;

		*) show_help;;
	esac
}

check_ver

case $(basename "$0") in
	python) run_python $@;;
	pip) run_pip $@;;
	venv) run_venv $@;;
	*) as_myself $@;;
esac

