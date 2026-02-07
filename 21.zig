const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");

const depth_level = 3;
const UNK: u32 = std.math.maxInt(u32);

const KeypadType = enum {
    Numeric,
    Arrows,
};

const Solver = struct {
    memo_num: [depth_level + 1][11][11]u32,
    memo_dir: [depth_level + 1][5][5]u32,

    fn init() Solver {
        var s: Solver = undefined;

        @memset(std.mem.asBytes(&s.memo_num), 0xFF);
        @memset(std.mem.asBytes(&s.memo_dir), 0xFF);

        return s;
    }

    fn costNum(self: *Solver, depth: usize, from_id: u8, to_id: u8) !u32 {
        if (self.memo_num[depth][from_id][to_id] != UNK) return self.memo_num[depth][from_id][to_id];
        if (depth == 0) return error.CannotTypeDirectlyOnNumeric;

        var min_cost: u32 = std.math.maxInt(u32);

        const from_key = numeric_kp.keyFromId(from_id);
        const to_key = numeric_kp.keyFromId(to_id);
        var it = try ShortestPathsIter.init(numeric_kp, from_key, to_key);
        var prev_id: u8 = dir_kp.id('A') orelse return error.BadKey;
        var path_sum: u32 = 0;
        var buf: [10_000]u8 = undefined;
        while (it.next(&buf)) |path| {
            path_sum = 0;
            prev_id = dir_kp.id('A') orelse return error.BadKey;
            for (path) |next| {
                const next_id = dir_kp.id(next) orelse return error.BadKey;
                path_sum += try self.costDir(depth - 1, prev_id, next_id);
                prev_id = next_id;
            }
            if (path_sum < min_cost) min_cost = path_sum;
        }
        self.memo_num[depth][from_id][to_id] = min_cost;
        return min_cost;
    }

    fn costDir(self: *Solver, depth: usize, from_id: u8, to_id: u8) !u32 {
        if (self.memo_dir[depth][from_id][to_id] != UNK) return self.memo_dir[depth][from_id][to_id];
        if (depth == 0) return 1;

        var min_cost: u32 = std.math.maxInt(u32);

        const from_key = dir_kp.keyFromId(from_id);
        const to_key = dir_kp.keyFromId(to_id);
        var it = try ShortestPathsIter.init(dir_kp, from_key, to_key);
        var prev_id: u8 = dir_kp.id('A') orelse return error.BadKey;
        var path_sum: u32 = 0;
        var buf: [10_000]u8 = undefined;
        while (it.next(&buf)) |path| {
            path_sum = 0;
            prev_id = dir_kp.id('A') orelse return error.BadKey;
            for (path) |next| {
                const next_id = dir_kp.id(next) orelse return error.BadKey;
                path_sum += try self.costDir(depth - 1, prev_id, next_id);
                prev_id = next_id;
            }
            if (path_sum < min_cost) min_cost = path_sum;
        }
        self.memo_dir[depth][from_id][to_id] = min_cost;
        return min_cost;
    }
};

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = try inp.readFile(&arena, "21_.txt");

    var lines_it = input.lines();

    var prev_id: u8 = numeric_kp.id('A') orelse return error.BadKey;

    var solver = Solver.init();

    var result: usize = 0;

    while (lines_it.next()) |line| {
        var price: usize = 0;

        const val = try std.fmt.parseInt(usize, line[0 .. line.len - 1], 10);

        for (line) |ch| {
            const to_id = numeric_kp.id(ch) orelse return error.BadKey;
            price += try solver.costNum(depth_level, prev_id, to_id);
            prev_id = to_id;
        }
        print("val {d} price {d}\n", .{ val, price });

        result += val * price;
    }

    print("result is: {d}", .{result});
}

fn part2(_: std.mem.Allocator) !void {}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

const numeric_grid = [_][]const u8{
    "789",
    "456",
    "123",
    "\x00" ++ "0A", // дырка + 0A
};

const dir_grid = [_][]const u8{
    "\x00^A",
    "<v>",
};

const numeric_kp = Keypad.init(3, 4, numeric_grid[0..]);
const dir_kp = Keypad.init(3, 2, dir_grid[0..]);

