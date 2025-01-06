const std = @import("std");
const win = std.os.windows;

// some constants that aren't in std.os.windows
const CREATE_SUSPENDED = 0x00000004;
const PROCESS_ALL_ACCESS = 0x000F0000 | 0x00100000 | 0xFFFF;
extern "kernel32" fn OpenProcess(dwDesiredAccess: win.DWORD, bInheritHandle: win.BOOL, dwProcessId: win.DWORD) callconv(win.WINAPI) ?win.HANDLE;
extern "kernel32" fn VirtualAllocEx(hProcess: ?win.HANDLE, lpAddress: ?win.LPVOID, dwSize: win.SIZE_T, flAllocationType: win.DWORD, flProtect: win.DWORD) callconv(win.WINAPI) win.LPVOID;
extern "kernel32" fn WriteProcessMemory(hProcess: ?win.HANDLE, lpBaseAddress: win.LPVOID, lpBuffer: win.LPCVOID, nSize: win.SIZE_T, lpNumberOfBytesWritten: ?*win.SIZE_T) callconv(win.WINAPI) win.BOOL;
extern "kernel32" fn CreateRemoteThread(hProcess: ?win.HANDLE, lpThreadAttributes: ?*win.SECURITY_ATTRIBUTES, dwStackSize: win.SIZE_T, lpStartAddress: ?win.LPTHREAD_START_ROUTINE, lpParameter: ?win.LPVOID, dwCreationFlags: win.DWORD, lpThreadId: ?*win.DWORD) callconv(win.WINAPI) win.HANDLE;
extern "kernel32" fn ResumeThread(hThread: ?win.HANDLE) callconv(win.WINAPI) win.DWORD;

var StartupInfo: win.STARTUPINFOW = undefined;
var ProcessInfo: win.PROCESS_INFORMATION = undefined;
var bytesWritten: win.SIZE_T = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // game exe path
    const gameExePath = std.unicode.utf8ToUtf16LeStringLiteral(".\\primordialis.exe");
    std.log.info("[*] Target Process: {s}", .{try std.unicode.utf16LeToUtf8Alloc(allocator, gameExePath)});

    // start game in suspended state
    if (win.kernel32.CreateProcessW(null, @constCast(gameExePath), null, null, win.FALSE, CREATE_SUSPENDED, null, null, &StartupInfo, &ProcessInfo) == win.FALSE) {
        std.debug.print("CreateProcessW fail: {}", .{win.GetLastError()});
    }
    std.log.info("[*] pHandle: {}", .{ProcessInfo.dwProcessId});

    // gets the newly created game process
    const ph = OpenProcess(PROCESS_ALL_ACCESS, win.FALSE, ProcessInfo.dwProcessId);
    defer win.CloseHandle(ph.?);

    // writes inject.dll into game memory
    const modloaderPath = std.unicode.utf8ToUtf16LeStringLiteral(".\\modloader\\zig-out\\bin\\modloader.dll");
    const modloaderPathLen: win.SIZE_T = modloaderPath.len * 2 + 1;
    const rb = VirtualAllocEx(ph, null, modloaderPathLen, (win.MEM_RESERVE | win.MEM_COMMIT), win.PAGE_EXECUTE_READWRITE);
    if (WriteProcessMemory(ph, rb, modloaderPath, modloaderPathLen, &bytesWritten) == win.FALSE) {
        std.debug.print("WriteProcessMemory fail: {}", .{win.GetLastError()});
    }
    std.log.info("[*] bytes written: {}", .{bytesWritten});

    // handle to kernel32 and pass it to GetProcAddress
    const hKernel32 = win.kernel32.GetModuleHandleW(std.unicode.utf8ToUtf16LeStringLiteral("Kernel32"));
    const lb = win.kernel32.GetProcAddress(hKernel32.?, "LoadLibraryW");
    if (lb == null) {
        std.debug.print("GetProcAddress fail: {}", .{win.GetLastError()});
    }
    // start modloader in a new thread
    const rt = CreateRemoteThread(ph, null, 0, @ptrCast(lb), rb, 0, null);

    // waits until modloader thread is complete
    try win.WaitForSingleObject(rt, win.INFINITE);

    // resumes game thread
    _ = ResumeThread(ProcessInfo.hThread);
}
