"""
--- Day 6: Guard Gallivant ---
The Historians use their fancy device again, this time to whisk you all away to the North Pole prototype suit manufacturing lab... in the year 1518! It turns out that having direct access to history is very convenient for a group of historians.

You still have to be careful of time paradoxes, and so it will be important to avoid anyone from 1518 while The Historians search for the Chief. Unfortunately, a single guard is patrolling this part of the lab.

Maybe you can work out where the guard will go ahead of time so that The Historians can search safely?

You start by making a map (your puzzle input) of the situation. For example:

....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#...
The map shows the current position of the guard with ^ (to indicate the guard is currently facing up from the perspective of the map). Any obstructions - crates, desks, alchemical reactors, etc. - are shown as #.

Lab guards in 1518 follow a very strict patrol protocol which involves repeatedly following these steps:

If there is something directly in front of you, turn right 90 degrees.
Otherwise, take a step forward.
Following the above protocol, the guard moves up several times until she reaches an obstacle (in this case, a pile of failed suit prototypes):

....#.....
....^....#
..........
..#.......
.......#..
..........
.#........
........#.
#.........
......#...
Because there is now an obstacle in front of the guard, she turns right before continuing straight in her new facing direction:

....#.....
........>#
..........
..#.......
.......#..
..........
.#........
........#.
#.........
......#...
Reaching another obstacle (a spool of several very long polymers), she turns right again and continues downward:

....#.....
.........#
..........
..#.......
.......#..
..........
.#......v.
........#.
#.........
......#...
This process continues for a while, but the guard eventually leaves the mapped area (after walking past a tank of universal solvent):

....#.....
.........#
..........
..#.......
.......#..
..........
.#........
........#.
#.........
......#v..
By predicting the guard's route, you can determine which specific positions in the lab will be in the patrol path. Including the guard's starting position, the positions visited by the guard before leaving the area are marked with an X:

....#.....
....XXXXX#
....X...X.
..#.X...X.
..XXXXX#X.
..X.X.X.X.
.#XXXXXXX.
.XXXXXXX#.
#XXXXXXX..
......#X..
In this example, the guard will visit 41 distinct positions on your map.

Predict the path of the guard. How many distinct positions will the guard visit before leaving the mapped area?
"""

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

    def find_guard(self) -> tuple[int, int, str]:
        for i, row in enumerate(self.array):
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
        curr_i, curr_j, guard = self.find_guard()
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


if __name__ == '__main__':
    lines = map(str.strip, open('./2024/day6/input.txt').readlines())
    array = [list(line) for line in lines]

    solver = Solver(array)
    new_array = solver.mark_guard_steps()
    mark_count = sum([cell == MARK for row in new_array for cell in row])
    print(mark_count)  # 5030
