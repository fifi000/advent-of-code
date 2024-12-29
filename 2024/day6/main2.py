"""
--- Part Two ---
While The Historians begin working around the guard's patrol route, you borrow their fancy device and step outside the lab. From the safety of a supply closet, you time travel through the last few months and record the nightly status of the lab's guard post on the walls of the closet.

Returning after what seems like only a few seconds to The Historians, they explain that the guard's patrol area is simply too large for them to safely search the lab without getting caught.

Fortunately, they are pretty sure that adding a single new obstruction won't cause a time paradox. They'd like to place the new obstruction in such a way that the guard will get stuck in a loop, making the rest of the lab safe to search.

To have the lowest chance of creating a time paradox, The Historians would like to know all of the possible positions for such an obstruction. The new obstruction can't be placed at the guard's starting position - the guard is there right now and would notice.

In the above example, there are only 6 different positions where a new obstruction would cause the guard to get stuck in a loop. The diagrams of these six situations use O to mark the new obstruction, | to show a position where the guard moves up/down, - to show a position where the guard moves left/right, and + to show a position where the guard moves both up/down and left/right.

Option one, put a printing press next to the guard's starting position:

....#.....
....+---+#
....|...|.
..#.|...|.
....|..#|.
....|...|.
.#.O^---+.
........#.
#.........
......#...
Option two, put a stack of failed suit prototypes in the bottom right quadrant of the mapped area:


....#.....
....+---+#
....|...|.
..#.|...|.
..+-+-+#|.
..|.|.|.|.
.#+-^-+-+.
......O.#.
#.........
......#...
Option three, put a crate of chimney-squeeze prototype fabric next to the standing desk in the bottom right quadrant:

....#.....
....+---+#
....|...|.
..#.|...|.
..+-+-+#|.
..|.|.|.|.
.#+-^-+-+.
.+----+O#.
#+----+...
......#...
Option four, put an alchemical retroencabulator near the bottom left corner:

....#.....
....+---+#
....|...|.
..#.|...|.
..+-+-+#|.
..|.|.|.|.
.#+-^-+-+.
..|...|.#.
#O+---+...
......#...
Option five, put the alchemical retroencabulator a bit to the right instead:

....#.....
....+---+#
....|...|.
..#.|...|.
..+-+-+#|.
..|.|.|.|.
.#+-^-+-+.
....|.|.#.
#..O+-+...
......#...
Option six, put a tank of sovereign glue right next to the tank of universal solvent:

....#.....
....+---+#
....|...|.
..#.|...|.
..+-+-+#|.
..|.|.|.|.
.#+-^-+-+.
.+----++#.
#+----++..
......#O..
It doesn't really matter what you choose to use as an obstacle so long as you and The Historians can put it into position without the guard noticing. The important thing is having enough options that you can find one that minimizes time paradoxes, and in this example, there are 6 different positions you could choose.

You need to get the guard stuck in a loop by adding a single new obstruction. How many different positions could you choose for this obstruction?
"""

from itertools import islice
from tqdm import tqdm


GUARDS = {
    '^',
    '>',
    'v',
    '<',
}

OBSTACLE = '#'
MARK = 'X'


