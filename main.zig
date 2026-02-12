const std = @import("std");
const day = @import("23.zig");
const print = std.debug.print;
const app_io = @import("app_io.zig");

pub fn main(init: std.process.Init) !void {
    app_io.init(init.io);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try day.solvepart2(allocator);
}
