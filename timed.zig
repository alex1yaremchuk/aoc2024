const std = @import("std");

pub fn timed(
    comptime label: []const u8,
    func: fn (std.mem.Allocator) anyerror!void,
    allocator: std.mem.Allocator,
) !void {
    const start = try std.time.Instant.now();
    defer {
        const dt = (std.time.Instant.now() catch unreachable).since(start);
        std.debug.print("[{s}] {d} ms\n", .{ label, dt / std.time.ns_per_ms });
    }
    try func(allocator);
}
