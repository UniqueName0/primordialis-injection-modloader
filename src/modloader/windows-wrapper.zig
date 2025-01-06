// I'll put this file into a seperate folder if I figure out how, zig is a little weird with imports
const std = @import("std");
const win = std.os.windows;
const modloader = @import("main.zig");

const DLL_PROCESS_ATTACH: win.DWORD = 1;
const DLL_THREAD_ATTACH: win.DWORD = 2;
const DLL_THREAD_DETACH: win.DWORD = 3;
const DLL_PROCESS_DETACH: win.DWORD = 0;

extern "kernel32" fn AllocConsole() callconv(win.WINAPI) void;
extern "kernel32" fn AttachConsole(dwProcessId: win.DWORD) callconv(win.WINAPI) win.BOOL;
const ATTACH_PARENT_PROCESS = 0xFFFFFFFF;
extern "user32" fn MessageBoxA(hWnd: ?win.HWND, lpText: win.LPCSTR, lpCaption: win.LPCSTR, uType: win.UINT) callconv(win.WINAPI) i32;

pub export fn DllMain(hinstDLL: win.HINSTANCE, fdwReason: win.DWORD, lpReserved: win.LPVOID) win.BOOL {
    _ = lpReserved;
    _ = hinstDLL;
    switch (fdwReason) {
        DLL_PROCESS_ATTACH => {
            AllocConsole();
            //_ = AttachConsole(ATTACH_PARENT_PROCESS); // need to test it but this is maybe better on windows then AllocConsole

            modloader.entry();
        },
        DLL_THREAD_ATTACH => {},
        DLL_THREAD_DETACH => {},
        DLL_PROCESS_DETACH => {
            modloader.exit();
        },
        else => {},
    }
    return 1;
}
