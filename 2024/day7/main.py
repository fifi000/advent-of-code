"""
--- Day 7: Bridge Repair ---
The Historians take you to a familiar rope bridge over a river in the middle of a jungle. The Chief isn't on this side of the bridge, though; maybe he's on the other side?

When you go to cross the bridge, you notice a group of engineers trying to repair it. (Apparently, it breaks pretty frequently.) You won't be able to cross until it's fixed.

You ask how long it'll take; the engineers tell you that it only needs final calibrations, but some young elephants were playing nearby and stole all the operators from their calibration equations! They could finish the calibrations if only someone could determine which test values could possibly be produced by placing any combination of operators into their calibration equations (your puzzle input).

For example:

190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20
Each line represents a single equation. The test value appears before the colon on each line; it is your job to determine whether the remaining numbers can be combined with operators to produce the test value.

Operators are always evaluated left-to-right, not according to precedence rules. Furthermore, numbers in the equations cannot be rearranged. Glancing into the jungle, you can see elephants holding two different types of operators: add (+) and multiply (*).

Only three of the above equations can be made true by inserting operators:

190: 10 19 has only one position that accepts an operator: between 10 and 19. Choosing + would give 29, but choosing * would give the test value (10 * 19 = 190).
3267: 81 40 27 has two positions for operators. Of the four possible configurations of the operators, two cause the right side to match the test value: 81 + 40 * 27 and 81 * 40 + 27 both equal 3267 (when evaluated left-to-right)!
292: 11 6 16 20 can be solved in exactly one way: 11 + 6 * 16 + 20.
The engineers just need the total calibration result, which is the sum of the test values from just the equations that could possibly be true. In the above example, the sum of the test values for the three equations listed above is 3749.

Determine which equations could possibly be true. What is their total calibration result?
"""

import re
import time


class Product:
    def __init__(self, a: str, b: str, length: int) -> None:
        self.a = a
        self.b = b
        self.length = length
        self._flags = (2**self.length) - 1

    def _is_overflow(self) -> bool:
        return self._flags < 0

    def next(self) -> list[str] | None:
        if self._is_overflow():
            return None

        output = [
            self.a if (self._flags & (1 << i)) != 0 else self.b
            for i in range(self.length)
        ]

        self._flags -= 1

        return output


def is_line_valid(line: str) -> None | int:
    s = None
    nums = []

    for word in re.split(r'[: \n\r]', line):
        if not word:
            continue
        num = int(word)

        if s is None:
            s = num
            continue
        nums.append(num)

    # for perm in product(('+', '*'), repeat=(len(nums) - 1)):
    #     test_sum = calc_equation(nums, perm)
    #     if test_sum == s:
    #         return s
    op_iter = Product('+', '*', len(nums) - 1)
    while (perm := op_iter.next()) is not None:
        test_sum = calc_equation(nums, perm)
        if test_sum == s:
            return s

    return None


def calc_equation(nums: list[int], operations: list[str]) -> int:
    assert len(nums) - 1 == len(operations)

    s = nums[0]

    for num, op in zip(nums[1:], operations, strict=True):
        s = calc(s, num, op)

    return s


def calc(a: int, b: int, operation: str) -> int:
    match operation:
        case '+':
            return a + b
        case '*':
            return a * b
    raise Exception


def main():
    start = time.perf_counter()
    with open('./2024/day7/input.txt', encoding='utf8') as file:
        s = 0

        while line := file.readline():
            line = line.strip()
            result = is_line_valid(line)
            if result is None:
                continue
            s += result
            print('line:', line)

        print('result:', s)

    end = time.perf_counter()
    print(f'\nDone in {end - start:.6f} s')


if __name__ == '__main__':
    main()

    length = 4
    for i in range(0, 3):
        for idx in range(length):
            print()
