struct Point
{
    public int x;
    public int y;
    public readonly char Value() => array[x][y];

    public readonly override string ToString()
    {
        return $"({x}, {y})";
    }
}

static char[][] GetInput()
{
    var lines = File.ReadAllLines("./2024/day10/input.txt");
    return lines.Select(x => x.ToCharArray()).ToArray();
}

static IEnumerable<Point> GetNewPoints(Point point)
{
    // up
    if (0 <= point.x - 1)
    {
        yield return new Point { x = point.x - 1, y = point.y };
    }

    // down
    if (point.x + 1 < array.Length)
    {
        yield return new Point { x = point.x + 1, y = point.y };
    }

    // left
    if (0 <= point.y - 1)
    {
        yield return new Point { x = point.x, y = point.y - 1 };
    }

    // right
    if (point.y + 1 < array[point.x].Length)
    {
        yield return new Point { x = point.x, y = point.y + 1 };
    }
}

static void ExplorePath(Point point)
{
    Debug.Assert(point.Value() == START);

    var queue = new Queue<Point>([point]);

    while (queue.TryDequeue(out Point currPoint))
    {
        if (currPoint.Value() == END)
        {
            if (!scores.ContainsKey(currPoint))
            {
                scores.Add(currPoint, 0);
            }
            scores[currPoint] += 1;
        }
        else
        {
            foreach (var newPoint in GetNewPoints(currPoint))
            {
                if (newPoint.Value() == currPoint.Value() + 1)
                {
                    queue.Enqueue(newPoint);
                }
            }
        }
    }
}

static var scores = new Dictionary<Point, int>();

const char START = '0';
const char END = '9';

static char[][] array = GetInput();

for (int i = 0; i < array.Length; i++)
{
    for (int j = 0; j < array[i].Length; j++)
    {
        if (array[i][j] == START)
        {
            ExplorePath(new Point { x = i, y = j });
        }
    }
}

var score = scores.Values.Sum();

WriteLine($"Score = {score}");  // 1706