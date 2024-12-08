"""
--- Part Two ---
As you scan through the corrupted memory, you notice that some of the conditional statements are also still intact. If you handle some of the uncorrupted conditional statements in the program, you might be able to get an even more accurate result.

There are two new instructions you'll need to handle:

The do() instruction enables future mul instructions.
The don't() instruction disables future mul instructions.
Only the most recent do() or don't() instruction applies. At the beginning of the program, mul instructions are enabled.

For example:

xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
This corrupted memory is similar to the example from before, but this time the mul(5,5) and mul(11,8) instructions are disabled because there is a don't() instruction before them. The other mul instructions function normally, including the one at the end that gets re-enabled by a do() instruction.

This time, the sum of the results is 48 (2*4 + 8*5).

Handle the new instructions; what do you get if you add up all of the results of just the enabled multiplications?
"""


class Helper:
    def __init__(self) -> None:
        self.current_text = []

    def __repr__(self) -> str:
        return ''.join(self.current_text)


class MulHelper(Helper):
    def __init__(self) -> None:
        super().__init__()
        self.current_text = []
        self.funcs = self._get_next_func()
        self.expect_func = next(self.funcs)

    @property
    def x(self) -> int:
        start_idx = len('mul(')
        end_idx = self.current_text.index(',')
        result = self.current_text[start_idx:end_idx]
        result = ''.join(result)
        return int(result)

    @property
    def y(self) -> int:
        start_idx = self.current_text.index(',') + 1
        end_idx = self.current_text.index(')')
        result = self.current_text[start_idx:end_idx]
        result = ''.join(result)
        return int(result)

    def _get_next_func(self):
        yield self._expect_mul
        yield self._expect_open_brace
        yield self._expect_digit
        yield self._expect_digit_or_comma
        yield self._expect_digit
        yield self._expect_digit_or_close_brace

    def _expect_mul(self, char: str) -> bool:
        match len(self.current_text):
            case 0:
                return char == 'm'
            case 1:
                return char == 'u'
            case 2:
                if char == 'l':
                    self.expect_func = next(self.funcs)
                    return True
            case _:
                raise Exception('This method should not be called.')
        return False

    def _expect_open_brace(self, char: str) -> bool:
        if char == '(':
            self.expect_func = next(self.funcs)
            return True
        return False

    def _expect_digit(self, char: str) -> bool:
        if char.isdigit():
            self.expect_func = next(self.funcs)
            return True
        return False

    def _expect_digit_or_comma(self, char: str) -> bool:
        if char == ',':
            self.expect_func = next(self.funcs)
            return True
        return char.isdigit()

    def _expect_digit_or_close_brace(self, char: str) -> bool:
        if char == ')':
            return True
        return char.isdigit()

    def __eval(self) -> int:
        text = ''.join(self.current_text)
        if not (text.startswith('mul(') and text.endswith(')') and ',' in text):
            raise Exception('Should not call this method yet.')

        return self.x * self.y

    def add_next(self, char: str) -> int | None:
        if not self.is_valid(char):
            if len(self.current_text) > 0:
                self.__init__()
                return self.add_next(char)
            return None
        self.current_text.append(char)
        if char == ')':
            result = self.__eval()
            self.__init__()
            return result
        return None

    def is_valid(self, char: str) -> bool:
        return self.expect_func(char)


class SimpleHelper(Helper):
    def __init__(self, word) -> None:
        super().__init__()
        self.original_word = word
        self.word = list(reversed(self.original_word))

    def add_next(self, char: str) -> bool:
        if char == self.word.pop():
            if not self.word:
                self.__init__(self.original_word)
                return True
            return False
        self.__init__(self.original_word)
        return False


with open('./2024/day3/input.txt') as file:
    sums = []
    mul_helper = MulHelper()
    do_helper = SimpleHelper('do()')
    dont_helper = SimpleHelper("don't()")

    mul_enabled = True

    while char := file.read(1):
        if mul_enabled:
            if isinstance(res := mul_helper.add_next(char), int):
                sums.append(res)
            elif dont_helper.add_next(char):
                mul_enabled = False
        elif do_helper.add_next(char):
            mul_enabled = True

    print(len(sums))
    print(sum(sums))