const Coord = struct { x: i8, y: i8 };

const Move = struct { dx: i8, dy: i8, ch: u8 };

const MOVES = [_]Move{
    .{ .dx = 0, .dy = -1, .ch = '^' },
    .{ .dx = 0, .dy = 1, .ch = 'v' },
    .{ .dx = -1, .dy = 0, .ch = '<' },
    .{ .dx = 1, .dy = 0, .ch = '>' },
};

const UNREACH: u8 = 0xFF;

/// Маленькая решётка: numeric 3x4, dir 3x2.
/// Храним как grid[y][x] = символ кнопки или 0 для "дыры".
pub const Keypad = struct {
    w: i8,
    h: i8,
    grid: []const []const u8,
    index: [256]u8,
    coords: [11]Coord,
    count: u8,

    pub fn init(w: i8, h: i8, grid: []const []const u8) Keypad {
        var kp: Keypad = .{
            .w = w,
            .h = h,
            .grid = grid,
            .index = undefined,
            .coords = undefined,
            .count = 0,
        };
        kp.buildIndex();
        return kp;
    }

    pub fn find(self: Keypad, key: u8) ?Coord {
        const key_id = self.id(key) orelse return null;
        return self.coords[key_id];
    }

    pub inline fn id(self: *const Keypad, key: u8) ?u8 {
        const v = self.index[key];
        return if (v == UNREACH) null else v;
    }

    pub inline fn coord(self: *const Keypad, key_id: u8) Coord {
        return self.coords[key_id];
    }

    pub inline fn keyFromId(self: *const Keypad, key_id: u8) u8 {
        const c = self.coords[key_id];
        return self.grid[@intCast(c.y)][@intCast(c.x)];
    }

    fn inBounds(self: Keypad, c: Coord) bool {
        return c.x >= 0 and c.y >= 0 and c.x < self.w and c.y < self.h;
    }

    fn isOpen(self: Keypad, c: Coord) bool {
        if (!self.inBounds(c)) return false;
        return self.grid[@intCast(c.y)][@intCast(c.x)] != 0;
    }

    fn buildIndex(self: *Keypad) void {
        @memset(&self.index, UNREACH);
        var k: u8 = 0;
        var y: i8 = 0;
        while (y < self.h) : (y += 1) {
            var x: i8 = 0;
            while (x < self.w) : (x += 1) {
                const ch = self.grid[@intCast(y)][@intCast(x)];
                if (ch == 0) continue;
                if (k >= self.coords.len) @panic("Keypad too large");
                self.index[ch] = k;
                self.coords[k] = .{ .x = x, .y = y };
                k += 1;
            }
        }
        self.count = k;
    }
};

fn bfsDist(kp: Keypad, start: Coord, dist: [][][]u8) void {
    // dist is dist[H][W][1] ??? нет. Мы сделаем по-другому ниже.
    _ = kp;
    _ = start;
    _ = dist;
}

