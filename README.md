<div align="center">

# 🧰 OllamaMiniTools

</div>

**OllamaMiniTools** is a humble collection of simple scripts designed to streamline the setup process for Ollama models. This project is primarily for personal use, and while it has been tested in my own use cases, it may not function as expected in other contexts.


## Included Scripts

Currently, OllamaMiniTools includes two basic scripts, each with limitations in this initial state:

1. **gguf-merge**: This script is designed to merge two GGUF files into one by utilizing the `gguf-split` tool from llama.cpp. However, it has a significant limitation: the `gguf-split` tool from llama.cpp was specifically created for "shredded" models (those divided into multiple files) and does not support merging arbitrary GGUF files. This greatly restricts the script's utility in scenarios where non-shredded files need to be combined.

2. **omodel**: This tool provides commands for listing Ollama models, exporting model files, and importing and modifying them. While it meets core requirements, it currently lacks user-friendly features:
   - The parameters and usage can be confusing without clear documentation.
   - There is no embedded guidance or help within the script to facilitate user interaction.
   - Users may need trial-and-error to understand full capabilities.

The repository is an active work in progress. Please use the scripts at your own risk, as they are not yet fully polished for all use cases.


## License

Copyright (c) 2025 Martin Rizzo  
This project is licensed under the MIT license.  
See the ["LICENSE"](LICENSE) file for details.
