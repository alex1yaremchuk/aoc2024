const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;

fn part1(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    _ = arena;

    const file = try std.fs.cwd().openFile("14.txt", .{});
    defer file.close();

    var resultA: usize = 0;
    var resultB: usize = 0;
    var resultC: usize = 0;
    var resultD: usize = 0;

    const width: isize = 101;
    const height: isize = 103;

    const widthHalf = width / 2;
    const heightHalf = height / 2;

    var buf: [256]u8 = undefined;
    var fr = file.reader(&buf);
    const r: *std.Io.Reader = &fr.interface;

    const timeFrame = 100;

    while (try readNumbers(r, "p=, v\r")) |robot| {
        const startX = robot[0];
        const startY = robot[1];
        const speedX = robot[2];
        const speedY = robot[3];

        const finishX = @mod(startX + speedX * timeFrame, width);
        const finishY = @mod(startY + speedY * timeFrame, height);

        if (finishX < widthHalf and finishY < heightHalf) resultA += 1;
        if (finishX < widthHalf and finishY > heightHalf) resultB += 1;
        if (finishX > widthHalf and finishY < heightHalf) resultC += 1;
        if (finishX > widthHalf and finishY > heightHalf) resultD += 1;
    }

    const result = resultA * resultB * resultC * resultD;

    print("result: {}\n", .{result});
}

fn part2(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    // _ = arena;

    const file = try std.fs.cwd().openFile("14.txt", .{});
    defer file.close();

    const width: isize = 101;
    const height: isize = 103;

    var buf: [256]u8 = undefined;
    var fr = file.reader(&buf);
    const r: *std.Io.Reader = &fr.interface;

    const robots = try loadRobots(arena, r, "p=, v\r");

    const out_file = try std.fs.cwd().createFile("14_frames.txt", .{ .truncate = true });
    defer out_file.close();

    var wbuf: [64 * 1024]u8 = undefined;
    var fw = out_file.writer(&wbuf);
    const writer: *std.Io.Writer = &fw.interface;

    const W: usize = @intCast(width);
    const H: usize = @intCast(height);

    const frame = try arena.alloc(u8, (W + 1) * H);
    defer arena.free(frame);

    const total_steps: usize = W * H;

    // const delay_ns = 30_000_000;

    var t: usize = 1;

    while (t < total_steps) : (t += 1) {
        stepRobots(robots, width, height);

        buildFrame(frame, width, height, robots);

        try writeT(writer, "t = {}\n", .{t});
        try writeAll(writer, frame);
        try writeAll(writer, "\n");

        // renderFrame(frame, W, H, robots);
        // std.Thread.sleep(delay_ns);
    }
}

fn writeAll(w: *std.Io.Writer, data: []const u8) !void {
    var off: usize = 0;
    while (off < data.len) {
        const n = try w.write(data[off..]);
        off += n;
    }
}

fn writeT(w: *std.Io.Writer, comptime fmt: []const u8, args: anytype) !void {
    var tmp: [64]u8 = undefined;
    const s = try std.fmt.bufPrint(&tmp, fmt, args);
    try writeAll(w, s);
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

//reader
fn readNumbers(reader: anytype, delim: []const u8) !?[4]isize {
    const line = try readNonEmptyLine(reader) orelse return null;
    var got: usize = 0;
    var out: [4]isize = undefined;

    var it = std.mem.tokenizeAny(u8, line, delim);
    while (it.next()) |tok| {
        const v = std.fmt.parseInt(i64, tok, 10) catch continue;
        if (got < 4) {
            out[got] = v;
            got += 1;
        }
    }

    if (got != 4) {
        print("{s} {any} {}\n", .{ line, out, got });
        return error.InvalidFormat;
    }

    return out;
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

const Robot = struct {
    startX: isize,
    startY: isize,
    speedX: isize,
    speedY: isize,
    currentX: isize,
    currentY: isize,
};

fn loadRobots(arena: std.mem.Allocator, reader: anytype, delim: []const u8) ![]Robot {
    var robots: std.ArrayListUnmanaged(Robot) = .{};

    while (try readNumbers(reader, delim)) |nums| {
        try robots.append(arena, Robot{
            .startX = nums[0],
            .startY = nums[1],
            .speedX = nums[2],
            .speedY = nums[3],
            .currentX = nums[0],
            .currentY = nums[1],
        });
    }
    return robots.toOwnedSlice(arena);
}

//reader

fn printRobotsCompact(alloc: std.mem.Allocator, robots: []Robot) !void {
    var minX: isize = std.math.maxInt(isize);
    var minY: isize = std.math.maxInt(isize);
    var maxX: isize = std.math.minInt(isize);
    var maxY: isize = std.math.minInt(isize);

    for (robots) |r| {
        if (r.currentX < minX) minX = r.currentX;
        if (r.currentX > maxX) maxX = r.currentX;
        if (r.currentY < minY) minY = r.currentY;
        if (r.currentY > maxY) maxY = r.currentY;
    }

    const cw: usize = @intCast(maxX - minX + 1);
    const ch: usize = @intCast(maxY - minY + 1);

    // const cwi: isize = @intCast(maxX - minX + 1);
    // const chi: isize = @intCast(maxY - minY + 1);

    var buf = try alloc.alloc(u8, (cw + 1) * ch);
    @memset(buf, '.');

    for (0..ch) |row| {
        buf[row * (cw + 1) + cw] = '\n';
    }

    for (robots) |r| {
        const x: usize = @intCast(r.currentX - minX);
        const y: usize = @intCast(r.currentY - minY);

        const idx = y * (cw + 1) + x;
        buf[idx] = '#';
    }

    print("{s}\n", .{buf});
}

fn applyAt(robots: []Robot, t: usize, width: isize, height: isize) void {
    const ti: isize = @intCast(t);

    for (robots) |*r| {
        r.currentX = @mod(r.startX + r.speedX * ti, width);
        r.currentY = @mod(r.startY + r.speedY * ti, height);
    }
}

fn stepRobots(robots: []Robot, width: isize, height: isize) void {
    for (robots) |*r| {
        r.currentX = @mod(r.currentX + r.speedX, width);
        r.currentY = @mod(r.currentY + r.speedY, height);
    }
}

fn buildFrame(buf: []u8, width: usize, height: usize, robots: []const Robot) void {
    @memset(buf, '.');

    var row: usize = 0;
    while (row < height) : (row += 1) {
        buf[row * (width + 1) + width] = '\n';
    }

    for (robots) |r| {
        const x: usize = @intCast(r.currentX);
        const y: usize = @intCast(r.currentY);
        buf[y * (width + 1) + x] = '#';
    }
}

fn renderFrame(buf: []u8, width: usize, height: usize, robots: []const Robot) void {
    buildFrame(buf, width, height, robots);
    print("{s}\n", .{buf});
}
