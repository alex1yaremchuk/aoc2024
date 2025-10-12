const std = @import("std");
const input = @import("input.zig");
const day1 = @import("1.zig");
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try day1.solveDay1part2(allocator);
}
