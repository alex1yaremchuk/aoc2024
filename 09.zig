const std = @import("std");
const timed = @import("timed.zig");
const input = @import("input.zig");
const app_io = @import("app_io.zig");

fn part1(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const digits = try readDigits(arena, "09.txt");

    var end = digits.len - 1;
    var end_cap = digits[end];

    var result: u128 = 0;

    var count: u64 = 0;

    main_loop: for (digits, 0..) |dig, ind| {
        //std.debug.print("==== ind {} ==== end {} \n", .{ ind, end });
        if (ind > end) break;
        if (ind % 2 == 0) {
            // std.debug.print("counting\n", .{});
            var cap = dig;
            if (ind == end) cap = end_cap;

            while (cap > 0) : (count += 1) {
                cap -= 1;
                result += count * (ind / 2);
            }
        } else {
            // std.debug.print("moving\n", .{});
            var cap = dig;

            while (cap > 0) {
                if (end_cap == 0) {
                    end -= 2;
                    end_cap = digits[end];
                    if (end < ind) break :main_loop;
                }
                // std.debug.print(
                //     "count {} ind {} end {} cap {} end_cap {}\n",
                //     .{ count, ind, end, cap, end_cap },
                // );
                result += count * (end / 2);

                end_cap -= 1;
                cap -= 1;
                count += 1;
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

    const digits = try readDigits(arena, "09.txt");

    const list = try parseToList(arena, digits);

    const first: *Span = &list[0];

    //  по порядку id файлов с конца

    // для каждого файла
    //  а) найти свободное место - (можно идти от начала списка)
    //  б) убрать файл со старого места в списке -
    //      соединить prev и next
    //  в) поставить файл на свободное место
    //     prev свободного места соединить с файлом
    //     соединить файл с оставшимся свободным местом (или нулем)

    var i: usize = list.len - 1;

    std.debug.print("len {} \n", .{list.len});

    main_while: while (i > 0) : (i -= 1) {
        if (list[i].id < 0) continue;

        // printList(&list[0]);

        var file = &list[i];

        var current: *Span = first;
        const free: *Span = while (current.next != null) : (current = current.next.?) {
            if (current.id == file.id) continue :main_while;
            if (current.id < 0 and current.len >= file.len) break current;
        } else continue :main_while;

        // std.debug.print(" free {} file {}\n", .{ free.*.len, file.*.len });

        file.*.prev.?.*.len += file.*.len;

        // std.debug.print(" free {} file {}\n", .{ free.*.len, file.*.len });

        file.*.prev.?.*.next = file.*.next;

        if (file.*.next != null) file.*.next.?.*.prev = file.*.prev;

        free.*.len -= file.*.len;

        file.*.prev = free.*.prev;
        free.*.prev.?.*.next = file;

        file.*.next = free;
        free.*.prev = file;
    }

    // printList(&list[0]);

    var result: u128 = 0;
    var counter: usize = 0;

    var current = first;
    while (current.next != null) : (current = current.next.?) {
        if (current.id > 0) {
            const c: u128 = @intCast(current.len);
            const counter_u128: u128 = @intCast(counter);
            const id_u128: u128 = @intCast(current.id);
            const res_for_file = id_u128 * (counter_u128 * c + @divExact((c - 1) * c, 2));

            result += res_for_file;
        }
        counter += current.len;
    }

    std.debug.print("result: {}\n", .{result});
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

pub fn readDigits(
    allocator: std.mem.Allocator,
    path: []const u8,
) ![]u8 {
    const data = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, allocator, .unlimited);
    errdefer allocator.free(data);

    const nums: []u8 = try allocator.alloc(u8, data.len);
    // std.debug.print("=================", .{});

    for (data, 0..) |ch, i| {
        // std.debug.print("[ {} {} ] ", .{ ch, '0' });
        nums[i] = ch - '0';
    }

    return nums;
}

fn parseToList(
    arena: std.mem.Allocator,
    digits: []u8,
) ![]Span {
    var list = try arena.alloc(Span, digits.len);

    for (digits, 0..) |d, ind| {
        const id: i32 = @intCast(ind / 2);
        const is_file = (ind % 2) == 0;
        list[ind] = Span{
            .id = if (is_file) id else -1,
            .len = d,
            .prev = if (ind > 0) &list[ind - 1] else null,
            .next = if (ind < (digits.len - 1)) &list[ind + 1] else null,
        };
    }

    return list;
}

fn printList(list_start: *Span) void {
    var current = list_start.*;
    while (true) : (current = current.next.?.*) {
        var c: usize = 0;
        std.debug.print("[", .{});

        while (c < current.len) : (c += 1) {
            if (current.id >= 0) {
                std.debug.print("{d}", .{current.id});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("]", .{});

        if (current.next == null) break;
    }
    std.debug.print("\n", .{});
}

const Span = struct {
    id: i32,
    len: usize,

    prev: ?*Span,
    next: ?*Span,
};
