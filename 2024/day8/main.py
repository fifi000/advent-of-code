"""
--- Day 8: Resonant Collinearity ---
You find yourselves on the roof of a top-secret Easter Bunny installation.

While The Historians do their thing, you take a look at the familiar huge antenna. Much to your surprise, it seems to have been reconfigured to emit a signal that makes people 0.1% more likely to buy Easter Bunny brand Imitation Mediocre Chocolate as a Christmas gift! Unthinkable!

Scanning across the city, you find that there are actually many such antennas. Each antenna is tuned to a specific frequency indicated by a single lowercase letter, uppercase letter, or digit. You create a map (your puzzle input) of these antennas. For example:

............
........0...
.....0......
.......0....
....0.......
......A.....
............
............
........A...
.........A..
............
............
The signal only applies its nefarious effect at specific antinodes based on the resonant frequencies of the antennas. In particular, an antinode occurs at any point that is perfectly in line with two antennas of the same frequency - but only when one of the antennas is twice as far away as the other. This means that for any pair of antennas with the same frequency, there are two antinodes, one on either side of them.

So, for these two antennas with frequency a, they create the two antinodes marked with #:

..........
...#......
..........
....a.....
..........
.....a....
..........
......#...
..........
..........
Adding a third antenna with the same frequency creates several more antinodes. It would ideally add four antinodes, but two are off the right side of the map, so instead it adds only two:

..........
...#......
#.........
....a.....
........a.
.....a....
..#.......
......#...
..........
..........
Antennas with different frequencies don't create antinodes; A and a count as different frequencies. However, antinodes can occur at locations that contain antennas. In this diagram, the lone antenna with frequency capital A creates no antinodes but has a lowercase-a-frequency antinode at its location:

..........
...#......
#.........
....a.....
........a.
.....a....
..#.......
......A...
..........
..........
The first example has antennas with two different frequencies, so the antinodes they create look like this, plus an antinode overlapping the topmost A-frequency antenna:

......#....#
...#....0...
....#0....#.
..#....0....
....0....#..
.#....A.....
...#........
#......#....
........A...
.........A..
..........#.
..........#.
Because the topmost A-frequency antenna overlaps with a 0-frequency antinode, there are 14 total unique locations that contain an antinode within the bounds of the map.

Calculate the impact of the signal. How many unique locations within the bounds of the map contain an antinode?
"""

import itertools
import time
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


def calc_antinodes(point1: Point, point2: Point) -> list[Point]:
    return [
        # P1 ---- P2 ---- unknown
        get_line_endpoint(point1, point2),
        # P2 ---- P1 ---- unknown
        get_line_endpoint(point2, point1),
    ]


def add_antinode(array: list[list[str]], antinode: Point) -> None:
    if not is_valid_index(array, antinode):
        return
    x, y = antinode
    if array[x][y] == '.':
        array[x][y] = '#'


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
    start = time.perf_counter_ns()

    # file_start = time.perf_counter_ns()
    lines = open('./2024/day8/input.txt').read().replace('\r', '').splitlines()
    array = [list(line.rstrip()) for line in lines]
    # print(f'File in {((time.perf_counter_ns() - file_start) / 1_000_000_000):.6f}')

    antennas: dict[str, list[tuple]] = {}

    for i, row in enumerate(array):
        for j, cell in enumerate(row):
            if is_antenna(cell):
                antennas.setdefault(cell, list()).append((i, j))

    antinodes: list[Point] = []
    for locations in antennas.values():
        pairs = itertools.combinations(locations, r=2)
        for p1, p2 in pairs:
            antinodes.extend(calc_antinodes(p1, p2))

    unique: set[Point] = {
        antinode for antinode in antinodes if is_valid_index(array, antinode)
    }

    # pprint(unique)
    print(len(unique))  # 376
    print(f'Found in {(time.perf_counter_ns() - start) / 1_000_000_000:0.6f} s')


if __name__ == '__main__':
    main()
