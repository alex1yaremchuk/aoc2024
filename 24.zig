const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");

const Wire = u32;
const Val = u1;

const Op = enum { and_, or_, xor_ };

const Gate = struct {
    a: Wire,
    b: Wire,
    out: Wire,
    op: Op,
};

const Circuit = struct {
    initial: std.AutoHashMap(Wire, Val),
    gates: std.ArrayList(Gate),

    fn init(alloc: std.mem.Allocator) Circuit {
        return .{
            .initial = std.AutoHashMap(Wire, Val).init(alloc),
            .gates = .empty,
        };
    }

    fn deinit(self: *Circuit, alloc: std.mem.Allocator) void {
        self.initial.deinit();
        self.gates.deinit(alloc);
    }
};

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const input = try inp.readFile(&arena, "24.txt");
    var c = try parseCircuit(alloc, input);
    defer c.deinit(alloc);

    var values = try evalCircuit(alloc, &c);
    defer values.deinit();

    const result = try readZNumber(&values);
    print("result is: {d}\n", .{result});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

inline fn packName(name: []const u8) Wire {
    std.debug.assert(name.len == 3);
    return @as(Wire, name[0]) |
        (@as(Wire, name[1]) << 8) |
        (@as(Wire, name[2]) << 16);
}

inline fn unpackName(id: Wire) [3]u8 {
    return .{
        @as(u8, @intCast(id & 0xFF)),
        @as(u8, @intCast((id >> 8) & 0xFF)),
        @as(u8, @intCast((id >> 16) & 0xFF)),
    };
}

fn parseInitLine(line: []const u8) !struct { w: Wire, v: Val } {
    // "x00: 1
    if (line.len < 6) return error.BadInitLine;
    const w = packName(line[0..3]);
    const ch = line[line.len - 1];
    const v: Val = switch (ch) {
        '1' => 1,
        '0' => 0,
        else => return error.BadBit,
    };
    return .{ .w = w, .v = v };
}

fn parseGateLine(line: []const u8) !Gate {
    // "a AND b -> c"
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    const a_s = it.next() orelse return error.BadGateLine;
    const op_s = it.next() orelse return error.BadGateLine;
    const b_s = it.next() orelse return error.BadGateLine;
    const arrow = it.next() orelse return error.BadGateLine;
    const out_s = it.next() orelse return error.BadGateLine;
    if (it.next() != null) return error.BadGateLine;
    if (!std.mem.eql(u8, arrow, "->")) return error.BadGateLine;

    const op: Op =
        if (std.mem.eql(u8, op_s, "AND")) .and_ else if (std.mem.eql(u8, op_s, "OR")) .or_ else if (std.mem.eql(u8, op_s, "XOR")) .xor_ else return error.BadOp;

    return .{
        .a = packName(a_s),
        .b = packName(b_s),
        .out = packName(out_s),
        .op = op,
    };
}

fn parseCircuit(alloc: std.mem.Allocator, input: inp.Input) !Circuit {
    var c = Circuit.init(alloc);
    errdefer c.deinit(alloc);

    var groups = input.groups();

    const init_group = groups.next() orelse return error.MissingInit;
    const gates_group = groups.next() orelse return error.MissingGates;

    if (groups.next() != null) return error.TooManyGroups;

    var init_lines = inp.groupLines(init_group);
    while (init_lines.next()) |line| {
        const iv = try parseInitLine(line);
        try c.initial.put(iv.w, iv.v);
    }

    var gate_lines = inp.groupLines(gates_group);
    while (gate_lines.next()) |line| {
        try c.gates.append(alloc, try parseGateLine(line));
    }

    return c;
}

inline fn evalOp(op: Op, a: Val, b: Val) Val {
    return switch (op) {
        .and_ => a & b,
        .or_ => a | b,
        .xor_ => a ^ b,
    };
}

fn appendConsumer(
    alloc: std.mem.Allocator,
    consumers: *std.AutoHashMap(Wire, std.ArrayListUnmanaged(u32)),
    w: Wire,
    gate_idx: u32,
) !void {
    var gop = try consumers.getOrPut(w);
    if (!gop.found_existing) gop.value_ptr.* = .{};
    try gop.value_ptr.append(alloc, gate_idx);
}

fn evalCircuit(
    alloc: std.mem.Allocator,
    c: *const Circuit,
) !std.AutoHashMap(Wire, Val) {
    var values = std.AutoHashMap(Wire, Val).init(alloc);
    errdefer values.deinit();

    var consumers = std.AutoHashMap(Wire, std.ArrayListUnmanaged(u32)).init(alloc);
    defer {
        var itc = consumers.iterator();
        while (itc.next()) |e| e.value_ptr.deinit(alloc);
        consumers.deinit();
    }

    const pending = try alloc.alloc(u8, c.gates.items.len);
    defer alloc.free(pending);
    @memset(pending, 2);

    for (c.gates.items, 0..) |g, i| {
        const gi: u32 = @intCast(i);
        try appendConsumer(alloc, &consumers, g.a, gi);
        try appendConsumer(alloc, &consumers, g.b, gi);
    }

    var queue: std.ArrayList(Wire) = .empty;
    defer queue.deinit(alloc);
    var head: usize = 0;

    var it0 = c.initial.iterator();
    while (it0.next()) |e| {
        const gop = try values.getOrPut(e.key_ptr.*);
        if (!gop.found_existing) {
            gop.value_ptr.* = e.value_ptr.*;
            try queue.append(alloc, e.key_ptr.*);
        }
    }

    while (head < queue.items.len) : (head += 1) {
        const w = queue.items[head];

        const lst_ptr = consumers.getPtr(w) orelse continue;
        for (lst_ptr.items) |gi| {
            if (pending[gi] == 0) continue;
            pending[gi] -= 1;
            if (pending[gi] != 0) continue;

            const g = c.gates.items[gi];
            const va = values.get(g.a) orelse return error.MissingInput;
            const vb = values.get(g.b) orelse return error.MissingInput;
            const outv = evalOp(g.op, va, vb);

            const out_gop = try values.getOrPut(g.out);
            if (!out_gop.found_existing) {
                out_gop.value_ptr.* = outv;
                try queue.append(alloc, g.out);
            } else if (out_gop.value_ptr.* != outv) {
                return error.ConflictingDriver;
            }
        }
    }

    return values;
}

