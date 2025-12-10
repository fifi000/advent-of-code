from __future__ import annotations

from dataclasses import dataclass
from typing import NamedTuple

data = """
162,817,812
57,618,57
906,360,560
592,479,940
352,342,300
466,668,158
542,29,236
431,825,988
739,650,466
52,470,668
216,146,977
819,987,18
117,168,530
805,96,715
346,949,466
970,615,88
941,993,340
862,61,35
984,92,344
425,690,689
""".strip()


class Point(NamedTuple):
    x: int
    y: int
    z: int

    @staticmethod
    def parse(text: str) -> Point:
        x, y, z = text.strip().split(',')
        return Point(int(x), int(y), int(z))

    def distance(self, other: Point) -> float:
        s = (self.x - other.x) ** 2 + (self.y - other.y) ** 2 + (self.z - other.z) ** 2
        return (s) ** 0.5


@dataclass
class Circut:
    points: list[Point]


def find(circuts: list[Circut], point: Point) -> Circut:
    for circut in circuts:
        if point in circut.points:
            return circut

    assert False

def main() -> None:
    points = [Point.parse(line) for line in data.splitlines()]
    circuts = [Circut([point]) for point in points]

    stack: list[tuple[Point, Point]] = []
    for p1 in points:
        for p2 in points:
            if p1 == p2:
                continue

            if (p1, p2) in stack or (p2, p1) in stack:
                continue

            stack.append((p1, p2))
    stack.sort(key=lambda pair: pair[0].distance(pair[1]))

    counter = 0
    for p1, p2 in stack:
        if counter == 10:
            break

        c1 = find(circuts, p1)
        c2 = find(circuts, p2)

        if c1 != c2:
            # merge circuts
            c1.points.extend(c2.points)
            circuts.remove(c2)

        counter += 1

    circuts.sort(key=lambda x: -len(x.points))
    for c in circuts:
        print(c)

    print(
        f'result: "{len(circuts[0].points) * len(circuts[1].points) * len(circuts[2].points)}"'
    )


if __name__ == '__main__':
    main()
