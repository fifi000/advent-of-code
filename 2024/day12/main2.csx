class Region
{

    public int Area => points.Count;

    private readonly HashSet<Point> points = [];

    public int Fence => Area * Sides();

    public int Sides()
    {
        Debug.Assert(points.Count != 0);

        // collections of points that is a border point
        var sides = new
        {
            Left = new List<Point>(),
            Top = new List<Point>(),
            Right = new List<Point>(),
            Bottom = new List<Point>(),
        };

        foreach (var point in points)
        {
            // left
            if (point.ColIdx == 0)
            {
                if (sides.Left.All(x => !AreConntected(point, x)))
                {
                    sides.Left.Add(point);
                }
            }
            else if (array[point.RowIdx][point.ColIdx - 1] != point.Value())
            {
                if (sides.Left.Where(x => x.ColIdx == point.ColIdx && AreConntected(x, point)).All(x => !AreConntected(new Point { RowIdx = point.RowIdx, ColIdx = point.ColIdx - 1 }, new Point { RowIdx = x.RowIdx, ColIdx = x.ColIdx - 1 }, point.Value())))
                {
                    sides.Left.Add(point);
                }
            }

            // top
            if (point.RowIdx == 0)
            {
                if (sides.Top.All(x => !AreConntected(point, x)))
                {
                    sides.Top.Add(point);
                }
            }
            else if (array[point.RowIdx - 1][point.ColIdx] != point.Value())
            {
                if (sides.Top.Where(x => x.RowIdx == point.RowIdx && AreConntected(x, point)).All(x => !AreConntected(new Point { RowIdx = point.RowIdx - 1, ColIdx = point.ColIdx }, new Point { RowIdx = x.RowIdx - 1, ColIdx = x.ColIdx }, point.Value())))
                {
                    sides.Top.Add(point);
                }
            }

            // right
            if (point.ColIdx == array[point.RowIdx].Length - 1)
            {
                if (sides.Right.All(x => !AreConntected(point, x)))
                {
                    sides.Right.Add(point);
                }
            }
            else if (array[point.RowIdx][point.ColIdx + 1] != point.Value())
            {
                if (sides.Right.Where(x => x.ColIdx == point.ColIdx && AreConntected(x, point)).All(x => !AreConntected(new Point { RowIdx = point.RowIdx, ColIdx = point.ColIdx + 1 }, new Point { RowIdx = x.RowIdx, ColIdx = x.ColIdx + 1 }, point.Value())))
                {
                    sides.Right.Add(point);
                }
            }

            // bottom
            if (point.RowIdx == array.Length - 1)
            {
                if (sides.Bottom.All(x => !AreConntected(point, x)))
                {
                    sides.Bottom.Add(point);
                }
            }
            else if (array[point.RowIdx + 1][point.ColIdx] != point.Value())
            {
                if (sides.Bottom.Where(x => x.RowIdx == point.RowIdx && AreConntected(x, point)).All(x => !AreConntected(new Point { RowIdx = point.RowIdx + 1, ColIdx = point.ColIdx }, new Point { RowIdx = x.RowIdx + 1, ColIdx = x.ColIdx }, point.Value())))
                {
                    sides.Bottom.Add(point);
                }
            }
        }

        if (!printed)
        {
            WriteLine($"[{string.Join(", ", new[] { sides.Left, sides.Top, sides.Right, sides.Bottom }.Select(x => x.Count))}]");
            printed = true;
        }
        return new[] { sides.Left, sides.Top, sides.Right, sides.Bottom }.Select(x => x.Count).Sum();
    }

    private bool printed = false;

    private static bool AreConntected(Point point1, Point point2, char value)
    {
        Debug.Assert(!(point1.RowIdx == point2.RowIdx && point1.ColIdx == point2.ColIdx));

        // check for horizontal connection
        if (point1.RowIdx == point2.RowIdx)
        {
            int fromCol = Math.Min(point1.ColIdx, point2.ColIdx);
            int toCol = Math.Max(point1.ColIdx, point2.ColIdx);

            for (int i = fromCol; i <= toCol; i++)
            {
                if (array[point1.RowIdx][i] == value)
                {
                    return false;
                }
            }

            return true;
        }

        // check for vertical connection
        if (point1.ColIdx == point2.ColIdx)
        {
            int fromRow = Math.Min(point1.RowIdx, point2.RowIdx);
            int toRow = Math.Max(point1.RowIdx, point2.RowIdx);

            for (int i = fromRow; i <= toRow; i++)
            {
                if (array[i][point1.ColIdx] == value)
                {
                    return false;
                }
            }

            return true;
        }

        return false;
    }

    private static bool AreConntected(Point point1, Point point2)
    {
        Debug.Assert(!(point1.RowIdx == point2.RowIdx && point1.ColIdx == point2.ColIdx));
        Debug.Assert(point1.Value() == point2.Value());

        // check for horizontal connection
        if (point1.RowIdx == point2.RowIdx)
        {
            int fromCol = Math.Min(point1.ColIdx, point2.ColIdx);
            int toCol = Math.Max(point1.ColIdx, point2.ColIdx);

            for (int i = fromCol; i <= toCol; i++)
            {
                if (array[point1.RowIdx][i] != point1.Value())
                {
                    return false;
                }
            }

            return true;
        }

        // check for vertical connection
        if (point1.ColIdx == point2.ColIdx)
        {
            int fromRow = Math.Min(point1.RowIdx, point2.RowIdx);
            int toRow = Math.Max(point1.RowIdx, point2.RowIdx);

            for (int i = fromRow; i <= toRow; i++)
            {
                if (array[i][point1.ColIdx] != point1.Value())
                {
                    return false;
                }
            }

            return true;
        }

        return false;
    }

    public char Value()
    {
        return points.First().Value();
    }

    public bool Contains(Point point) => points.Contains(point);

    public bool Add(Point point)
    {
        if (points.Count >= 1 && point.Value() != Value())
        {
            throw new Exception($"Cannot add point with value = {point.Value()} to region with values = {Value()}.");
        }

        return points.Add(point);
    }
}

