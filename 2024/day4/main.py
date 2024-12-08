"""
--- Day 4: Ceres Search ---
"Looks like the Chief's not here. Next!" One of The Historians pulls out a device and pushes the only button on it. After a brief flash, you recognize the interior of the Ceres monitoring station!

As the search for the Chief continues, a small Elf who lives on the station tugs on your shirt; she'd like to know if you could help her with her word search (your puzzle input). She only has to find one word: XMAS.

This word search allows words to be horizontal, vertical, diagonal, written backwards, or even overlapping other words. It's a little unusual, though, as you don't merely need to find one instance of XMAS - you need to find all of them. Here are a few ways XMAS might appear, where irrelevant characters have been replaced with .:


..X...
.SAMX.
.A..A.
XMAS.S
.X....
The actual word search will be full of letters instead. For example:

MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX
In this word search, XMAS occurs a total of 18 times; here's the same word search again, but where letters not involved in any XMAS have been replaced with .:

....XXMAS.
.SAMXMS...
...S..A...
..A.A.MS.X
XMASAMX.MM
X.....XA.A
S.S.S.S.SS
.A.A.A.A.A
..M.M.M.MM
.X.X.XMASX
Take a look at the little Elf's word search. How many times does XMAS appear?
"""

import operator


class Solver:
    def __init__(self, array: list[str], key: str) -> None:
        self.array = [row.strip() for row in array]
        self.key = key

    def _check_all_dirs(self, i: int, j: int) -> int:
        result = 0
        for op1, op2 in Solver.get_operators():
            for idx, char in enumerate(self.key):
                try:
                    row_idx, col_idx = op1(i, idx), op2(j, idx)
                    if row_idx < 0 or col_idx < 0:
                        raise IndexError
                    if char != self.array[row_idx][col_idx]:
                        break
                except IndexError:
                    break
            else:
                result += 1
        return result

    @staticmethod
    def get_operators():
        ops = [operator.add, operator.sub, lambda a, b: a]
        for op1 in ops:
            for op2 in ops:
                yield op1, op2

    def find_all(self) -> int:
        occurrances = 0
        for i, row in enumerate(self.array):
            for j, val in enumerate(row):
                occurrances += self._check_all_dirs(i, j)
        return occurrances


if __name__ == '__main__':
    lines = open('./2024/day4/input.txt').readlines()
    solver = Solver(lines, 'XMAS')

    print(solver.find_all())  # 2571
