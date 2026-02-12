const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");

const SBS = std.StaticBitSet(max_nodes);

const ArrayList = std.ArrayList;

const Hash = std.AutoHashMap;

const max_nodes = 26 * 26;

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const input = try inp.readFile(&arena, "23.txt");

    var lines_it = input.lines();

    var is_t = try ArrayList(bool).initCapacity(alloc, 10000);
    var adj: [max_nodes]std.StaticBitSet(max_nodes) = [_]std.StaticBitSet(max_nodes){std.StaticBitSet(max_nodes).initEmpty()} ** max_nodes;
    var name_to_id = Hash(u16, u16).init(alloc);
    var id_to_name = try ArrayList(u16).initCapacity(alloc, max_nodes);

    var countTriangles: usize = 0;

    while (lines_it.next()) |line| {
        const id1 = try addNode(line[0..2], &is_t, &name_to_id, &id_to_name, alloc);
        const id2 = try addNode(line[3..5], &is_t, &name_to_id, &id_to_name, alloc);

        adj[id1].set(id2);
        adj[id2].set(id1);
    }

    const n_nodes: usize = is_t.items.len;
    for (0..n_nodes) |id1| {
        for (id1 + 1..n_nodes) |id2| {
            if (!adj[id1].isSet(id2)) continue;
            var common = adj[id1].intersectWith(adj[id2]);

            while (common.toggleFirstSet()) |id3| {
                if (id3 <= id2) continue;
                if (is_t.items[id1] or is_t.items[id2] or is_t.items[id3]) countTriangles += 1;
            }
        }
    }

    print("there are {d} triangles", .{countTriangles});
}

fn addNode(name: []const u8, is_t: *ArrayList(bool), name_to_id: *Hash(u16, u16), id_to_name: *ArrayList(u16), alloc: std.mem.Allocator) !usize {
    const num_code = (@as(u16, name[0]) << 8) | @as(u16, name[1]);

    if (name_to_id.get(num_code)) |known_id| return known_id;

    const new_id: u16 = @as(u16, @intCast(is_t.items.len));

    const has_t = name[0] == 't';
    const gop = try name_to_id.getOrPut(num_code);
    if (!gop.found_existing) gop.value_ptr.* = new_id;
    try id_to_name.append(alloc, num_code);
    try is_t.append(alloc, has_t);
    return new_id;
}

fn part2(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const input = try inp.readFile(&arena, "23.txt");

    var lines_it = input.lines();

    var is_t = try ArrayList(bool).initCapacity(alloc, 10000);
    var adj: [max_nodes]std.StaticBitSet(max_nodes) =
        [_]std.StaticBitSet(max_nodes){std.StaticBitSet(max_nodes).initEmpty()} ** max_nodes;
    var name_to_id = Hash(u16, u16).init(alloc);
    var id_to_name = try ArrayList(u16).initCapacity(alloc, max_nodes);

    while (lines_it.next()) |line| {
        const id1 = try addNode(line[0..2], &is_t, &name_to_id, &id_to_name, alloc);
        const id2 = try addNode(line[3..5], &is_t, &name_to_id, &id_to_name, alloc);

        adj[id1].set(id2);
        adj[id2].set(id1);
    }

    var best = SBS.initEmpty();
    var all_nodes = SBS.initEmpty();
    for (0..is_t.items.len) |ind| all_nodes.set(ind);

    findLargest(&adj, SBS.initEmpty(), all_nodes, SBS.initEmpty(), &best);

    var password: [max_nodes]u16 = undefined;
    var it = best.iterator(.{});
    var count: usize = 0;
    while (it.next()) |ind| {
        password[count] = id_to_name.items[ind];
        count += 1;
    }

    std.sort.pdq(u16, password[0..count], {}, std.sort.asc(u16));

    for (password[0..count], 0..) |node, i| {
        if (i != 0) print(",", .{});
        const first: u8 = @intCast(node >> 8);
        const second: u8 = @intCast(node % 256);
        print("{c}{c}", .{ first, second });
    }
    print("\n", .{});
}

fn findLargest(adj: []SBS, R1: SBS, P1: SBS, Q1: SBS, best: *SBS) void {
    var P = P1;
    var Q = Q1;
    var R = R1;
    if (P.count() == 0 and Q.count() == 0 and R.count() > best.count()) best.* = R;
    if (P.count() == 0) return;

    var pivot: u16 = undefined;
    var pivot_count: usize = 0;

    var U: SBS = P;
    U.setUnion(Q);

    var it = U.iterator(.{});

    while (it.next()) |u| {
        var A = adj[u];
        const count = A.intersectWith(P).count();
        if (count >= pivot_count) {
            pivot = @intCast(u);
            pivot_count = count;
        }
    }

    var candidates = P;
    var it_cand = candidates.differenceWith(adj[pivot]).iterator(.{});

    while (it_cand.next()) |v| {
        var R_new = R;
        R_new.set(v);

        const A = adj[v];

        var P_new = P;
        var Q_new = Q;

        findLargest(adj, R_new, P_new.intersectWith(A), Q_new.intersectWith(A), best);

        P.unset(v);
        Q.set(v);
    }
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}
