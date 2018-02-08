#!/bin/bash
#
# Copyright (C) 2017 Nathan Chancellor
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>


###########
#         #
#  USAGE  #
#         #
###########

# PURPOSE: Remove Substratum support from LineageOMS org merged into LineageOS repos
#
# USAGE: $ bash resset_lineage_oms.sh -h


############
#          #
#  COLORS  #
#          #
############

BOLD="\033[1m"
GREEN="\033[01;32m"
RED="\033[01;31m"
RESTORE="\033[0m"


###############
#             #
#  FUNCTIONS  #
#             #
###############

# PRINTS A FORMATTED HEADER TO POINT OUT WHAT IS BEING DONE TO THE USER
function echoText() {
    echo -e ${RED}
    echo -e "====$( for i in $( seq ${#1} ); do echo -e "=\c"; done )===="
    echo -e "==  ${1}  =="
    echo -e "====$( for i in $( seq ${#1} ); do echo -e "=\c"; done )===="
    echo -e ${RESTORE}
}

# FORMATS THE TIME
function format_time() {
    MINS=$(((${1}-${2})/60))
    SECS=$(((${1}-${2})%60))
    if [[ ${MINS} -ge 60 ]]; then
        HOURS=$((${MINS}/60))
        MINS=$((${MINS}%60))
    fi

    if [[ ${HOURS} -eq 1 ]]; then
        TIME_STRING+="1 HOUR, "
    elif [[ ${HOURS} -ge 2 ]]; then
        TIME_STRING+="${HOURS} HOURS, "
    fi

    if [[ ${MINS} -eq 1 ]]; then
        TIME_STRING+="1 MINUTE"
    else
        TIME_STRING+="${MINS} MINUTES"
    fi

    if [[ ${SECS} -eq 1 && -n ${HOURS} ]]; then
        TIME_STRING+=", AND 1 SECOND"
    elif [[ ${SECS} -eq 1 && -z ${HOURS} ]]; then
        TIME_STRING+=" AND 1 SECOND"
    elif [[ ${SECS} -ne 1 && -n ${HOURS} ]]; then
        TIME_STRING+=", AND ${SECS} SECONDS"
    elif [[ ${SECS} -ne 1 && -z ${HOURS} ]]; then
        TIME_STRING+=" AND ${SECS} SECONDS"
    fi

    echo ${TIME_STRING}
}

# PRINTS A HELP MENU
function help_menu() {
    echo -e "\n${BOLD}OVERVIEW:${RESTORE} Merges full Substratum support from LineageOMS organization into a LineageOS set of repos\n"
    echo -e "${BOLD}USAGE:${RESTORE} bash lineage_oms_merge.sh <source_dir>\n"
    echo -e "${BOLD}EXAMPLE:${RESTORE} bash lineage_oms_merge.sh ~/Android/Lineage\n"
    echo -e "${BOLD}Required options:${RESTORE}"
    echo -e "       source_dir: Location of the Lineage tree; this needs to exist for the script to properly proceed\n"
}

# CREATES A NEW LINE IN TERMINAL
function newLine() {
    echo -e ""
}

# PRINTS AN ERROR IN BOLD RED
function reportError() {
    RED="\033[01;31m"
    RESTORE="\033[0m"

    echo -e ""
    echo -e ${RED}"${1}"${RESTORE}
    if [[ -z ${2} ]]; then
        echo -e ""
    fi
}

# PRINTS AN WARNING IN BOLD YELLOW
function reportWarning() {
    YELLOW="\033[01;33m"
    RESTORE="\033[0m"

    echo -e ""
    echo -e ${YELLOW}"${1}"${RESTORE}
    if [[ -z ${2} ]]; then
        echo -e ""
    fi
}

###############
#             #
#  VARIABLES  #
#             #
###############

# HARD CODED FOR TESTING
ORG="Roach2010"
DEVBRANCH=LineageOMS

if [[ $# -eq 0 ]]; then
    reportError "Source directory not specified!" -c; help_menu && exit
fi

while [[ $# -ge 1 ]]; do
    case "${1}" in
        "-h"|"--help")
            help_menu && exit ;;
        *)
            SOURCE_DIR=${1}
            if [[ ! -d ${SOURCE_DIR} ]]; then
                reportError "Source directory not found!" && exit
            elif [[ ! -d ${SOURCE_DIR}/.repo ]]; then
                reportError "This is not a valid Android source folder as there is no .repo folder!" && exit
            fi ;;
    esac

    shift
done

# DO NOT EDIT THIS
SUBS_REPOS="
.repo/manifests
frameworks/base
frameworks/native
packages/apps/Contacts
packages/apps/ContactsCommon
packages/apps/Dialer
packages/apps/ExactCalculator
packages/apps/PackageInstaller
packages/apps/PhoneCommon
packages/apps/Settings
system/sepolicy
vendor/cm"

unset RESULT_STRING


################
#              #
# SCRIPT START #
#              #
################

# START TRACKING TIME
START=$( date +%s )

for FOLDER in ${SUBS_REPOS}; do
    # PRINT TO THE USER WHAT WE ARE DOING
    newLine; echoText "Unmerging ${FOLDER}"

    # SET PROPER URL
    if [[ ${FOLDER} == ".repo/manifests" ]]; then
        cd ${SOURCE_DIR}/${FOLDER}
        git reset --hard HEAD^
    else
        cd ${SOURCE_DIR}
	repo abandon ${DEVBRANCH} ${SOURCE_DIR}/${FOLDER}
    fi

    # ADD TO RESULT STRING
    if [[ $? -ne 0 ]]; then
        RESULT_STRING+="${FOLDER}: ${RED}FAILED${RESTORE}\n"
    else
        RESULT_STRING+="${FOLDER}: ${GREEN}SUCCESS${RESTORE}\n"
    fi
done

# SHIFT BACK TO THE TOP OF THE REPO
cd ${SOURCE_DIR}

# SYNC THEME INTERFACER REPO
newLine; echoText "Syncing packages/services/ThemeInterfacer"

# Make sure that the local manifest exists
if [[ ! -f .repo/local_manifests/substratum.xml ]]; then
    mkdir -p .repo/local_manifests
    curl --silent --output .repo/local_manifests/substratum.xml \
    https://raw.githubusercontent.com/${ORG}/merge_script/master/substratum.xml
fi

repo sync --force-sync packages/services/ThemeInterfacer

# PRINT RESULTS
echoText "RESULTS"
echo -e ${RESULT_STRING}

# STOP TRACKING TIME
END=$( date +%s )

# PRINT RESULT TO USER
echoText "SCRIPT COMPLETED!"
echo -e ${RED}"TIME: $(format_time ${END} ${START})"${RESTORE}; newLine
