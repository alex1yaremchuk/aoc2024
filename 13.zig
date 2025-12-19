const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;

fn part1(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    _ = arena;

    const file = try std.fs.cwd().openFile("13.txt", .{});
    defer file.close();

    var result: usize = 0;

    var buf: [256]u8 = undefined;
    var fr = file.reader(&buf);
    const r: *std.Io.Reader = &fr.interface;

    while (try readMachine(r, false)) |machine| {
        result += solveMachine(machine);
    }

    print("result: {}\n", .{result});
}

fn solveMachine(machine: Machine) usize {
    const ax = machine.a_step[0];
    const ay = machine.a_step[1];
    const bx = machine.b_step[0];
    const by = machine.b_step[1];
    const tx = machine.prize[0];
    const ty = machine.prize[1];

    const dAB = det(ax, ay, bx, by);
    const dTB = det(tx, ty, bx, by);
    const dAT = det(ax, ay, tx, ty);

    if (dAB != 0) { // single solution, check if it is natural
        const a_ = @divTrunc(dTB, dAB);
        const b_ = @divTrunc(dAT, dAB);

        if (@rem(dTB, dAB) == 0 and @rem(dAT, dAB) == 0) {
            const a_usize: usize = @intCast(a_);
            const b_usize: usize = @intCast(b_);
            // опционально: защита от переполнения суммы
            return a_usize * 3 + b_usize;
        }
        return 0;
    }
    if (dAB == 0 and dTB != 0) return 0;

    // a is better than b
    if (ax > 3 * bx) {
        var a = tx / ax;
        while (true) {
            if ((tx - ax * a) % bx == 0) return a * 3 + (tx - ax * a) / bx;
            a -= 1;
        }
    } else {
        var b = tx / bx;
        while (true) {
            if ((tx - bx * b) % ax == 0) return 3 * (tx - bx * b) / ax + b;
            b -= 1;
        }
    }
}

fn det(ax: usize, ay: usize, bx: usize, by: usize) i128 {
    const axi: i128 = @intCast(ax);
    const bxi: i128 = @intCast(bx);
    const byi: i128 = @intCast(by);
    const ayi: i128 = @intCast(ay);
    return axi * byi - ayi * bxi;
}

fn part2(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    _ = arena;

    const file = try std.fs.cwd().openFile("13.txt", .{});
    defer file.close();

    var result: usize = 0;

    var buf: [256]u8 = undefined;
    var fr = file.reader(&buf);
    const r: *std.Io.Reader = &fr.interface;

    while (try readMachine(r, true)) |machine| {
        result += solveMachine(machine);
    }

    print("result: {}\n", .{result});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

//reader
const Machine = struct {
    a_step: [2]usize,
    b_step: [2]usize,

    prize: [2]usize,
};

fn readMachine(reader: anytype, p2: bool) !?Machine {
    const a_line = try readNonEmptyLine(reader) orelse return null;
    const a = try parseCoords(a_line);
    const b_line = try readLineRequired(reader);
    const b = try parseCoords(b_line);
    const p_line = try readLineRequired(reader);
    const p = try parseCoords(p_line);

    const off: u64 = if (p2) @as(u64, 10_000_000_000_000) else 0;

    return Machine{
        .a_step = .{ @intCast(a[0]), @intCast(a[1]) },
        .b_step = .{ @intCast(b[0]), @intCast(b[1]) },
        .prize = .{
            @intCast(p[0] + off),
            @intCast(p[1] + off),
        },
    };
}

fn readLine(r: *std.Io.Reader) !?[]const u8 {
    return r.takeDelimiterExclusive('\n') catch |err| switch (err) {
        error.EndOfStream => return null, // EOF без новой строки
        error.StreamTooLong => return err, // строка длиннее внутреннего буфера
        else => return err,
    };
}

fn readNonEmptyLine(r: *std.Io.Reader) !?[]const u8 {
    while (true) {
        const line = try readLine(r) orelse return null;
        const trimmed = std.mem.trim(u8, line, " \r\t");
        if (trimmed.len == 0) continue;
        return trimmed;
    }
}

fn readLineRequired(r: *std.Io.Reader) ![]const u8 {
    const line = try readLine(r) orelse return error.UnexpectedEof;
    const trimmed = std.mem.trim(u8, line, " \r\t");
    if (trimmed.len == 0) return error.UnexpectedEmptyLine;
    return trimmed;
}

fn parseCoords(line: []const u8) ![2]u64 {
    var it = std.mem.tokenizeAny(u8, line, " \t,:+=XY");
    var out: [2]u64 = .{ 0, 0 };
    var got: usize = 0;

    while (it.next()) |tok| {
        const v = std.fmt.parseInt(u64, tok, 10) catch continue;
        if (got < 2) {
            out[got] = v;
            got += 1;
        } else break;
    }
    if (got != 2) {
        print("{s}\n", .{line});
        return error.InvalidFormat;
    }
    return out;
}

//reader
