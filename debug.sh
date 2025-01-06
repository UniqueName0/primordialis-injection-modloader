#!/bin/bash

# this script must be ran from the same folder as primordialis.exe
# change this to the path to injector.exe
wine ./modloader/zig-out/bin/injector.exe
# gdb must be used for this to work, normal winedbg doesn't work unless you manually do it for some reason
winedbg --gdb --no-start "0x$(winedbg --command "info proc" | grep primordialis.exe | tr -s ' ' | cut -d ' ' -f 2 | sed 's/^0*//')"
# this will give you the gdb command to attach to the game with the modloader running
# you just paste the "target remote ....." into gdb
# this also works with ghidra, in the debugger create a new debugging target with gdb, then paste the command in the interpreter and it'll connect
