const std = @import("std");

pub var io: std.Io = undefined;

pub fn init(init_io: std.Io) void {
    io = init_io;
}
