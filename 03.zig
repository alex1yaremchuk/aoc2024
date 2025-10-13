const std = @import("std");
const input = @import("input.zig");
const timed = @import("timed.zig");

const State = enum {
    Start,
    Num1,
    Comma,
    Num2,
    Close,
};

fn part1(allocator: std.mem.Allocator) !void {
    const vals = try input.readChars(allocator, "03.txt");
    defer {
        allocator.free(vals);
    }

    const s = vals;
    var state = State.Start;
    var i: usize = 0;
    var result: u64 = 0;
    var num1: u64 = 0;
    var num2: u64 = 0;

    while (i < s.len) {
        switch (state) {
            .Start => {
                num1 = 0;
                num2 = 0;

                if (std.mem.startsWith(u8, s[i..], "mul(")) {
                    i += 4;
                    state = State.Num1;
                } else {
                    i += 1;
                }
            },
            .Num1 => {
                var countDigits: usize = 0;
                while (s[i] >= '0' and s[i] <= '9') {
                    countDigits += 1;
                    num1 = num1 * 10 + (s[i] - '0');
                    i += 1;
                }
                if (countDigits == 0) {
                    state = State.Start;
                } else {
                    state = State.Comma;
                }
            },
            .Comma => {
                if (s[i] == ',') {
                    i = i + 1;
                    state = State.Num2;
                } else {
                    state = State.Start;
                }
            },
            .Num2 => {
                var countDigits: usize = 0;
                while (s[i] >= '0' and s[i] <= '9') {
                    countDigits += 1;
                    num2 = num2 * 10 + (s[i] - '0');
                    i += 1;
                }
                if (countDigits == 0) {
                    state = State.Start;
                } else {
                    state = State.Close;
                }
            },
            .Close => {
                if (s[i] == ')') {
                    i = i + 1;
                    std.debug.print("{} * {} \n", .{ num1, num2 });
                    result += num1 * num2;
                }
                state = State.Start;
            },
        }
    }

    std.debug.print("{}\n", .{result});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

fn part2(allocator: std.mem.Allocator) !void {
    const vals = try input.readChars(allocator, "03.txt");
    defer {
        allocator.free(vals);
    }

    const s = vals;
    var state = State.Start;
    var i: usize = 0;
    var result: u64 = 0;
    var num1: u64 = 0;
    var num2: u64 = 0;
    var do: bool = true;

    while (i < s.len) {
        switch (state) {
            .Start => {
                num1 = 0;
                num2 = 0;

                if (do and std.mem.startsWith(u8, s[i..], "mul(")) {
                    i += 4;
                    state = State.Num1;
                } else if (std.mem.startsWith(u8, s[i..], "do()")) {
                    i += 4;
                    do = true;
                } else if (std.mem.startsWith(u8, s[i..], "don't()")) {
                    i += 7;
                    do = false;
                } else {
                    i += 1;
                }
            },
            .Num1 => {
                var countDigits: usize = 0;
                while (s[i] >= '0' and s[i] <= '9') {
                    countDigits += 1;
                    num1 = num1 * 10 + (s[i] - '0');
                    i += 1;
                }
                if (countDigits == 0) {
                    state = State.Start;
                } else {
                    state = State.Comma;
                }
            },
            .Comma => {
                if (s[i] == ',') {
                    i = i + 1;
                    state = State.Num2;
                } else {
                    state = State.Start;
                }
            },
            .Num2 => {
                var countDigits: usize = 0;
                while (s[i] >= '0' and s[i] <= '9') {
                    countDigits += 1;
                    num2 = num2 * 10 + (s[i] - '0');
                    i += 1;
                }
                if (countDigits == 0) {
                    state = State.Start;
                } else {
                    state = State.Close;
                }
            },
            .Close => {
                if (s[i] == ')') {
                    i = i + 1;
                    std.debug.print("{} * {} \n", .{ num1, num2 });
                    result += num1 * num2;
                }
                state = State.Start;
            },
        }
    }

    std.debug.print("{}\n", .{result});
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

fn checkSlice(row: []i8, exclude: ?usize) bool {
    var ok = true;
    var order: i8 = 0;
    for (row, 0..) |_, i| {
        if (i == exclude or ((i + 1) == exclude and exclude == (row.len - 1))) continue;
        const next = if (i + 1 == exclude) i + 2 else i + 1;
        if (order == 0) {
            order = if (row[i] > row[next]) -1 else 1;
        }
        if (i == (row.len - 1)) break;
        const diff = if (row[i] > row[next]) row[i] - row[next] else row[next] - row[i];

        if (diff < 1 or diff > 3 or (row[next] - row[i]) * order <= 0) {
            std.debug.print("wrong pair: {} {}\n", .{ row[i], row[next] });
            ok = false;
            if (exclude == null) {
                if (i > 0) {
                    ok = checkSlice(row, i - 1);
                }
                ok = ok or checkSlice(row, i);
                ok = ok or checkSlice(row, i + 1);
            }
            break;
        }
    }
    return ok;
}
