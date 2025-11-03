#!/usr/bin/env bash
# File    : omodel.sh
# Purpose : Import and export the Modelfile with ease
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
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")  # the name of this script
OLLAMA='ollama'
HELP="
Usage: ./$SCRIPT_NAME <command>

Available commands:
  list            - List all Ollama models.
  export <model>  - Exporta el Modelfile del modelo suministrado
  import <model>  - Importa el archivo Modelfile modificandolo para el modelo suministrado
  help            - Display this help message.
"

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


ask_user() {
    local question="$1"
    local default="$2"

    read -p "${question} [$default]: " user_input

    if ! [[ "$user_input" ]]; then
        echo "$default"
    else
        echo "$user_input"
    fi
}

get_model_tag() {
    ask_user "Enter the model tag:" "7b-q4_K_M"
}

get_model_name() {
    ask_user "Enter the model name:" "Llama3"
}

get_absolute_path() {
    local relative_path="$1"
    echo $(realpath "$relative_path")
}

#================================ COMMANDS =================================#

# Lists all available models in Ollama
#
# Usage:
#   cmd_list [--help] [-n|--name] [-s|--size]
#
# Options:
#   --help: Show help message and exit.
#   -n, --name: Sort models by their names (alphabetical order).
#   -s, --size: Sort models by their size (largest to smallest).
#
# Example:
#   cmd_list
#   cmd_list -n
#   cmd_list -s
#
# Notes:
#   Requires the `ollama` command to be installed and in the PATH.
#   The `awk`, `sort`, and `cut` commands are used for sorting by size.
#
cmd_list() {
    local header list sorted_list sort_by

    # loop through all the command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help) help ; exit 0 ;;
            -n|--name) sort_by='name' ;;
            -s|--size) sort_by='size' ;;
            *) fatal_error "Unknown option: '$1'" ;;
        esac
        shift
    done

    # list all models usanig ollama
    list=$("$OLLAMA" list)

    # extract the header and list of models
    header=$(echo "$list" | head -n 1)
    list=$(echo "$list" | tail -n +2)

    if [[ $sort_by == 'size' ]]; then
        sorted_list=$(
            echo "$list" | awk '{ size = $3; unit = $4; if (unit == "GB") size *= 1024; print size, $0 }' | sort -rn | cut -d' ' -f2-;
        )
    elif [[ $sort_by == 'name' ]]; then
        sorted_list=$( echo "$list" | sort -k1,1  )
    else
        sorted_list=$list;
    fi

    # print the header and list of models
    echo "$header"
    echo "$sorted_list"
}


cmd_export() {
    local checkpoint=$1
    local modelfile="Modelfile"
    echo "Exporting Modelfile for '$checkpoint'"
    echo "Creating file $modelfile"
    "$OLLAMA" show --modelfile "$checkpoint" > "$modelfile"
}

cmd_import() {
    local checkpoint=$1
    local modelfile="Modelfile"
    
    # replace the line that starts with 'FROM'
    echo "Modificando archivo Modelfile apuntando a '$checkpoint'"

    modelfile=$(get_absolute_path "$modelfile")

    # if checkpoint is a URL (starts with 'hf.co/') then skip path resolution
    #if [[ $checkpoint != hf.co/* ]]; then
    #    checkpoint=$(get_absolute_path "$checkpoint")
    #fi
    sed -i "s#^FROM.*#FROM $checkpoint#" "$modelfile"

    MODEL_NAME=$(get_model_name)
    MODEL_TAG=$(get_model_tag)
    echo "OLLAMA_USER: $OLLAMA_USER"
    echo "MODEL_NAME : $MODEL_NAME"
    echo "MODEL_TAG  : $MODEL_TAG"
    echo "Modelfile  : $modelfile"
    echo "> ollama create -f '$modelfile' '$OLLAMA_USER/$MODEL_NAME:$MODEL_TAG'"
    "$OLLAMA" create -f "$modelfile" "$OLLAMA_USER/$MODEL_NAME:$MODEL_TAG"
}


# #===========================================================================#
# #////////////////////////////////// MAIN ///////////////////////////////////#
# #===========================================================================#
main() {
    local no_color=false   # no color mode flag
    local command=''       # default command to execute
    local arguments=()     # array to store the arguments for the command

    # check that the environment variable OLLAMA_USER is correctly defined
    if [[ -z "${OLLAMA_USER}" ]]; then
        echo "Error: OLLAMA_USER environment variable is not set."
        echo "This variable must be defined with your ollama.com username."
        echo "To set it, use the following command:"
        echo "  export OLLAMA_USER='your_ollama_username'"
        exit 1
    fi

    # loop through all the command line arguments
    while [[ $# -gt 0 ]]; do
        if [[ $1 == -* ]]; then
            case $1 in
                -n|--nc|--no-color) no_color=true ;;
                *)
                # add to the list of arguments for the command
                arguments+=("$1")
                ;; 
            esac
        else
            if [[ -z "$command" ]]; then command="$1"
            else
                # add to the list of arguments for the command
                arguments+=("$1") 
            fi
        fi
        shift # next argument
    done

    # disable color output if --no-color option is provided
    if [[ $no_color == true ]]; then disable_color; fi

    # if no command is specified, show the help message
    if [[ -z "$command" ]]; then help; exit 0; fi

    # execute the specified command
    case $command in
        list)   cmd_list   "${arguments[@]}"; exit 0 ;;
        export) cmd_export "${arguments[@]}"; exit 0 ;;
        import) cmd_import "${arguments[@]}"; exit 0 ;;
        help)   help ;;
        *)
        fatal_error "Invalid command: \"$command\"" "Use --help for usage."
        ;;
    esac

}
main "$@"
