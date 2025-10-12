const std = @import("std");

pub fn timed(
    comptime label: []const u8,
    func: fn (std.mem.Allocator) anyerror!void,
    allocator: std.mem.Allocator,
) !void {
    const start = std.time.nanoTimestamp();
    defer {
        const dt = std.time.nanoTimestamp() - start;
        std.debug.print("[{s}] {d} ms\n", .{ label, @divTrunc(dt, 1_000_000) });
    }
    try func(allocator);
}