class Solver:
    def __init__(self, array: list[list]) -> None:
        self.array = array

    @staticmethod
    def find_guard(array: list[list]) -> tuple[int, int, str]:
        for i, row in enumerate(array):
            for j, cell in enumerate(row):
                if cell in GUARDS:
                    return i, j, cell

        raise Exception('Did not find any guard.')

    @staticmethod
    def turn_right(guard: str) -> str:
        match guard:
            case '^':
                return '>'
            case '>':
                return 'v'
            case 'v':
                return '<'
            case '<':
                return '^'
        raise Exception(f'Wrong guard type `{guard}`.')

    @staticmethod
    def get_new_pos(guard: str, i: int, j: int) -> tuple[int, int]:
        match guard:
            case '^':
                return i - 1, j
            case '>':
                return i, j + 1
            case 'v':
                return i + 1, j
            case '<':
                return i, j - 1
        raise Exception(f'Wrong guard type `{guard}`.')

    def is_valid_pos(self, i: int, j: int) -> bool:
        if i < 0 or j < 0:
            raise IndexError
        return self.array[i][j] != OBSTACLE

    def try_move(self, guard: str, i: int, j: int) -> tuple[int, int, str]:
        starting_guard = guard

        while True:
            new_i, new_j = self.get_new_pos(guard, i, j)
            if self.is_valid_pos(new_i, new_j):
                return new_i, new_j, guard
            if (guard := self.turn_right(guard)) == starting_guard:
                raise Exception

    def mark_guard_steps(self) -> list[list]:
        new_array = [row.copy() for row in self.array]
        curr_i, curr_j, guard = self.find_guard(self.array)
        seen_positions: set[tuple[int, int, str]] = set()

        while True:
            # mark current position
            new_array[curr_i][curr_j] = MARK

            # no more moves or new direction
            try:
                new_i, new_j, guard = self.try_move(guard, curr_i, curr_j)
            except Exception:
                break

            # already seen this position
            if (new_i, new_j, guard) in seen_positions:
                break

            # move
            new_array[new_i][new_j] = guard
            seen_positions.add((new_i, new_j, guard))
            curr_i, curr_j = new_i, new_j

        return new_array

    def stuck_in_loop(self) -> bool:
        new_array = [row.copy() for row in self.array]
        curr_i, curr_j, guard = self.find_guard(new_array)
        seen_positions: set[tuple[int, int, str]] = set()

        while True:
            # mark current position
            new_array[curr_i][curr_j] = MARK

            try:
                # get new directions
                new_i, new_j, guard = self.try_move(guard, curr_i, curr_j)
            except Exception:
                # no more moves
                break

            # already seen this position
            if (new_i, new_j, guard) in seen_positions:
                return True

            # move
            new_array[new_i][new_j] = guard
            seen_positions.add((new_i, new_j, guard))
            curr_i, curr_j = new_i, new_j

        return False


def find_obstacle(
    array: list[list[str]], pos: tuple[int, int], dir: str
) -> tuple[int, int] | None:
    i, j = pos
    if not (0 <= i < len(array)):
        return None
    if not (0 <= j < len(array[i])):
        return None

    match dir:
        case '>':
            col_idx = j + 1
            while col_idx < len(array[i]):
                if array[i][col_idx] == OBSTACLE:
                    return i, col_idx - 1
                col_idx += 1
            return None
        case '<':
            col_idx = j - 1
            while col_idx >= 0:
                if array[i][col_idx] == OBSTACLE:
                    return i, col_idx + 1
                col_idx -= 1
            return None
        case '^':
            row_idx = i - 1
            while row_idx >= 0:
                if array[row_idx][j] == OBSTACLE:
                    return row_idx + 1, j
                row_idx -= 1
            return None
        case 'v':
            row_idx = i + 1
            while row_idx < len(array):
                if array[row_idx][j] == OBSTACLE:
                    return row_idx - 1, j
                row_idx += 1
            return None
        case _:
            raise Exception


def is_valid_candidate(array: list[list[str]], i: int, j: int) -> bool:
    # upper left
    if new_pos := find_obstacle(array, (i + 1, j), '>'):
        if new_pos := find_obstacle(array, new_pos, 'v'):
            if new_pos := find_obstacle(array, new_pos, '<'):
                if new_pos[1] == j:
                    return True

    # upper right
    if new_pos := find_obstacle(array, (i, j - 1), 'v'):
        if new_pos := find_obstacle(array, new_pos, '<'):
            if new_pos := find_obstacle(array, new_pos, '^'):
                if new_pos[0] == i:
                    return True
    # lower left
    if new_pos := find_obstacle(array, (i, j + 1), '^'):
        if new_pos := find_obstacle(array, new_pos, '>'):
            if new_pos := find_obstacle(array, new_pos, 'v'):
                if new_pos[0] == i:
                    return True

    # lower right
    if new_pos := find_obstacle(array, (i - 1, j), '<'):
        if new_pos := find_obstacle(array, new_pos, '^'):
            if new_pos := find_obstacle(array, new_pos, '>'):
                if new_pos[1] == j:
                    return True

    return False


if __name__ == '__main__':
    lines = map(str.strip, open('./2024/day6/input.txt').readlines())
    array = [list(line) for line in lines]

    solver = Solver(array)
    start_i, start_j, _ = solver.find_guard(solver.array)

    candidates = [
        (i, j)
        for i, row in enumerate(solver.mark_guard_steps())
        for j, cell in enumerate(row)
        if cell == MARK and (start_i, start_j) != (i, j)
    ]

    count = 0
    new_array = [row[:] for row in array]
    for i, j in tqdm(candidates):
        prev = new_array[i][j]
        if is_valid_candidate(new_array, i, j):
            new_array[i][j] = OBSTACLE
            count += Solver(new_array).stuck_in_loop()
        new_array[i][j] = prev

    print(count)  # 1928
