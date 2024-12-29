"""
--- Part Two ---
Watching over your shoulder as you work, one of The Historians asks if you took the effects of resonant harmonics into your calculations.

Whoops!

After updating your model, it turns out that an antinode occurs at any grid position exactly in line with at least two antennas of the same frequency, regardless of distance. This means that some of the new antinodes will occur at the position of each antenna (unless that antenna is the only one of its frequency).

So, these three T-frequency antennas now create many antinodes:

T....#....
...T......
.T....#...
.........#
..#.......
..........
...#......
..........
....#.....
..........
In fact, the three T-frequency antennas are all exactly in line with two antennas, so they are all also antinodes! This brings the total number of antinodes in the above example to 9.

The original example now has 34 antinodes, including the antinodes that appear on every antenna:

##....#....#
.#.#....0...
..#.#0....#.
..##...0....
....0....#..
.#...#A....#
...#..#.....
#....#.#....
..#.....A...
....#....A..
.#........#.
...#......##
Calculate the impact of the signal using this updated model. How many unique locations within the bounds of the map contain an antinode?
"""

import itertools
from pprint import pprint
from typing import TypeAlias


Point: TypeAlias = tuple[int, int]


def is_antenna(letter: str) -> bool:
    assert len(letter) == 1

    return letter.isalnum()


def get_line_endpoint(start: Point, middle: Point) -> Point:
    start_x, start_y = start
    middle_x, middle_y = middle

    end_x = 2 * middle_x - start_x
    end_y = 2 * middle_y - start_y

    return end_x, end_y


def calc_antinodes(array: list[list[str]], point1: Point, point2: Point) -> set[Point]:
    output = {point1, point2}

    left, middle = point1, point2
    while True:
        right = get_line_endpoint(left, middle)
        if not is_valid_index(array, right):
            break
        output.add(right)
        left, middle = middle, right

    left, middle = point2, point1
    while True:
        right = get_line_endpoint(left, middle)
        if not is_valid_index(array, right):
            break
        output.add(right)
        left, middle = middle, right

    return output


def is_valid_index(array: list[list[str]], antinode: Point) -> bool:
    x, y = antinode

    if not (0 <= x < len(array)):
        return False
    if not (0 <= y < len(array[x])):
        return False

    return True


def print_map(array):
    for row in array:
        print(''.join(row))
    print()


def main():
    lines = open('./2024/day8/input.txt').read().replace('\r', '').splitlines()
    array = [list(line.rstrip()) for line in lines]

    antennas: dict[str, list[tuple]] = {}
    for i, row in enumerate(array):
        for j, cell in enumerate(row):
            if is_antenna(cell):
                antennas.setdefault(cell, list()).append((i, j))

    antinodes: set[Point] = set()
    for locations in antennas.values():
        pairs = itertools.combinations(locations, r=2)
        for p1, p2 in pairs:
            antinodes.update(calc_antinodes(array, p1, p2))

    pprint(antinodes)

    for i, row in enumerate(array):
        for j, col in enumerate(row):
            if col == '.' and (i, j) in antinodes:
                print('#', end='')
            else:
                print(col, end='')
        print()

    print(len(antinodes))  # 376


if __name__ == '__main__':
    main()
