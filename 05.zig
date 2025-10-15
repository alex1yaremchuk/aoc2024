const std = @import("std");
const input = @import("input.zig");
const timed = @import("timed.zig");

const Rule = struct { a: u16, b: u16 };

const Seq = struct {
    values: []u16,
    pos: std.AutoHashMap(u16, u32),

    pub fn indexOf(seq: *const Seq, v: u16) ?u32 {
        return seq.pos.get(v);
    }
};

const Parsed = struct {
    rules: []Rule,
    seqs: []Seq,
};

const ParsedIndexed = struct {
    rules: []RuleIndexed,
    seqs: []SeqIndexed,
    index: std.AutoHashMap(u32, u16),
    rev: std.AutoHashMap(u16, u32),
};

const RuleIndexed = struct { a: u32, b: u32 };

const SeqIndexed = struct {
    values: []u32,
    pos: std.AutoHashMap(u32, u32),

    pub fn indexOf(seq: *const SeqIndexed, v: u32) ?u32 {
        return seq.pos.get(v);
    }
};

fn stripCR(data: []u8) []u8 {
    var w: usize = 0;
    for (data) |c| {
        if (c != '\r') {
            data[w] = c;
            w += 1;
        }
    }
    return data[0..w];
}

fn parseU16(s: []const u8) !u16 {
    return std.fmt.parseUnsigned(u16, s, 10);
}

fn part1(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const parsed = try parseRulesAndSeqs(arena, "05.txt");

    const rules = parsed.rules;
    const seqs = parsed.seqs;

    var result: usize = 0;

    for (seqs) |seq| {
        var ok = true;
        for (rules) |rule| {
            const ai = seq.indexOf(rule.a);
            const bi = seq.indexOf(rule.b);
            if (ai != null and bi != null and ai.? > bi.?) {
                ok = false;
                break;
            }
            // std.debug.print("a={} b={} ai={} bi={} ok={}\n", .{ rule.a, rule.b, ai orelse 0, bi orelse 0, ok });
        }
        result += if (ok) seq.values[seq.values.len / 2] else 0;
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

    const parsed = try parseRulesAndSeqsIndexed(arena, "05.txt");

    const rules = parsed.rules;
    const seqs = parsed.seqs;
    const index = parsed.index;

    var result: usize = 0;

    for (seqs) |seq| {
        var ok = true;
        for (rules) |rule| {
            const ai = seq.indexOf(rule.a);
            const bi = seq.indexOf(rule.b);
            if (ai != null and bi != null and ai.? > bi.?) {
                ok = false;
                break;
            }
            // std.debug.print("a={} b={} ai={} bi={} ok={}\n", .{ rule.a, rule.b, ai orelse 0, bi orelse 0, ok });
        }
        if (!ok) {
            const sorted = try topoSortSeq(arena, &seq, rules);

            const mid_id = sorted[sorted.len / 2];
            const mid_val = index.get(mid_id).?;

            //here we need to sort it out and find middle element
            result += mid_val;
        }
    }

    std.debug.print("result: {}\n", .{result});
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

fn parseRulesAndSeqs(arena: std.mem.Allocator, path: []const u8) !Parsed {
    const raw = try std.fs.cwd().readFileAlloc(path, arena, .unlimited);

    const data = stripCR(raw);

    var rules_list: std.ArrayListUnmanaged(Rule) = .{};
    defer rules_list.deinit(arena);

    var seqs_list: std.ArrayListUnmanaged(Seq) = .{};
    defer seqs_list.deinit(arena);

    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0) continue;

        if (std.mem.indexOfScalar(u8, line, '|')) |k| {
            const left = std.mem.trim(u8, line[0..k], " \t");
            const right = std.mem.trim(u8, line[k + 1 ..], " \t");
            const a = try parseU16(left);
            const b = try parseU16(right);
            try rules_list.append(arena, .{ .a = a, .b = b });
            continue;
        }

        if (std.mem.indexOfScalar(u8, line, ',')) |_| {
            var tmp: std.ArrayListUnmanaged(u16) = .{};
            defer tmp.deinit(arena);

            var it2 = std.mem.splitScalar(u8, line, ',');
            while (it2.next()) |tok_raw| {
                const tok = std.mem.trim(u8, tok_raw, " \t");
                if (tok.len == 0) continue;
                try tmp.append(arena, try parseU16(tok));
            }

            const vals = try arena.alloc(u16, tmp.items.len);
            std.mem.copyForwards(u16, vals, tmp.items);

            var map = std.AutoHashMap(u16, u32).init(arena);

            for (vals, 0..) |v, i| {
                try map.put(v, @intCast(i));
            }

            try seqs_list.append(arena, .{ .values = vals, .pos = map });
            continue;
        }
    }
    const rules = try rules_list.toOwnedSlice(arena);
    const seqs = try seqs_list.toOwnedSlice(arena);
    return Parsed{ .rules = rules, .seqs = seqs };
}

