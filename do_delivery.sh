#!/bin/bash
#
# Copyright © Alexey Tulia 2012
#
# Packages changed files inside a git repository beginning from specified revision
#
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#	
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#	
#	You should have received a copy of the GNU General Public License
#	along with this program.  If not, see <http://www.gnu.org/licenses/>.


# Prints the functioning of this program
function printUsage(){
	cat >&2 << EOF
==================================================
Git packaging script version 0.0.1 by Alexey Tulia
==================================================

Usage:
     do_delivery [-n "name"] [-o <output path>] [-r <revision>]
                 [-p <repository path>] [-?]

Filenames and Paths:
    -n "name"               Set a base name for the archive package.
    -o <output path>        The package should be put in this dir (if omitted
                            tries to put files in the 'packages' directory of
                            the git repository, if present).
    -p <repository path>    The git repository path, defaults to "." (current
                            working directory).

Revisions:

    -r                      Set revision number to generate change set package from.

EOF
	exit 2;
}


function setArchiveFilename(){
    day=$(( `date +%s` ))
	export archive_filename="${archive_name}-$( date -r ${day} '+%Y%m%d' )";
}


function setDefaults(){

	# Set default output path. Note: do this BEFORE cding into git path!
	if [ -z "${path_output}" ]; then
		setOutputPath "./packages";
	fi;

	if [ -z "${path_git}" ]; then
		setGitPath ".";
	else
		cd "${path_git}";
	fi;

	if [ -z "${archive_name}" ]; then
		setArchiveName;
	fi;

	setArchiveFilename;
}

# Set the archive version
setRevisionFrom(){
	revision="${1}";

	# If none provide then find it
	if [ -z "${revision}" ]; then
		echo "Git repository revision is not passed...Exiting";
		exit 1;
	fi;
	
	export revision_from="${revision}";
}


# For verbose operation only, show each and every option.
function showOptions(){ # TODO
		cat << EOF
===> Archive filename: "${archive_filename}"
===> Revisions affected: "${revision_from}-->HEAD"
===> Output path: "${path_output}"
===> Git repository: "${path_git:-.}"
EOF
}

# Set the path into which to put output files
function setOutputPath(){
	trypath_out="${1}";
    echo "Output path: ${trypath_out}"
	if [ -z "${path_output}" ]; then
		result="$(test -d "${trypath_out}" && test -w "${trypath_out}"; echo $?; )";

		if [ "${result}" -eq 0 ]; then
			# Get the canonical full path for output
			fullpath_out="$(pwd -P "${trypath_out}")/";
            echo "Fullpath0:${fullpath_out}"
			export path_output="${fullpath_out}";
		else
			echo "Error: output path \"${trypath_out}\" isn't a writable directory." >&2
			return 1;
		fi;
	else
		echo "Error: you can't set more than one output path." >&2;
		exit 1;
	fi; 
}

# Set the name of the archive as param, if set, or git repo's name
function setArchiveName(){
	name="${1}";
    
	if [ -z "${archive_name}" ]; then
		export archive_name="${name}";
	else
		echo "Error: you must provide archive name. Aborting";
		exit 1;
	fi;
}

# Set the path of the git repository
function setGitPath(){
	trypath="${1}";
    echo "Git path: ${trypath}"
	if [ -z "${path_git}" ]; then
		result="$(test -d "${trypath}" && cd "${trypath}" && git status &>/dev/null; echo $?)";

		if [ "${result}" -eq 0 ]; then
			# Get the canonical full path for the repository
			fullpath="$(pwd -P "${trypath}")/";
            echo "Fullpath1: ${fullpath}"
			export path_git="${fullpath}";
		else
			echo "Error: git path \"${trypath}\" isn't a cd-able directory or a git repository." >&2
			return 1;
		fi;
	else
		echo "Error: you can't set more than one git path." >&2;
		exit 1;
	fi; 
}

# Creates the archives of the files, leaving space for other inclusions
function createArchive(){
    
    IFS=$'\n'
    files=($(git diff --name-only $revision_from HEAD))

	options="--format=tar.gz --output=\"${path_output}${archive_filename}.tgz\" --prefix=\"${archive_name}/\" ${revision_from} ${files[@]}";

	echo "===> Creating tar.gz archive..."
    echo $options | xargs git archive
    echo "===> Done!"
}

# Parse command options
function parseOptions(){
	set -e;

	while getopts 'r:n:o:p:?' flag; do
		case $flag in
			'o') setOutputPath "${OPTARG}";;
			'n') setArchiveName "${OPTARG}";;
            'r') setRevisionFrom "${OPTARG}";;
			'p') setGitPath "${OPTARG}";;
			'?') printUsage;;
			default) printUsage;;
		esac;
	done;

	if [ ! -z "${@:$OPTIND}" ]; then
		echo "Error: argument(s) \"${@:$OPTIND}\" are irrelevant. Aborting." >&2;
		printUsage;
	fi;
}


# Main part
parseOptions $*;
setDefaults;
showOptions;
createArchive;
