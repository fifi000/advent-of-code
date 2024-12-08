"""
--- Part Two ---
The Elf looks quizzically at you. Did you misunderstand the assignment?

Looking for the instructions, you flip over the word search to find that this isn't actually an XMAS puzzle; it's an X-MAS puzzle in which you're supposed to find two MAS in the shape of an X. One way to achieve that is like this:

M.S
.A.
M.S
Irrelevant characters have again been replaced with . in the above diagram. Within the X, each MAS can be written forwards or backwards.

Here's the same example from before, but this time all of the X-MASes have been kept instead:

.M.S......
..A..MSMS.
.M.S.MAA..
..A.ASMSM.
.M.S.M....
..........
S.S.S.S.S.
.A.A.A.A..
M.M.M.M.M.
..........
In this example, an X-MAS appears 9 times.

Flip the word search from the instructions back over to the word search side and try again. How many times does an X-MAS appear?
"""


class Solver:
    def __init__(self, array: list[str], key: str) -> None:
        self.array = [row.strip() for row in array]
        assert len(key) % 2 == 1
        self.key = key

    def _check_positive_diagonal(self, i: int, j: int) -> bool:
        # /  -  bottom to up
        start_i = i + len(self.key) // 2
        start_j = j - len(self.key) // 2
        for idx, char in enumerate(self.key):
            try:
                row_idx, col_idx = start_i - idx, start_j + idx
                if row_idx < 0 or col_idx < 0:
                    raise IndexError
                if self.array[row_idx][col_idx] != char:
                    break
            except IndexError:
                break
        else:
            return True

        # /  -  up to bottom
        start_i = i - len(self.key) // 2
        start_j = j + len(self.key) // 2
        for idx, char in enumerate(self.key):
            try:
                row_idx, col_idx = start_i + idx, start_j - idx
                if row_idx < 0 or col_idx < 0:
                    raise IndexError
                if self.array[row_idx][col_idx] != char:
                    break
            except IndexError:
                break
        else:
            return True

        return False

    def _check_negative_diagonal(self, i: int, j: int) -> bool:
        # \  -  up to bottom
        start_i = i - len(self.key) // 2
        start_j = j - len(self.key) // 2
        for idx, char in enumerate(self.key):
            try:
                row_idx, col_idx = start_i + idx, start_j + idx
                if row_idx < 0 or col_idx < 0:
                    raise IndexError
                if self.array[row_idx][col_idx] != char:
                    break
            except IndexError:
                break
        else:
            return True

        # \  -  bottom to up
        start_i = i + len(self.key) // 2
        start_j = j + len(self.key) // 2
        for idx, char in enumerate(self.key):
            try:
                row_idx, col_idx = start_i - idx, start_j - idx
                if row_idx < 0 or col_idx < 0:
                    raise IndexError
                if self.array[row_idx][col_idx] != char:
                    break
            except IndexError:
                break
        else:
            return True

        return False

    def _is_x(self, i: int, j: int) -> bool:
        if self.array[i][j] != self.key[len(self.key) // 2]:
            return False
        return self._check_positive_diagonal(i, j) and self._check_negative_diagonal(
            i, j
        )

    def find_all(self) -> int:
        occurrances = 0
        for i, row in enumerate(self.array):
            for j, val in enumerate(row):
                occurrances += self._is_x(i, j)
        return occurrances


if __name__ == '__main__':
    lines = open('./2024/day4/input2.txt').readlines()
    solver = Solver(lines, 'MAS')

    print(solver.find_all())  # 2571