fn parseRulesAndSeqsIndexed(arena: std.mem.Allocator, path: []const u8) !ParsedIndexed {
    const raw = try std.fs.cwd().readFileAlloc(path, arena, .unlimited);

    const data = stripCR(raw);

    var idx = Indexer.init(arena);

    var rules_list: std.ArrayListUnmanaged(RuleIndexed) = .{};
    defer rules_list.deinit(arena);

    var seqs_list: std.ArrayListUnmanaged(SeqIndexed) = .{};
    defer seqs_list.deinit(arena);

    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0) continue;

        if (std.mem.indexOfScalar(u8, line, '|')) |k| {
            const left = std.mem.trim(u8, line[0..k], " \t");
            const right = std.mem.trim(u8, line[k + 1 ..], " \t");
            const a = try parseU16(left);
            const b = try parseU16(right);

            const a_id = try idx.ensureId(a);
            const b_id = try idx.ensureId(b);

            try rules_list.append(arena, .{ .a = a_id, .b = b_id });
            continue;
        }

        if (std.mem.indexOfScalar(u8, line, ',')) |_| {
            var tmp: std.ArrayListUnmanaged(u32) = .{};
            defer tmp.deinit(arena);

            var it2 = std.mem.splitScalar(u8, line, ',');
            while (it2.next()) |tok_raw| {
                const tok = std.mem.trim(u8, tok_raw, " \t");
                if (tok.len == 0) continue;
                const val = try parseU16(tok);
                const id = try idx.ensureId(val);
                try tmp.append(arena, id);
            }

            const vals = try arena.alloc(u32, tmp.items.len);
            std.mem.copyForwards(u32, vals, tmp.items);

            var map = std.AutoHashMap(u32, u32).init(arena);

            for (vals, 0..) |v, i| {
                try map.put(v, @intCast(i));
            }

            try seqs_list.append(arena, .{ .values = vals, .pos = map });
            continue;
        }
    }
    const rules = try rules_list.toOwnedSlice(arena);
    const seqs = try seqs_list.toOwnedSlice(arena);
    return ParsedIndexed{
        .rules = rules,
        .seqs = seqs,
        .index = idx.index,
        .rev = idx.rev,
    };
}

const Indexer = struct {
    index: std.AutoHashMap(u32, u16),
    rev: std.AutoHashMap(u16, u32),

    next_id: u32,

    pub fn init(alloc: std.mem.Allocator) Indexer {
        return .{
            .index = std.AutoHashMap(u32, u16).init(alloc),
            .rev = std.AutoHashMap(u16, u32).init(alloc),
            .next_id = 0,
        };
    }

    pub fn ensureId(indexer: *Indexer, v: u16) !u32 {
        if (indexer.rev.get(v)) |id| return id;
        const id = indexer.next_id;
        indexer.next_id += 1;
        try indexer.rev.put(v, id);
        try indexer.index.put(id, v);
        return id;
    }
};

fn topoSortSeq(
    arena: std.mem.Allocator,
    seq: *const SeqIndexed,
    rules: []const RuleIndexed,
) ![]u32 {
    var how_many_before = std.AutoHashMap(u32, u32).init(arena);
    defer how_many_before.deinit();

    var goes_after = std.AutoHashMap(u32, std.ArrayListUnmanaged(u32)).init(arena);

    for (seq.values) |id| {
        try how_many_before.put(id, 0);
        try goes_after.put(id, .{});
    }

    for (rules) |r| {
        const ai = seq.indexOf(r.a);
        if (ai == null) continue;
        const bi = seq.indexOf(r.b);
        if (bi == null) continue;

        const p = how_many_before.getPtr(r.b).?;
        p.* += 1;

        var lst = goes_after.getPtr(r.a).?;
        try lst.append(arena, r.b);
    }

    var q: ?u32 = null;

    for (seq.values) |id| {
        if (how_many_before.get(id).? == 0) {
            if (q != null) return error.AmbiguousOrder;
            q = id;
        }
    }
    if (q == null) return error.CycleInSubgraph;

    const out = try arena.alloc(u32, seq.values.len);
    var oi: usize = 0;

    var cur = q.?;
    while (true) {
        out[oi] = cur;
        oi += 1;

        var next_q: ?u32 = null;

        if (goes_after.get(cur)) |lst| {
            for (lst.items) |y| {
                const py = how_many_before.getPtr(y).?;
                if (py.* == 0) continue;
                py.* -= 1;

                if (py.* == 0) {
                    if (next_q != null) return error.AmbiguousOrder;
                    next_q = y;
                }
            }
        }

        if (oi == seq.values.len) break;

        if (next_q == null) return error.AmbiguousOrStuck;

        cur = next_q.?;
    }

    return out;
}