inline fn zIndex(w: Wire) ?u8 {
    const n = unpackName(w);
    if (n[0] != 'z') return null;
    if (n[1] < '0' or n[1] > '9') return null;
    if (n[2] < '0' or n[2] > '9') return null;
    return (n[1] - '0') * 10 + (n[2] - '0');
}

fn readZNumber(values: *const std.AutoHashMap(Wire, Val)) !u64 {
    var result: u64 = 0;
    var it = values.iterator();
    while (it.next()) |e| {
        const zi = zIndex(e.key_ptr.*) orelse continue;
        if (zi >= 64) return error.zTooWide;
        if (e.value_ptr.* == 1) {
            result |= (@as(u64, 1) << @as(u6, @intCast(zi)));
        }
    }
    return result;
}

inline fn startsWith(w: Wire, c: u8) bool {
    const n = unpackName(w);
    return n[0] == c;
}

inline fn isXYWire(w: Wire) bool {
    const n = unpackName(w);
    return n[0] == 'x' or n[0] == 'y';
}

inline fn isXYPair(a: Wire, b: Wire) bool {
    return (startsWith(a, 'x') and startsWith(b, 'y')) or
        (startsWith(a, 'y') and startsWith(b, 'x'));
}

fn hasConsumerWithOp(
    c: *const Circuit,
    consumers: *const std.AutoHashMap(Wire, std.ArrayListUnmanaged(u32)),
    w: Wire,
    op: Op,
) bool {
    const lst = consumers.get(w) orelse return false;
    for (lst.items) |gi| {
        if (c.gates.items[gi].op == op) return true;
    }
    return false;
}

fn lessWire(_: void, a: Wire, b: Wire) bool {
    const an = unpackName(a);
    const bn = unpackName(b);
    return std.mem.order(u8, an[0..], bn[0..]) == .lt;
}

fn printWire(w: Wire) void {
    const n = unpackName(w);
    print("{c}{c}{c}", .{ n[0], n[1], n[2] });
}

fn part2(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const input = try inp.readFile(&arena, "24.txt");
    var c = try parseCircuit(alloc, input);
    defer c.deinit(alloc);

    var consumers = std.AutoHashMap(Wire, std.ArrayListUnmanaged(u32)).init(alloc);
    defer {
        var itc = consumers.iterator();
        while (itc.next()) |e| e.value_ptr.deinit(alloc);
        consumers.deinit();
    }

    for (c.gates.items, 0..) |g, i| {
        const gi: u32 = @intCast(i);
        try appendConsumer(alloc, &consumers, g.a, gi);
        try appendConsumer(alloc, &consumers, g.b, gi);
    }

    var max_z: u8 = 0;
    for (c.gates.items) |g| {
        const zi = zIndex(g.out) orelse continue;
        if (zi > max_z) max_z = zi;
    }

    const x00 = packName("x00");
    const y00 = packName("y00");

    var bad_map = std.AutoHashMap(Wire, u8).init(alloc);
    defer bad_map.deinit();

    for (c.gates.items) |g| {
        if (zIndex(g.out)) |zi| {
            if (zi != max_z and g.op != .xor_) {
                try bad_map.put(g.out, 1);
            }
        } else if (g.op == .xor_ and !(isXYWire(g.a) and isXYWire(g.b))) {
            try bad_map.put(g.out, 1);
        }

        if (g.op == .and_ and !(g.a == x00 and g.b == y00) and !(g.a == y00 and g.b == x00)) {
            if (!hasConsumerWithOp(&c, &consumers, g.out, .or_)) {
                try bad_map.put(g.out, 1);
            }
        }

        if (g.op == .xor_ and isXYPair(g.a, g.b) and !(g.a == x00 and g.b == y00) and !(g.a == y00 and g.b == x00)) {
            if (!hasConsumerWithOp(&c, &consumers, g.out, .xor_)) {
                try bad_map.put(g.out, 1);
            }
        }
    }

    var bad = std.ArrayList(Wire).empty;
    defer bad.deinit(alloc);

    var it = bad_map.iterator();
    while (it.next()) |e| {
        try bad.append(alloc, e.key_ptr.*);
    }

    std.sort.pdq(Wire, bad.items, {}, lessWire);

    for (bad.items, 0..) |w, i| {
        if (i != 0) print(",", .{});
        printWire(w);
    }
    print("\n", .{});
}
