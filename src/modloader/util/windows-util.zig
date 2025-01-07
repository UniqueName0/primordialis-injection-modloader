// some windows specific stuff will be moved here later
const std = @import("std");
const win = std.os.windows;

extern "kernel32" fn CreateMutexA(lpMutexAttributes: ?*win.SECURITY_ATTRIBUTES, bInitialOwner: win.BOOL, lpname: ?win.LPCSTR) callconv(win.WINAPI) win.HANDLE;
extern "kernel32" fn ReleaseMutex(hMutex: win.HANDLE) callconv(win.WINAPI) win.BOOL;

pub fn get_base_addr() usize {
    const addr = win.kernel32.GetModuleHandleW(null).?;
    std.log.info("base addr: {p}", .{addr});
    return @intFromPtr(addr);
}

var oldProtect: win.DWORD = undefined;
pub fn mem_protect_rw(addr: usize) void {
    win.VirtualProtect(@ptrFromInt(addr), 16, win.PAGE_EXECUTE_READWRITE, &oldProtect) catch |err| {
        std.log.err("virtual protect error: {}", .{err});
        return;
    };
}

pub fn mem_protect_restore(addr: usize) void {
    win.VirtualProtect(@ptrFromInt(addr), 16, oldProtect, &oldProtect) catch |err| {
        std.log.err("virtual protect error: {}", .{err});
        return;
    };
}

pub const Lock = struct {
    mutexHandle: win.HANDLE = undefined,

    pub fn init() Lock {
        var out = Lock{};
        out.mutexHandle = CreateMutexA(null, win.FALSE, null);
        return out;
    }

    pub fn lock(self: *Lock) void {
        win.WaitForSingleObject(self.mutexHandle, win.INFINITE) catch |err| {
            std.log.err("error waiting for mutex: {}", .{err});
            return;
        };
    }

    pub fn unlock(self: *Lock) void {
        const sucess = ReleaseMutex(self.mutexHandle);
        if (sucess == win.FALSE) {
            std.log.err("failed to release mutex", .{});
        }
    }
};
