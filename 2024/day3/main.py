"""
--- Day 3: Mull It Over ---
"Our computers are having issues, so I have no idea if we have any Chief Historians in stock! You're welcome to check the warehouse, though," says the mildly flustered shopkeeper at the North Pole Toboggan Rental Shop. The Historians head out to take a look.

The shopkeeper turns to you. "Any chance you can see why our computers are having issues again?"

The computer appears to be trying to run a program, but its memory (your puzzle input) is corrupted. All of the instructions have been jumbled up!

It seems like the goal of the program is just to multiply some numbers. It does that with instructions like mul(X,Y), where X and Y are each 1-3 digit numbers. For instance, mul(44,46) multiplies 44 by 46 to get a result of 2024. Similarly, mul(123,4) would multiply 123 by 4.

However, because the program's memory has been corrupted, there are also many invalid characters that should be ignored, even if they look like part of a mul instruction. Sequences like mul(4*, mul(6,9!, ?(12,34), or mul ( 2 , 4 ) do nothing.

For example, consider the following section of corrupted memory:

xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
Only the four highlighted sections are real mul instructions. Adding up the result of each instruction produces 161 (2*4 + 5*5 + 11*8 + 8*5).

Scan the corrupted memory for uncorrupted mul instructions. What do you get if you add up all of the results of the multiplications?
"""


class Helper:
    def __init__(self) -> None:
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

    def __repr__(self) -> str:
        return ''.join(self.current_text)

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


with open('./2024/day3/input.txt') as file:
    sums = []
    helper = Helper()

    while char := file.read(1):
        if isinstance(res := helper.add_next(char), int):
            sums.append(res)

    print(len(sums))
    print(sum(sums))
