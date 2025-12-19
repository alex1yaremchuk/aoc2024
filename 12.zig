const std = @import("std");
const timed = @import("timed.zig");
const input = @import("input.zig");
const Grid = input.Grid;
const print = std.debug.print;

fn part1(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const plants = try input.read2D(arena, "12.txt", false);

    const labeled = try label_all(arena, plants);
    const regions = labeled.regions;

    var result: u32 = 0;

    print("regions: {}\n", .{regions.len});

    for (regions) |region| {
        print("region {c} area {} perimeter {}\n", .{ region.ch, region.area, region.perimeter });
        result += region.area * region.perimeter;
    }

    print("result: {}\n", .{result});
}

const Region = struct {
    ch: u8,
    area: u32,
    perimeter: u32,
    sides: u32,
};

const UNASSIGNED: u32 = std.math.maxInt(u32);

fn label_all(
    arena: std.mem.Allocator,
    plants: Grid,
) !struct { labels: []u32, regions: []Region } {
    var labels = try arena.alloc(u32, plants.vals.len);
    @memset(labels, UNASSIGNED);

    var regions_list: std.ArrayListUnmanaged(Region) = .{};

    var q: std.ArrayListUnmanaged(usize) = .{};
    defer q.deinit(arena);

    var region_id: u32 = 0;

    for (plants.vals, 0..) |plant, region_start_ind| {
        if (labels[region_start_ind] != UNASSIGNED) continue;

        try regions_list.append(arena, Region{ .ch = plant, .area = 0, .perimeter = 0, .sides = 0 });

        try q.append(arena, region_start_ind);
        labels[region_start_ind] = region_id;

        while (q.items.len > 0) {
            const processing_ind = q.items[q.items.len - 1];
            q.items.len -= 1;

            var our_neighbours: usize = 0;

            var it = plants.neighbors_ind(processing_ind);

            while (it.next()) |neighbour| {
                // print("neighbour {} {c} to {} {c} \n", .{ neighbour, plants.vals[neighbour], processing_ind, plants.vals[processing_ind] });
                if (plants.vals[neighbour] == plants.vals[processing_ind]) {
                    if (labels[neighbour] == UNASSIGNED) {
                        try q.append(arena, neighbour);
                        labels[neighbour] = region_id;
                    }
                    our_neighbours += 1;
                }
            }

            regions_list.items[region_id].area += 1;
            regions_list.items[region_id].perimeter += @intCast(4 - our_neighbours);
        }

        region_id += 1;
    }
    return .{ .labels = labels, .regions = try regions_list.toOwnedSlice(arena) };
}

const Entry = struct {
    region_id: u32,
    count: u3,
    mask: u4,
};

const WindowCounts = struct {
    entries: [4]Entry,
    len: u3,
};

fn count2x2(region_ids: [4]u32) WindowCounts {
    var out = WindowCounts{
        .entries = [_]Entry{.{
            .region_id = UNASSIGNED,
            .count = 0,
            .mask = 0,
        }} ** 4,
        .len = 0,
    };

    for (region_ids, 0..) |region_id, pos| {
        if (region_id == UNASSIGNED) continue;
        var found = false;

        var i: usize = 0;

        while (i < out.len) : (i += 1) {
            if (out.entries[i].region_id == region_id) {
                out.entries[i].count += 1;
                out.entries[i].mask |= @as(u4, 1) << @intCast(pos);
                found = true;
                break;
            }
        }
        if (!found) {
            out.entries[out.len] = .{
                .region_id = region_id,
                .count = 1,
                .mask = @as(u4, 1) << @intCast(pos),
            };
            out.len += 1;
        }
    }
    return out;
}

fn count_sides(regions: []Region, labels: []u32, grid: Grid) !void {
    for (0..grid.cols + 1) |col_raw| {
        for (0..grid.rows + 1) |row_raw| {
            const col: i32 = @as(i32, @intCast(col_raw)) - 1;
            const row: i32 = @as(i32, @intCast(row_raw)) - 1;
            const ids = [4]u32{
                getRegionId(row, col, labels, grid),
                getRegionId(row + 1, col, labels, grid),
                getRegionId(row, col + 1, labels, grid),
                getRegionId(row + 1, col + 1, labels, grid),
            };
            const counts = count2x2(ids);

            // print("counting them {any} \ncounts {any}\n", .{ ids, counts });

            for (0..counts.len) |idx| {
                const count = counts.entries[idx].count;
                const region_id = counts.entries[idx].region_id;
                const mask = counts.entries[idx].mask;
                // print("region {} with count {} \n", .{ region_id, count });
                if (region_id != UNASSIGNED and
                    (count == 1 or count == 3))
                {
                    regions[region_id].sides += 1;
                    // print("region {} with new sides {} \n", .{ region_id, regions[region_id].sides });
                }
                if (region_id != UNASSIGNED and
                    (mask == 9 or mask == 6))
                {
                    regions[region_id].sides += 2;
                    // print("region {} with new sides {} \n", .{ region_id, regions[region_id].sides });
                }
            }
        }
    }
}

fn getRegionId(row: i32, col: i32, labels: []u32, grid: Grid) u32 {
    if (row < 0 or row >= grid.rows or col < 0 or col >= grid.cols) {
        return UNASSIGNED;
    } else {
        return labels[grid.idx(@intCast(row), @intCast(col))];
    }
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

fn part2(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const plants = try input.read2D(arena, "12.txt", false);

    const labeled = try label_all(arena, plants);
    const regions = labeled.regions;
    const labels = labeled.labels;

    try count_sides(regions, labels, plants);

    var result: u32 = 0;

    for (regions) |region| {
        print("region {c} with area {} and sides {} equals {} \n", .{
            region.ch,
            region.area,
            region.sides,
            region.area * region.sides,
        });
        result += region.area * region.sides;
    }

    print("result: {}\n", .{result});
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}
