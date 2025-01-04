using System.Buffers;
using System.Collections.Concurrent;
using System.Numerics;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp.Syntax;

static ulong[] GetInput()
{
    var line = File.ReadAllText("./2024/day11/input.txt");

    Debug.Assert(!line.Contains('\n'));

    var nums = line.Trim().Split().Select(x => ulong.Parse(x)).ToArray();
    return nums;
}

static (ulong left, ulong right) SplitInt(ulong value)
{
    ulong halfLength = GetLength(value) / 2;

    ulong right = 0;
    for (uint i = 0; i < halfLength; i++)
    {
        right += (ulong)Math.Pow(10, i) * (value % 10);
        value /= 10;
    }

    ulong left = 0;
    for (uint i = 0; i < halfLength; i++)
    {
        left += (ulong)Math.Pow(10, i) * (value % 10);
        value /= 10;
    }

    return (left, right);
}

static ulong GetLength(ulong value)
{
    if (value == 0)
    {
        return 1;
    }
    return (ulong)Math.Floor(Math.Log10(value)) + 1;
}

static bool HasEvenDigits(ulong value)
{
    return GetLength(value) % 2 == 0;
}

static void Blink(Dictionary<ulong, ulong> counter)
{
    var copy = counter.Select(pair => (pair.Key, pair.Value)).ToArray();
    foreach ((var key, var count) in copy)
    {
        if (key == 0)
        {
            counter[key] -= count;
            TryAdd(1, count);
        }
        else if (HasEvenDigits(key))
        {
            (ulong leftVal, ulong rightVal) = SplitInt(key);
            counter[key] -= count;

            TryAdd(leftVal, count);
            TryAdd(rightVal, count);
        }
        else
        {
            counter[key] -= count;
            TryAdd(key * 2024, count);
        }
    }

    void TryAdd(ulong key, ulong value)
    {
        if (!counter.ContainsKey(key))
        {
            counter[key] = 0;
        }
        counter[key] += value;
    }
}

var nums = GetInput();

var counter = nums.GroupBy(x => x).ToDictionary(x => x.Key, x => (ulong)x.Count());

for (int i = 0; i < 75; i++)
{
    WriteLine($"{i + 1}. Count = {counter.Values.Aggregate((acc, val) => acc + val)}");
    Blink(counter);
}

WriteLine($"Found: {counter.Values.Aggregate((acc, val) => acc + val)}"); // 225404711855335
