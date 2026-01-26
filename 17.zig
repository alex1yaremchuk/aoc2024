const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = try inp.readFile(&arena, "17_.txt");
    const a_prefix = "Register A: ";
    const b_prefix = "Register B: ";
    const c_prefix = "Register C: ";
    const program_prefix = "Program: ";

    var a_reg: usize = undefined;
    var b_reg: usize = undefined;
    var c_reg: usize = undefined;
    var pc: usize = 0;
    var program: []const u8 = undefined;

    var output: [200]u8 = undefined;
    var output_len: usize = 0;

    var it = input.lines();
    while (it.next()) |line| {
        if (std.mem.startsWith(u8, line, a_prefix)) {
            a_reg = try std.fmt.parseInt(usize, line[a_prefix.len..], 10);
        } else if (std.mem.startsWith(u8, line, b_prefix)) {
            b_reg = try std.fmt.parseInt(usize, line[b_prefix.len..], 10);
        } else if (std.mem.startsWith(u8, line, c_prefix)) {
            c_reg = try std.fmt.parseInt(usize, line[c_prefix.len..], 10);
        } else if (std.mem.startsWith(u8, line, program_prefix)) {
            program = line[program_prefix.len..];
        }
    }

    print("a {d}\nb {d}\nc {d}\nprogram {s}\n", .{ a_reg, b_reg, c_reg, program });

    while (pc < program.len) {
        const command = program[pc];
        const next_ind = pc + 2;
        switch (command) {
            '0' => a_reg /= try std.math.powi(usize, 2, combo(program, next_ind, &a_reg, &b_reg, &c_reg)),
            '1' => b_reg ^= program[next_ind] - '0',
            '2' => b_reg = @mod(combo(program, next_ind, &a_reg, &b_reg, &c_reg), 8),
            '3' => {
                if (a_reg != 0) {
                    pc = 2 * (program[next_ind] - '0');
                    continue;
                }
            },
            '4' => b_reg ^= c_reg,
            '5' => {
                // print("output {s}  len {d}\n", .{ output, output_len });
                if (output_len > 0) {
                    output[output_len] = ',';
                    output_len += 1;
                }
                output[output_len] = '0' + @as(u8, @intCast(@mod(combo(program, next_ind, &a_reg, &b_reg, &c_reg), 8)));
                output_len += 1;
            },
            '6' => b_reg = a_reg / try std.math.powi(usize, 2, combo(program, next_ind, &a_reg, &b_reg, &c_reg)),
            '7' => c_reg = a_reg / try std.math.powi(usize, 2, combo(program, next_ind, &a_reg, &b_reg, &c_reg)),
            else => return error.UnknownCommand,
        }
        pc += 4;
    }

    print("a {d}\nb {d}\nc {d}\nprogram {s}\n", .{ a_reg, b_reg, c_reg, program });

    print("{s}\n", .{output[0..output_len]});
}

fn combo(
    program: []const u8,
    ind: usize,
    reg_a: usize,
    reg_b: usize,
    reg_c: usize,
) usize {
    return switch (program[ind]) {
        '0', '1', '2', '3' => |v| v - '0',
        '4' => reg_a,
        '5' => reg_b,
        '6' => reg_c,
        '7' => unreachable,
        else => unreachable,
    };
}

fn part2(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = try inp.readFile(&arena, "17.txt");
    const a_prefix = "Register A: ";
    const b_prefix = "Register B: ";
    const c_prefix = "Register C: ";
    const program_prefix = "Program: ";

    var a_reg: usize = undefined;
    var b_reg: usize = undefined;
    var c_reg: usize = undefined;
    var program: []const u8 = undefined;

    var it = input.lines();
    while (it.next()) |line| {
        if (std.mem.startsWith(u8, line, a_prefix)) {
            a_reg = try std.fmt.parseInt(usize, line[a_prefix.len..], 10);
        } else if (std.mem.startsWith(u8, line, b_prefix)) {
            b_reg = try std.fmt.parseInt(usize, line[b_prefix.len..], 10);
        } else if (std.mem.startsWith(u8, line, c_prefix)) {
            c_reg = try std.fmt.parseInt(usize, line[c_prefix.len..], 10);
        } else if (std.mem.startsWith(u8, line, program_prefix)) {
            program = line[program_prefix.len..];
        }
    }

    print("result: {d}", .{try search(program, 0, b_reg, c_reg, 0)});
}

fn search(
    program: []const u8,
    a_base: usize,
    b_reg: usize,
    c_reg: usize,
    depth: usize,
) anyerror!usize {
    for (a_base..a_base + 8) |candidate| {
        if (try execute(program, candidate, b_reg, c_reg, program[program.len - depth * 2 - 1])) {
            if (depth == 15) return candidate;
            return search(program, candidate << 3, b_reg, c_reg, depth + 1) catch |err| switch (err) {
                error.NotFound => continue,
                else => return err,
            };
        }
    }
    return error.NotFound;
}

fn execute(
    program: []const u8,
    a_reg_: usize,
    b_reg_: usize,
    c_reg_: usize,
    char: u8,
) !bool {
    var a_reg = a_reg_;
    var b_reg = b_reg_;
    var c_reg = c_reg_;
    var pc: usize = 0;
    while (pc < program.len) {
        const command = program[pc];
        const next_ind = pc + 2;
        switch (command) {
            '0' => a_reg /= try std.math.powi(usize, 2, combo(program, next_ind, a_reg, b_reg, c_reg)),
            '1' => b_reg ^= program[next_ind] - '0',
            '2' => b_reg = @mod(combo(program, next_ind, a_reg, b_reg, c_reg), 8),
            '3' => {
                if (a_reg != 0) {
                    pc = 2 * (program[next_ind] - '0');
                    continue;
                }
            },
            '4' => b_reg ^= c_reg,
            '5' => {
                return ('0' + @as(u8, @intCast(@mod(combo(program, next_ind, a_reg, b_reg, c_reg), 8)))) == char;
            },
            '6' => b_reg = a_reg / try std.math.powi(usize, 2, combo(program, next_ind, a_reg, b_reg, c_reg)),
            '7' => c_reg = a_reg / try std.math.powi(usize, 2, combo(program, next_ind, a_reg, b_reg, c_reg)),
            else => return error.UnknownCommand,
        }
        pc += 4;
    }
    return false;
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}
