#!/bin/zsh

if clang_output=$(clang --version 2>&1); then
    echo "Clang detected!"
    echo "$clang_output" | head -n 1
else

echo "Removing broken toolchain files"
sudo rm -rf /Library/Developer/CommandLineTools

echo "Starting Xcode Command Line Tools installer"
xcode-select --install

read "Press anykey here once the GUI installation finishes"

echo "Resetting CommandLine tool path"

sudo xcode-select --reset

echo "Checking version"
if clang --version >/dev/null 2>&1; then
        echo "Done! Clang is successfully installed:"
        clang --version | head -n 1
    else
        echo "Installation failed or was canceled."
    fi

fi
