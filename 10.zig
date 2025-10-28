const std = @import("std");
const timed = @import("timed.zig");
const input = @import("input.zig");
const Grid = input.Grid;
const Dirs = input.Dirs;
const print = std.debug.print;

fn part1(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const grid: Grid = try input.readDigits2D(arena, "10.txt");

    var paths: []u64 = try arena.alloc(u64, grid.nums.len);

    var result: usize = 0;
    for (grid.nums, 0..) |n, outer_ind| {
        if (n != 0) continue;
        @memset(paths, 0);
        paths[outer_ind] = 1;

        for (0..9) |digit| {
            for (paths, 0..) |p, ind| {
                if (grid.nums[ind] == digit) {
                    const coords = try grid.coords(ind);
                    var it = grid.neighbors(coords[0], coords[1]);
                    while (it.next()) |next| {
                        if (grid.nums[next] == (digit + 1) and p == 1) {
                            paths[next] = 1;
                        }
                    }
                }
            }
        }
        for (paths, 0..) |p, ind| {
            if (grid.nums[ind] == 9) {
                result += p;
            }
        }
    }

    std.debug.print("result: {}\n", .{result});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

fn part2(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const grid: Grid = try input.readDigits2D(arena, "10.txt");

    var paths: []u64 = try arena.alloc(u64, grid.nums.len);
    @memset(paths, 0);

    for (paths, 0..) |_, ind| {
        if (grid.nums[ind] == 0) paths[ind] = 1;
    }

    for (0..9) |digit| {
        for (paths, 0..) |p, ind| {
            // std.debug.print("grid {} digit {} p {} ind {} {any}\n", .{ grid.nums[ind], digit, p, ind, paths });
            if (grid.nums[ind] == digit) {
                const coords = try grid.coords(ind);
                // print("coords {} {} \n", .{ coords[0], coords[1] });
                var it = grid.neighbors(coords[0], coords[1]);
                while (it.next()) |next| {
                    // print("next {} grid.nums[next] {} \n", .{ next, grid.nums[next] });
                    if (grid.nums[next] == (digit + 1)) {
                        paths[next] += p;
                    }
                }
            }
        }
    }

    var result: usize = 0;
    for (paths, 0..) |p, ind| {
        if (grid.nums[ind] == 9) {
            // print("found 8!\n", .{});
            result += p;
        }
    }

    std.debug.print("result: {}\n", .{result});
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}
