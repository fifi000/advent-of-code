from main import Solver

KEY = 'XMAS'


def test1():
    lines = """
XMAS
MMAA
AAAM
SAMS
""".strip().splitlines()
    solver = Solver(lines, KEY)
    assert solver.find_all() == 3


def test2():
    lines = """
..X...
.SAMX.
.A..A.
XMAS.S
.X....
""".strip().splitlines()
    solver = Solver(lines, KEY)
    assert solver.find_all() == 4


def test3():
    lines = """
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
""".strip().splitlines()
    solver = Solver(lines, KEY)
    assert solver.find_all() == 18


def test4():
    lines = """
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
""".strip().splitlines()
    solver = Solver(lines, KEY)
    assert solver.find_all() == 18