struct Point
{
    public int RowIdx { get; set; }

    public int ColIdx { get; set; }

    public readonly char Value() => array[RowIdx][ColIdx];

    public readonly override string ToString()
    {
        return $"({RowIdx}, {ColIdx})";
    }
}

static char[][] GetInput()
{
    var lines = File.ReadAllLines("./2024/day12/input.txt");
    return lines.Select(x => x.ToCharArray()).ToArray();
}


static IEnumerable<Point> GetNewPoints(Point point)
{
    // up
    if (0 <= point.RowIdx - 1)
    {
        yield return new Point { RowIdx = point.RowIdx - 1, ColIdx = point.ColIdx };
    }

    // down
    if (point.RowIdx + 1 < array.Length)
    {
        yield return new Point { RowIdx = point.RowIdx + 1, ColIdx = point.ColIdx };
    }

    // left
    if (0 <= point.ColIdx - 1)
    {
        yield return new Point { RowIdx = point.RowIdx, ColIdx = point.ColIdx - 1 };
    }

    // right
    if (point.ColIdx + 1 < array[point.RowIdx].Length)
    {
        yield return new Point { RowIdx = point.RowIdx, ColIdx = point.ColIdx + 1 };
    }
}


static Region ExploreRegion(Point startingPoint)
{
    var region = new Region();

    var points = new Queue<Point>([startingPoint]);

    while (points.TryDequeue(out var point))
    {
        if (region.Contains(point))
        {
            continue;
        }
        region.Add(point);

        foreach (var newPoint in GetNewPoints(point))
        {
            if (newPoint.Value() != point.Value())
            {
                continue;
            }
            points.Enqueue(newPoint);
        }
    }

    return region;
}

static var array = GetInput();

var regions = new List<Region>();

for (int i = 0; i < array.Length; i++)
{
    for (int j = 0; j < array.Length; j++)
    {
        var point = new Point { RowIdx = i, ColIdx = j };
        if (regions.Any(x => x.Contains(point)))
        {
            continue;
        }
        regions.Add(ExploreRegion(point));
    }
}

foreach (var region in regions)
{
    WriteLine($"{region.Value()}: {region.Area} * {region.Sides()} = {region.Fence}");
}

WriteLine($"Sum = {regions.Select(x => x.Fence).Sum()}")  // 839780