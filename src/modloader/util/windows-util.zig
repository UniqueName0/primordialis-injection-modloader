// some windows specific stuff will be moved here later
const std = @import("std");
const win = std.os.windows;

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