/// Итератор всех кратчайших путей from_key -> to_key.
/// next(buf) -> ?[]const u8  (пишет в buf и возвращает buf[0..len])
pub const ShortestPathsIter = struct {
    kp: Keypad,
    start: Coord,
    target: Coord,

    // dist[y][x] (макс 5x5, нам достаточно)
    dist: [5][5]u8 = undefined,

    // длина кратчайшего пути
    L: u8 = 0,

    stack: [32]Frame = undefined,
    depth: u8 = 0, // текущая глубина (кол-во сделанных шагов)
    started: bool = false,
    finished: bool = false,
    at_solution: bool = false, // если прошлый next() вернул решение и мы стоим на target

    // DFS стек: на каждом уровне храним текущую координату и индекс следующего move для перебора
    const Frame = struct {
        c: Coord,
        next_move: u8, // 0..4
    };

    pub fn init(kp: Keypad, from_key: u8, to_key: u8) !ShortestPathsIter {
        const s = kp.find(from_key) orelse return error.BadKey;
        const t = kp.find(to_key) orelse return error.BadKey;

        var it: ShortestPathsIter = .{
            .kp = kp,
            .start = s,
            .target = t,
        };

        // init dist
        var y: usize = 0;
        while (y < 5) : (y += 1) @memset(&it.dist[y], UNREACH);

        // BFS очередь фиксированная
        var qx: [64]i8 = undefined;
        var qy: [64]i8 = undefined;
        var head: usize = 0;
        var tail: usize = 0;

        it.dist[@intCast(s.y)][@intCast(s.x)] = 0;
        qx[tail] = s.x;
        qy[tail] = s.y;
        tail += 1;

        while (head < tail) : (head += 1) {
            const cx = qx[head];
            const cy = qy[head];
            const curd = it.dist[@intCast(cy)][@intCast(cx)];

            for (MOVES) |m| {
                const nx: i8 = cx + m.dx;
                const ny: i8 = cy + m.dy;
                const nc: Coord = .{ .x = nx, .y = ny };
                if (!kp.isOpen(nc)) continue;

                if (it.dist[@intCast(ny)][@intCast(nx)] == UNREACH) {
                    it.dist[@intCast(ny)][@intCast(nx)] = curd + 1;
                    qx[tail] = nx;
                    qy[tail] = ny;
                    tail += 1;
                }
            }
        }

        const d_to = it.dist[@intCast(t.y)][@intCast(t.x)];
        if (d_to == UNREACH) {
            it.finished = true; // путей нет
            return it;
        }
        it.L = d_to;
        return it;
    }

    /// Вернуть следующий кратчайший путь (без 'A'), записав его в buf.
    /// buf.len должен быть >= L (макс L небольшой).
    pub fn next(self: *ShortestPathsIter, buf: []u8) ?[]const u8 {
        if (self.finished) return null;
        if (buf.len < self.L) return null; // или panic/ошибка, но пусть будет null

        // частный случай: старт == цель, L==0 => единственный путь пустой
        if (self.L == 0) {
            if (self.started) {
                self.finished = true;
                return null;
            }
            self.started = true;
            return buf[0..0];
        }

        // первая инициализация DFS
        if (!self.started) {
            self.started = true;
            self.depth = 0;
            self.stack[0] = .{ .c = self.start, .next_move = 0 };
            self.at_solution = false;
        } else if (self.at_solution) {
            // мы стояли на решении; перед поиском следующего откатимся на шаг назад
            self.at_solution = false;
            if (!self.backtrack()) {
                self.finished = true;
                return null;
            }
        }

        while (true) {
            // если дошли до длины L, мы обязаны быть на target (иначе это не кратчайший путь)
            if (self.depth == self.L) {
                const c = self.stack[self.depth].c;
                if (c.x == self.target.x and c.y == self.target.y) {
                    self.at_solution = true;
                    return buf[0..self.L];
                }
                // не должно происходить, но на всякий случай:
                if (!self.backtrack()) {
                    self.finished = true;
                    return null;
                }
                continue;
            }

            // текущий фрейм
            var fr = &self.stack[self.depth];
            const cur = fr.c;
            const curd = self.dist[@intCast(cur.y)][@intCast(cur.x)];

            var moved = false;
            while (fr.next_move < 4) : (fr.next_move += 1) {
                const m = MOVES[fr.next_move];
                const nxt: Coord = .{ .x = cur.x + m.dx, .y = cur.y + m.dy };
                if (!self.kp.isOpen(nxt)) continue;

                const nd = self.dist[@intCast(nxt.y)][@intCast(nxt.x)];
                if (nd == UNREACH) continue;

                // идём только по кратчайшим: dist увеличивается на 1
                if (nd != curd + 1) continue;

                // выбираем этот ход
                buf[self.depth] = m.ch;
                fr.next_move += 1; // следующий раз продолжим со следующего движения
                self.depth += 1;
                self.stack[self.depth] = .{ .c = nxt, .next_move = 0 };
                moved = true;
                break;
            }

            if (!moved) {
                if (!self.backtrack()) {
                    self.finished = true;
                    return null;
                }
            }
        }
    }

    fn backtrack(self: *ShortestPathsIter) bool {
        // откатываемся, пока не найдём уровень, где остались неиспользованные ходы
        while (true) {
            if (self.depth == 0) return false;
            self.depth -= 1;
            if (self.stack[self.depth].next_move < 4) return true;
        }
    }
};
