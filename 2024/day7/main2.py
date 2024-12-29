"""
--- Part Two ---
The engineers seem concerned; the total calibration result you gave them is nowhere close to being within safety tolerances. Just then, you spot your mistake: some well-hidden elephants are holding a third type of operator.

The concatenation operator (||) combines the digits from its left and right inputs into a single number. For example, 12 || 345 would become 12345. All operators are still evaluated left-to-right.

Now, apart from the three equations that could be made true using only addition and multiplication, the above example has three more equations that can be made true by inserting operators:

156: 15 6 can be made true through a single concatenation: 15 || 6 = 156.
7290: 6 8 6 15 can be made true using 6 * 8 || 6 * 15.
192: 17 8 14 can be made true using 17 || 8 + 14.
Adding up all six test values (the three that could be made before using only + and * plus the new three that can now be made by also using ||) produces the new total calibration result of 11387.

Using your new knowledge of elephant hiding spots, determine which equations could possibly be true. What is their total calibration result?
"""

import itertools
import math

from tqdm import tqdm


OPERATORS = ['+', '*', '||']


def is_line_valid(line: str) -> int:
    lhs, rhs = line.split(':')
    expected_sum = int(lhs)

    nums = list(map(int, rhs.split()))
    for prod in itertools.product(OPERATORS, repeat=len(nums) - 1):
        if expected_sum == eval_eq(nums, prod):
            return expected_sum
    return 0


def eval_eq(nums: list[int], operations: list[str]) -> int:
    assert len(nums) - 1 == len(operations)

    result = nums[0]
    for num, op in zip(itertools.islice(nums, 1, None), operations, strict=True):
        result = calc(result, num, op)
    return result


def calc(a: int, b: int, op: str) -> int:
    match op:
        case '+':
            return a + b
        case '*':
            return a * b
        case '||':
            return a * (10 ** (math.floor(math.log10(b) + 1))) + b
    raise Exception


def main():
    with open('./2024/day7/input.txt') as file:
        lines = file.readlines()
        lines = list(map(str.strip, lines))
        result = sum([is_line_valid(line) for line in tqdm(lines)])
        print(result)  # 34612812972206


if __name__ == '__main__':
    main()
