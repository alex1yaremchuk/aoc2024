const std = @import("std");
const day = @import("14.zig");
const print = std.debug.print;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try day.solvepart2(allocator);

    print("usize bits: {d}\n", .{@bitSizeOf(usize)});
    print("usize max:  {}\n", .{std.math.maxInt(usize)});
}
