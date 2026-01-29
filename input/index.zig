const iter = @import("iter.zig");
const grid = @import("grid.zig");
const input = @import("input.zig");
const util = @import("util.zig");

pub const LinesIter = iter.LinesIter;
pub const LinesIterTrim = iter.LinesIterTrim;
pub const TokensIter = iter.TokensIter;
pub const GroupsIter = iter.GroupsIter;

pub const GridLines = grid.GridLines;
pub const gridFlatten = grid.gridFlatten;
pub const gridDigits = grid.gridDigits;
pub const Grid = grid.Grid;
pub const Neigh4Iter = grid.Neigh4Iter;
pub const gridLinesFromSlice = grid.gridLinesFromSlice;

pub const Input = input.Input;
pub const readFile = input.readFile;

pub const tokensAny = util.tokensAny;
pub const groupLines = util.groupLines;
pub const stringsAny = util.stringsAny;
pub const stringsAnyTrim = util.stringsAnyTrim;
pub const stringsScalarKeepEmpty = util.stringsScalarKeepEmpty;
pub const stripByteInPlace = util.stripByteInPlace;
pub const Dir = util.Dir;
