const std = @import("std");
const day = @import("16.zig");
const print = std.debug.print;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try day.solvepart1(allocator);
}
