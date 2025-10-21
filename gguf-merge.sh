#!/usr/bin/env bash
# File    : gguf-merge.sh
# Purpose : Merge two GGUF files into one.
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Oct 20, 2025
# Repo    : https://github.com/martin-rizzo/OllamaMiniTools
# License : MIT
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#                               OllamaMiniTools
#           Simple scripts to streamline ollama models setup process
#
#     Copyright (c) 2025 Martin Rizzo
#
#     Permission is hereby granted, free of charge, to any person obtaining
#     a copy of this software and associated documentation files (the
#     "Software"), to deal in the Software without restriction, including
#     without limitation the rights to use, copy, modify, merge, publish,
#     distribute, sublicense, and/or sell copies of the Software, and to
#     permit persons to whom the Software is furnished to do so, subject to
#     the following conditions:
#
#     The above copyright notice and this permission notice shall be
#     included in all copies or substantial portions of the Software.
#
#     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#     EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#     TORT OR OTHERWISE, ARISING FROM,OUT OF OR IN CONNECTION WITH THE
#     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
SCRIPT_FULL_PATH="$(readlink -f "$0")"
SCRIPT_NAME=$(basename "${SCRIPT_FULL_PATH}" .sh)         # script name without extension
SCRIPT_DIR=$(realpath "$(dirname "${SCRIPT_FULL_PATH}")") # script directory
HELP="
Usage: ./$SCRIPT_NAME.sh [OPTIONS] <GGUF_FILE1> <GGUF_FILE2>

  Allows you to merge two GGUF files into one.

  Available options:
    -n, --no-color         Disable color output.
    -h, --help             Show this help message and exit.

  Examples:
    ./$SCRIPT_NAME.sh model1.gguf model2.gguf 
"

# if the environment variable LLAMA_BIN_DIR is not defined,
# then assign it the value SCRIPT_DIR/bin
[[ -z "${LLAMA_BIN_DIR}" ]] && LLAMA_BIN_DIR="$SCRIPT_DIR"/bin



# ANSI escape codes for colored terminal output
RED='\e[91m'; YELLOW='\e[93m'; GREEN='\e[92m'; CYAN='\e[96m'; RESET='\e[0m'
disable_color() { RED=''; YELLOW=''; GREEN=''; CYAN=''; RESET=''; }

#============================= ERROR MESSAGES ==============================#

# Display help message
help() { echo "${HELP}"; }

# Display a warning message
warning() { echo -e "\n${CYAN}[${YELLOW}WARNING${CYAN}]${RESET} $1" >&2; }

# Display an error message
error() { echo -e "\n${CYAN}[${RED}ERROR${CYAN}]${RESET} $1" >&2; }

# Displays a fatal error message and exits the script
fatal_error() {
    error "$1"; shift
    while [[ $# -gt 0 ]]; do
        echo -e " ${CYAN}\xF0\x9F\x9B\x88 $1${RESET}" >&2
        shift
    done
    echo; exit 1
}

# #===========================================================================#
# #////////////////////////////////// MAIN ///////////////////////////////////#
# #===========================================================================#
main() {
    local no_color=false   # no color mode flag
    local help=false       # help mode flag
    local gguf_file1=''    # first GGUF file to merge
    local gguf_file2=''    # second GGUF file to merge

    while [[ $# -gt 0 ]]; do
        if [[ $1 == -* ]]; then
            case $1 in
                -n|--nc|--no-color) no_color=true           ;;
                -h|--help)          help=true               ;;
                *)
                    fatal_error "Invalid option: \"$1\"" "Use --help for usage." ;;
            esac
        else
            # cargar gguf file1 y gguf_file2 (el que esté vacio)
            if   [[ -z "${gguf_file1}" ]]; then gguf_file1="$1"
            elif [[ -z "${gguf_file2}" ]]; then gguf_file2="$1"
            else fatal_error "Invalid argument: \"$1\"" "Use --help for usage."
            fi
        fi
        shift
    done

    # disable color output if --no-color option is provided
    if [[ $no_color == true ]]; then disable_color; fi

    # display help message and exit if --help option is provided
    if [[ $help == true ]]; then help; exit 0; fi

    # both GGUF files must be provided
    [[ -n "${gguf_file1}" && -n "${gguf_file2}" ]] ||
        fatal_error "Missing required gguf file(s)."

    # both GGUF must exist as files
    [[ -f "${gguf_file1}" ]] || 
        fatal_error "GGUF file \"${gguf_file1}\" does not exist."
    [[ -f "${gguf_file2}" ]] ||
        fatal_error "GGUF file \"${gguf_file2}\" does not exist."


    # insert the llama directory that contains the ".so" files into the LD_LIBRARY_PATH
    #export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${LLAMA_BIN_DIR}"

    # merge the two GGUF files into 'merged-model.gguf'
    echo ">llama-gguf-split --merge '${gguf_file1}' '${gguf_file2}' merged-model.gguf"
    "$LLAMA_BIN_DIR"/llama-gguf-split --merge "${gguf_file1}" "${gguf_file2}" merged-model.gguf

}
main "$@"
