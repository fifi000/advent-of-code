from collections import Counter


lines = open('./2024/day1/input.txt').readlines()
lines = [line.strip().split() for line in lines]

left = [int(line[0]) for line in lines]
right = [int(line[1]) for line in lines]

right_counter = Counter(right)

result = 0

for num in left:
    result += num * right_counter.get(num, 0)

print(f'{result=}')
