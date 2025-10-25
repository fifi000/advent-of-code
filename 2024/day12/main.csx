class Region
{
    public int Area { get; set; } = 0;
    public int Perimeter { get; set; } = 0;
    private readonly HashSet<Point> points = [];

    public int Fence => Area * Perimeter;

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

        Area++;

        // up
        if (point.RowIdx == 0 || array[point.RowIdx - 1][point.ColIdx] != point.Value())
        {
            Perimeter++;
        }

        // down
        if (point.RowIdx == array.Length - 1 || array[point.RowIdx + 1][point.ColIdx] != point.Value())
        {
            Perimeter++;
        }

        // left
        if (point.ColIdx == 0 || array[point.RowIdx][point.ColIdx - 1] != point.Value())
        {
            Perimeter++;
        }

        // right
        if (point.ColIdx == array[point.RowIdx].Length - 1 || array[point.RowIdx][point.ColIdx + 1] != point.Value())
        {
            Perimeter++;
        }

        return points.Add(point);
    }
}

struct Point
{
    public int RowIdx { get; set; }

    public int ColIdx { get; set; }

    public readonly char Value() => array[RowIdx][ColIdx];
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
    WriteLine($"{region.Value()}: {region.Area} * {region.Perimeter} = {region.Fence}");
}

WriteLine($"Sum = {regions.Select(x => x.Fence).Sum()}");

