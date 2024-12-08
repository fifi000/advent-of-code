"""
--- Part Two ---
The engineers are surprised by the low number of safe reports until they realize they forgot to tell you about the Problem Dampener.

The Problem Dampener is a reactor-mounted module that lets the reactor safety systems tolerate a single bad level in what would otherwise be a safe report. It's like the bad level never happened!

Now, the same rules apply as before, except if removing a single level from an unsafe report would make it safe, the report instead counts as safe.

More of the above example's reports are now safe:

7 6 4 2 1: Safe without removing any level.
1 2 7 8 9: Unsafe regardless of which level is removed.
9 7 6 2 1: Unsafe regardless of which level is removed.
1 3 2 4 5: Safe by removing the second level, 3.
8 6 4 4 1: Safe by removing the third level, 4.
1 3 6 7 9: Safe without removing any level.
Thanks to the Problem Dampener, 4 reports are actually safe!

Update your analysis by handling situations where the Problem Dampener can remove a single level from unsafe reports. How many reports are now safe?
"""

import operator
from typing import Any


def same_sign(n: int, m: int) -> bool:
    if n == m:
        return True
    if n < 0 and m < 0:
        return True
    if n > 0 and m > 0:
        return True
    return False


def get_without(array: list[Any], idx: int) -> list[Any]:
    return array[:idx] + array[idx + 1 :]


def is_safe(levels: list[int]) -> bool:
    prev_diff = None

    for i, diff in enumerate(map(operator.sub, levels[:-1], levels[1:])):
        if diff == 0:
            return False
        if prev_diff is not None and not same_sign(diff, prev_diff):
            return False
        if abs(diff) not in {1, 2, 3}:
            return False

        prev_diff = diff

    return True


lines = open('./2024/day2/input2.txt').readlines()
reports = [line.strip().split() for line in lines]
reports = [list(map(int, report)) for report in reports]

result = 0
for report in reports:
    if is_safe(report):
        result += 1
        continue
    for i in range(len(report)):
        if is_safe(get_without(report, i)):
            result += 1
            break


print(result)  # 700
