using System.Collections;

class Node<T>
{
    public Node<T> Prev { get; set; }
    public Node<T> Next { get; set; }
    public T Value { get; set; }

    public long Count()
    {
        long counter = 0;
        var currNode = this;

        while (currNode != null)
        {
            counter++;
            currNode = currNode.Next;
        }

        return counter;
    }

    public void Print()
    {
        var values = GetAllValues().Order();

        WriteLine($"[{string.Join(", ", values)}]");
    }

    private IEnumerable<T> GetAllValues()
    {
        var currNode = this;

        while (currNode != null)
        {
            yield return currNode.Value;
            currNode = currNode.Next;
        }
    }

    public override string ToString()
    {
        return Value.ToString();
    }
}

static Node<T> CreateNodes<T>(IEnumerable<T> list)
{
    if (!list.Any())
    {
        return null;
    }

    var first = new Node<T> { Value = list.First() };
    var currNode = first;

    foreach (var value in list.Skip(1))
    {
        currNode.Next = new Node<T>
        {
            Prev = currNode,
            Value = value,
        };
        currNode = currNode.Next;
    }

    return first;
}

static long[] GetInput()
{
    var line = File.ReadAllText("./2024/day11/input.txt");

    Debug.Assert(!line.Contains('\n'));

    var nums = line.Trim().Split().Select(x => long.Parse(x)).ToArray();
    return nums;
}

static (long left, long right) SplitInt(long value)
{
    Debug.Assert(HasEvenDigits(value));

    long halfLength = GetLength(value) / 2;

    long right = 0;
    for (int i = 0; i < halfLength; i++)
    {
        right += (long)Math.Pow(10, i) * (value % 10);
        value /= 10;
    }

    long left = 0;
    for (int i = 0; i < halfLength; i++)
    {
        left += (long)Math.Pow(10, i) * (value % 10);
        value /= 10;
    }

    Debug.Assert(value == 0);

    return (left, right);
}

static int GetLength(long value)
{
    if (value == 0)
    {
        return 1;
    }
    return (int)Math.Floor(Math.Log10(value)) + 1;
}

static bool HasEvenDigits(long value)
{
    return GetLength(value) % 2 == 0;
}

static void BlinkEach(Node<long> node)
{
    var currNode = node;

    while (currNode != null)
    {
        if (currNode.Value == 0)
        {
            currNode.Value = 1;
        }
        else if (HasEvenDigits(currNode.Value))
        {
            (long leftVal, long rightVal) = SplitInt(currNode.Value);

            var leftNode = currNode;
            leftNode.Value = leftVal;

            var rightNode = new Node<long>
            {
                Prev = leftNode,
                Next = leftNode.Next,
                Value = rightVal,
            };
            leftNode.Next = rightNode;
            currNode = rightNode;
        }
        else
        {
            var before = currNode.Value;
            currNode.Value *= 2024;
            Debug.Assert(before < currNode.Value);
        }

        currNode = currNode.Next;
    }
}

var nums = GetInput();

var node = CreateNodes(nums);

for (int i = 0; i < 25; i++)
{
    WriteLine($"{i + 1}. Count = {node.Count()}");
    BlinkEach(node);
}

WriteLine($"Found: {node.Count()} nodes"); // 190865
