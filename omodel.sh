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
CMD=$1
MODEL=$2
OLLAMA='ollama'

HELP=$(cat <<EOF
Usage: $0 <command>

Available commands:
  list            - List all Ollama models.
  export <model>  - Exporta el Modelfile del modelo suministrado
  import <model>  - Importa el archivo Modelfile modificandolo para el modelo suministrado
  help            - Display this help message.
.
EOF
)

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

cmd_list() {
    "$OLLAMA" list
}

cmd_export() {
    local modelfile=$1 checkpoint=$2
    echo "Exporting Modelfile for '$checkpoint'"
    echo "Creating file $outfile"
    "$OLLAMA" show --modelfile "$checkpoint" > "$modelfile"
}

cmd_import() {
    local modelfile="$1" checkpoint="$2"
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


CMD="${CMD:---help}"
case "$CMD" in
    list)
        cmd_list
        exit 0
        ;;
    export)
        cmd_export "Modelfile" "$MODEL"
        exit 0
        ;;
    help|-h|--help)
        echo "$HELP"
        exit 0
esac

if [[ -z "${OLLAMA_USER}" ]]; then
    echo "Error: OLLAMA_USER environment variable is not set."
    echo "This variable must be defined with your ollama.com username."
    echo "To set it, use the following command:"
    echo "  export OLLAMA_USER='your_ollama_username'"
    exit 1
fi

# process the provided command
case "$CMD" in
    import)
        cmd_import "Modelfile" "$MODEL"
        ;;
    *)
        echo "Error: Unknown command '$CMD'."
        exit 1
        ;;
esac

