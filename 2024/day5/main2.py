"""
--- Part Two ---
While the Elves get to work printing the correctly-ordered updates, you have a little time to fix the rest of them.

For each of the incorrectly-ordered updates, use the page ordering rules to put the page numbers in the right order. For the above example, here are the three incorrectly-ordered updates and their correct orderings:

75,97,47,61,53 becomes 97,75,47,61,53.
61,13,29 becomes 61,29,13.
97,13,75,29,47 becomes 97,75,47,29,13.
After taking only the incorrectly-ordered updates and ordering them correctly, their middle page numbers are 47, 29, and 47. Adding these together produces 123.

Find the updates which are not in the correct order. What do you get if you add up the middle page numbers after correctly ordering just those updates?
"""

from pprint import pprint
from functools import cmp_to_key


class Solver:
    def __init__(self, rules: list[str]) -> None:
        self.rules = [rule.split('|') for rule in rules]
        self.rulebook = self._create_rulebook()

    def _create_rulebook(self) -> dict[int, set[int]]:
        rulebook = {}
        pairs = (map(int, rule) for rule in self.rules)
        for left, right in pairs:
            rulebook.setdefault(right, set()).add(left)
        return rulebook

    def is_valid_update(self, update: list[int]) -> bool:
        seen = set()

        for num in reversed(update):
            for page in self.rulebook.get(num, ()):
                if page in seen:
                    return False
            seen.add(num)

        return True

    def fix_update(self, update: list[int]) -> list[int]:
        def cmp(a: int, b: int) -> int:
            if a in self.rulebook.get(b, ()):
                return -1
            if b in self.rulebook.get(a, ()):
                return 1
            return 0

        return list(sorted(update, key=cmp_to_key(cmp)))


if __name__ == '__main__':
    rules: list[str] = []
    updates: list[str] = []

    with open('./2024/day5/input.txt') as file:
        # gather rules
        while line := file.readline():
            if not (line := line.strip()):
                break
            rules.append(line)

        # gather updates
        while line := file.readline():
            if not (line := line.strip()):
                break
            updates.append(line)

    solver = Solver(rules)

    middle_sum = 0
    for update in updates:
        splited = list(map(int, update.split(',')))
        if solver.is_valid_update(splited):
            continue

        splited = solver.fix_update(splited)
        # get middle element
        assert len(splited) % 2 == 1
        middle_sum += splited[len(splited) // 2]

    print(middle_sum)  # 5184
