import std.algorithm;
import std.container;
import std.range;
import std.stdio;
import std.conv;
import std.format;
import std.regex;
import std.experimental.logger;

struct Interval
{
    private
    {
        int _begin;
        int _end;
    }

    @property int begin() const { return _begin; }
    @property void begin(int begin) { _begin = begin; }
    @property int end() const { return _end; }
    @property void end(int end) { _end = end; }
    @property int length() const { return end-begin+1; }

    invariant
    {
        assert(_begin <= _end, format!"Invalid interval: %d <= %d is false"(_begin, _end));
    }

    this(int value)
    {
        _begin = _end = value;
    }

    this(int begin, int end)
    {
        _begin = begin;
        _end = end;
    }

    this(Interval i)
    {
        _begin = i.begin;
        _end = i.end;
    }

    int opCmp(ref const Interval oth) const
    {
        if (begin == oth.begin)
            return end - oth.end;
        else
            return begin - oth.begin;
    }

    int opCmp(ref const int value) const
    {
        return begin - value;
    }

    bool opEquals()(auto ref const Interval oth) const
    {
        return (begin == oth.begin) && (end == oth.end);
    }

    bool opBinaryRight(string op)(in int value) const
        if (op == "in")
    {
        return (value >= begin) && (value <= end);
    }
    bool opBinaryRight(string op)(in Interval oth) const
        if (op == "in")
    {
        return (oth.begin >= begin) && (oth.end <= end);
    }

    string toString() const
    {
        if (begin == end)
            return format!"[%d]"(begin);
        else
            return format!"[%d,%d]"(begin,end);
    }

    string to_string_protocol() const
    {
        if (begin == end)
            return format!"%d"(begin);
        else
            return format!"%d-%d"(begin,end);
    }

    // Properties tests
    unittest
    {
        Interval i = Interval(1);
        assert(i.begin == 1, format!"[1].begin %d!=1"(i.begin));
        assert(i.end == 1, format!"[1].end %d!=1"(i.end));
        assert(i.length == 1, format!"[1] of length %d!=1"(i.length));

        i = Interval(404, 404);
        assert(i.begin == 404, format!"[404,404].begin %d!=404"(i.begin));
        assert(i.end == 404, format!"[404,404].end %d!=404"(i.end));
        assert(i.length == 1, format!"[404,404] of length %d!=1"(i.length));

        i = Interval(40, 41);
        assert(i.begin == 40, format!"[40,41].begin %d!=40"(i.begin));
        assert(i.end == 41, format!"[40,41].end %d!=41"(i.end));
        assert(i.length == 2, format!"[40,41] of length %d!=2"(i.length));

        i = Interval(101, 103);
        assert(i.begin == 101, format!"[101,103].begin %d!=101"(i.begin));
        assert(i.end == 103, format!"[101,103].end %d!=103"(i.end));
        assert(i.length == 3, format!"[101,103] of length %d!=3"(i.length));
    }
    // number in Interval tests
    unittest
    {
        Interval a = Interval(42);
        assert(42 in a, "42 should be in [42]");
        assert(!(41 in a), "41 should NOT be in [42]");
        assert(!(43 in a), "43 should NOT be in [42]");

        a = Interval(42,44);
        assert(42 in a, "42 should be in [42,44]");
        assert(43 in a, "43 should be in [42,44]");
        assert(44 in a, "44 should be in [42,44]");
        assert(!(41 in a), "41 should NOT be in [42,44]");
        assert(!(45 in a), "45 should NOT be in [42,44]");
    }
    // Interval in Interval tests
    unittest
    {
        auto a = Interval(42);
        auto b = Interval(42);
        auto c = Interval(43);

        assert(a in a, "[42] should be in itself");
        assert(a in b, "[42] should be in [42]");
        assert(!(a in c), "[42] should NOT be in [43]");
        assert(!(c in a), "[43] should NOT be in [42]");

        b = Interval(42,43);
        assert(b in b, "[42,43] should be in itself");
        assert(a in b, "[42] should be in [42,43]");
        assert(c in b, "[43] should be in [42,43]");

        b = Interval(10,42);
        assert(a in b, "[42] should be in [10,42]");
        assert(!(c in b), "[43] should NOT be in [10,42]");

        b = Interval(43,50);
        assert(!(a in b), "[42] should NOT be in [43,50]");
        assert(c in b, "[43] should be in [43,50]");
    }
    // Equals tests
    unittest
    {
        Interval a = Interval(42);
        Interval b = Interval(42,42);
        Interval c = Interval(42,43);
        Interval d = Interval(42,43);
        Interval e = Interval(43);

        assert(a == a, "[42] should equal itself");
        assert(c == c, "[42,43] should equal itself");

        assert(a == b, "[42] should equal [42,42]");
        assert(b == a, "[42,42] should equal [42]");

        assert(c == d, "[42,43] should equal [42,43]");
        assert(d == c, "[42,43] should equal [42,43]");

        assert(a != c, "[42] should NOT equal [42,43]");
        assert(c != a, "[42,43] should NOT equal [42]");
        assert(a != e, "[42] should NOT equal [43]");
        assert(e != a, "[43] should NOT equal [42]");
    }
    // Comparison tests
    unittest
    {
        // Autocomparison
        auto a = Interval(42);
        auto b = Interval(42,43);

        assert(a <= a, "[42] should be lesser than or equal to itself");
        assert(a >= a, "[42] should be greater than or equal to itself");
        assert(b <= b, "[42,43] should be lesser than or equal to itself");
        assert(b >= b, "[42,43] should be greater than or equal to itself");

        // Singletons
        a = Interval(42);
        b = Interval(43);

        assert(a < b, "[42] should be lesser than [43]");
        assert(a <= b, "[42] should be lesser than or equal to [43]");
        assert(b > a, "[43] should be greater than [42]");
        assert(b >= a, "[43] should be greater than or equal to [42]");

        // singleton, interval (empty intersection)
        a = Interval(42);
        b = Interval(43, 50);

        assert(a < b, "[42] should be lesser than [42,43]");
        assert(a <= b, "[42] should be lesser than or equal to [42,43]");
        assert(b > a, "[42,43] should be greater than [42]");
        assert(b >= a, "[42,43] should be greater than or equal to [42]");

        // interval, singleton (empty intersection)
        a = Interval(10,42);
        b = Interval(43);

        assert(a < b, "[10,42] should be lesser than [43]");
        assert(a <= b, "[10,42] should be lesser than or equal to [43]");
        assert(b > a, "[43] should be greater than [10,42]");
        assert(b >= a, "[43] should be greater than or equal to [10,42]");

        // singleton, interval (non-empty intersection)
        a = Interval(42);
        b = Interval(42,50);

        assert(a < b, "[42] should be lesser than [42,50]");
        assert(a <= b, "[42] should be lesser than or equal to [42,50]");
        assert(b > a, "[42,50] should be greater than [42]");
        assert(b >= a, "[42,50] should be greater than or equal to [42]");

        a = Interval(43);
        assert(a > b, "[43] should be greater than [42,50]");
        assert(a >= b, "[43] should be greater than or equal to [42,50]");
        assert(b < a, "[42,50] should be lesser than [43]");
        assert(b <= a, "[42,50] should be lesser than or equal to [43]");

        a = Interval(50);
        assert(a > b, "[50] should be greater than [42,50]");
        assert(a >= b, "[50] should be greater than or equal to [42,50]");
        assert(b < a, "[42,50] should be lesser than [50]");
        assert(b <= a, "[42,50] should be lesser than or equal to [50]");

        // Now let's have fun with interval, interval!
        // a : ---
        // b :     ---
        a = Interval(10,42);
        b = Interval(43,50);

        assert(a < b, "[10,42] should be lesser than [43,50]");
        assert(a <= b, "[10,42] should be lesser than or equal to [43,50]");
        assert(b > a, "[43,50] should be greater than [10,42]");
        assert(b >= a, "[43,50] should be greater than or equal to [10,42]");

        // a : ---
        // b : -----
        a = Interval(42, 45);
        b = Interval(42, 50);
        assert(a < b, "[42,45] should be lesser than [42,50]");
        assert(a <= b, "[42,45] should be lesser than or equal to [42,50]");
        assert(b > a, "[42,50] should be greater than [42,45]");
        assert(b >= a, "[42,50] should be greater than or equal to [42,45]");

        // a : -----
        // b :   ---
        a = Interval(50,60);
        b = Interval(55,60);
        assert(a < b, "[50,60] should be lesser than [55,60]");
        assert(a <= b, "[50,60] should be lesser than or equal to [55,60]");
        assert(b > a, "[55,60] should be greater than [50,60]");
        assert(b >= a, "[55,60] should be greater than or equal to [50,60]");

        // a : ---
        // b :  ----
        a = Interval(10,20);
        b = Interval(15,25);
        assert(a < b, "[10,20] should be lesser than [15,25]");
        assert(a <= b, "[10,20] should be lesser than or equal to [15,25]");
        assert(b > a, "[15,25] should be greater than [10,20]");
        assert(b >= a, "[15,25] should be greater than or equal to [10,20]");

        // a : ---
        // b :   ---
        a = Interval(1000,2000);
        b = Interval(2000,3000);
        assert(a < b, "[1000,2000] should be lesser than [2000,3000]");
        assert(a <= b, "[1000,2000] should be lesser than or equal to [2000,3000]");
        assert(b > a, "[2000,3000] should be greater than [1000,2000]");
        assert(b >= a, "[2000,3000] should be greater than or equal to [1000,2000]");

        // a : -----
        // b :  ---
        a = Interval(100,200);
        b = Interval(125,175);
        assert(a < b, "[100,200] should be lesser than [125,175]");
        assert(a <= b, "[100,200] should be lesser than or equal to [125,175]");
        assert(b > a, "[125,175] should be greater than [100,200]");
        assert(b >= a, "[125,175] should be greater than or equal to [100,200]");
    }
}


struct IntervalSet
{
    private
    {
        Interval[] _intervals;
    }

    @property size_t nb_intervals() const { return _intervals.length; }
    @property int nb_elements() const
    {
        if (nb_intervals == 0)
            return 0;
        else
            return _intervals.map!(a => a.length).fold!((a,b) => a+b);
    }

    invariant
    {
        for (int i = 1; i < _intervals.length; ++i)
        {
            assert(_intervals[i-1].begin < _intervals[i].begin,
                   format!"Invalid IntervalSet: [%d,%d] cannot follow [%d,%d]: Unsorted"
                   (_intervals[i-1].begin, _intervals[i-1].end,
                    _intervals[i].begin, _intervals[i].end));

            assert(_intervals[i-1].end < _intervals[i].begin - 1,
                   format!"Invalid IntervalSet: [%d,%d] cannot follow [%d,%d]: Non-optimal"
                   (_intervals[i-1].begin, _intervals[i-1].end,
                    _intervals[i].begin, _intervals[i].end));
        }
        assert(_intervals.isSorted, "Invalid IntervalSet: not sorted!");
    }

    this(in Interval i)
    {
        _intervals = [Interval(i.begin, i.end)];
    }
    this(in Interval[] intervals)
    {
        _intervals = intervals.dup;
    }
    this(in int value)
    {
        _intervals = [Interval(value)];
    }
    this(in int begin, in int end)
    {
        _intervals = [Interval(begin, end)];
    }
    this(in IntervalSet oth)
    {
        _intervals.length = oth.nb_intervals;
        for (auto i = 0; i < oth.nb_intervals; ++i)
            _intervals[i] = Interval(oth._intervals[i].begin,
                                     oth._intervals[i].end);
    }

    this(in string input,
         in string sep = " ",
         in string joiner = "-")
    {
        foreach(s; splitter(input, sep))
        {
            if (!s.empty)
            {
                auto m = matchFirst(s, regex(`\s*(\d+)-(\d+)\s*`));
                if (!m.empty)
                {
                    int begin = to!int(m[1]);
                    int end = to!int(m[2]);
                    assert(begin <= end, format!"Invalid interval: %d <= %d is false. input='%s', sep='%s', joiner='%s'"(begin, end, input, sep, joiner));
                    _intervals ~= Interval(begin, end);
                }
                else
                {
                    m = matchFirst(s, regex(`\s*(\d+)\s*`));
                    if (!m.empty)
                    {
                        int value = to!int(m[1]);
                        _intervals ~= Interval(value);
                    }
                    else
                        assert(0, format!"Invalid interval string '%s' (input='%s', sep='%s', joiner='%s')"(s, input, sep, joiner));
                }
            }
        }

        // Even if the intervals are syntaxically valid, they might
        // be non-optimal (e.g. {[1,2], [3,4], [5,6], ...})
        // or even with intersecting parts (e.g. {[1,4], [3,6]}).
        _intervals = compressed(_intervals);
    }

    ref IntervalSet opAssign(in IntervalSet oth)
    {
        _intervals.length = oth._intervals.length;
        _intervals[] = oth._intervals;
        return this;
    }

    string toString() const
    {
        return "{" ~ to!string(_intervals.map!("a.toString").joiner(" ")) ~ "}";
    }

    string to_string_protocol() const
    {
        return to!string(_intervals.map!("a.to_string_protocol").joiner(" "));
    }

    void clear()
    {
        _intervals.length = 0;
    }

    IntervalSet left(int nb) const
    out(result)
    {
        assert(result.nb_elements == nb,
               format!"Invalid left result (nb_elem=%d instead of %d)"
               (result.nb_elements, nb));
    }
    body
    {
        IntervalSet res;
        int nb_added = 0;

        auto r = assumeSorted(_intervals);

        while (!r.empty && nb_added < nb)
        {
            int nb_to_add = min(r.front.length, nb - nb_added);
            res._intervals ~= Interval(r.front.begin, r.front.begin + nb_to_add - 1);
            nb_added += nb_to_add;
            r.popFront;
        }

        assert(nb_added == nb,
               format!"Cannot take the %d leftmost values of %s: too small (nb_elem=%d)"
               (nb, this, nb_elements));
        return res;
    }

    static Interval[] compressed(in Interval[] input)
    {
        Interval[] intervals, input_copy;

        input_copy = input.dup;
        input_copy.sort();

        bool opened = false;
        Interval interval;

        foreach(i; input_copy)
        {
            if (!opened)
            {
                opened = true;
                interval = i;
            }
            else
            {
                if (i.begin <= interval.end + 1)
                    interval.end = max(interval.end, i.end);
                else
                {
                    intervals ~= interval;
                    interval = i;
                }
            }
        }

        if (opened)
            intervals ~= interval;

        return intervals;
    }

    void opOpAssign(string op)(in IntervalSet oth)
    {
        static if (op == "|")
        {
            this = this | oth;
        }
        else static if (op == "&")
        {
            this = this & oth;
        }
        else static if (op == "-")
        {
            this = this - oth;
        }
        else static assert(0, "Operator " ~ op ~ " not implemented");
    }

    IntervalSet opBinary(string op)(in IntervalSet oth) const
        if (op == "|")
    {
        return IntervalSet(compressed(_intervals ~ oth._intervals));
    }

    IntervalSet opBinary(string op)(in IntervalSet oth) const
        if (op == "&")
    {
        Interval[] result;

        auto setA = assumeSorted(oth._intervals);
        auto setB = assumeSorted(_intervals);

        while (!setA.empty && !setB.empty)
        {
            auto a = setA.front;
            auto b = setB.front;

            // If intervals have no intersection, the leftmost one is popped.
            if (b.begin > a.end)
                setA.popFront;
            else if (a.begin > b.end)
                setB.popFront;
            else
            {
                // Intervals are intersecting!
                result ~= Interval(max(a.begin, b.begin),
                                   min(a.end, b.end));

                if (a.begin <= b.begin)
                    setA.popFront;
                else
                    setB.popFront;
            }
        }

        return IntervalSet(compressed(result));
    }

    IntervalSet opBinary(string op)(in IntervalSet oth) const
        if (op == "-")
    {
        Interval[] result;

        // We are computing setA - setB
        auto setA = assumeSorted(_intervals);
        auto setB = assumeSorted(oth._intervals);

        while (!setA.empty)
        {
            auto a = setA.front;

            if (setB.empty)
            {
                // B is empty. Remaining intervals in A are in the result.
                result ~= a;

                setA.popFront;

                while (!setA.empty)
                {
                    result ~= setA.front;
                    setA.popFront;
                }
            }
            else
            {
                auto b = setB.front;

                if (b.begin > a.end)
                {
                    // B is strictly after A.
                    // A can entirely be added entirely into the result.
                    result ~= a;
                    setA.popFront;
                }
                else if (a.begin > b.end)
                {
                    // A is strictly after B.
                    // The B part cannot intersect with the current A part nor
                    // with any of the next parts, it can thus be popped.
                    setB.popFront;
                }
                else
                {
                    // Intervals are intersecting!
                    // Let's traverse setB until we are sure the current A part
                    // has been fully handled
                    bool a_handled = false;
                    Interval remaining_a = a;

                    while (!setB.empty && !a_handled)
                    {
                        // B starts strictly after A. Thus the first part of A
                        // (before B) may be added into the result
                        if (setB.front.begin > remaining_a.begin)
                        {
                            result ~= Interval(remaining_a.begin,
                                                min(remaining_a.end,
                                                    setB.front.begin-1));
                        }

                        // If something will remain in remainingA
                        if (remaining_a.end > setB.front.end)
                        {
                            // Remaining_a update.
                            remaining_a.begin = setB.front.end+1;

                            // The B part cannot intersect with next A parts
                            // since it ends strictly before the current A part
                            setB.popFront;
                        }
                        else
                        {
                            a_handled = true;
                        }
                    }

                    if (!a_handled)
                    {
                        result ~= Interval(remaining_a.begin,
                                           remaining_a.end);
                    }

                    setA.popFront;
                }
            }
        }

        return IntervalSet(compressed(result));
    }

    bool opBinaryRight(string op)(in int value) const
        if (op == "in")
    {
        foreach (i; _intervals)
        {
            if (value in i)
                return true;
            else if (value < i)
                return false;
        }

        return false;
    }
    bool opBinaryRight(string op)(in Interval interval) const
        if (op == "in")
    {
        foreach (i; _intervals)
        {
            if (interval in i)
                return true;
            else if (interval < i)
                return false;
        }

        return false;
    }
    bool opBinaryRight(string op)(in IntervalSet oth) const
        if (op == "in")
    {
        auto subset = assumeSorted(oth._intervals);
        auto superset = assumeSorted(_intervals);

        while (!subset.empty)
        {
            auto subset_interval = subset.front;

            if (superset.empty)
                return false;
            else
            {
                auto superset_interval = superset.front;

                if (subset_interval in superset_interval)
                    subset.popFront;
                else if (subset_interval < superset_interval)
                    return false;
                else
                    superset.popFront;
            }
        }

        return true;
    }

    bool opEquals()(auto ref const IntervalSet oth) const
    {
        if (nb_intervals != oth.nb_intervals)
            return false;
        for (auto i = 0; i < nb_intervals; ++i)
            if (_intervals[i] != oth._intervals[i])
                return false;
        return true;
    }

    // basic tests
    unittest
    {
        IntervalSet a, b, c;

        assert(a == a, "{} should equal itself");
        assert(a == b, "{} should equal {}");
        assert(a.nb_intervals == 0);
        assert(a.nb_elements == 0);

        a = IntervalSet(10,20);
        b = IntervalSet("10-20");
        assert(a == b, "[10,20] should equal 10-20");
        assert(a.nb_intervals == 1);
        assert(a.nb_elements == 11);

        a = IntervalSet([Interval(10,20), Interval(40,50), Interval(70,80)]);
        b = IntervalSet("10-20 40-50 70-80");
        assert(a == b, "{[10,20], [40,50], [70,80]} should equal 10-20 40-50 70-80");
        assert(a.nb_intervals == 3);
        assert(a.nb_elements == 11*3);

        for (int i = 0; i < 100; ++i)
        {
            if ((i >= 10 && i <= 20) ||
                (i >= 40 && i <= 50) ||
                (i >= 70 && i <= 80))
            {
                assert(i in a, format!"%d should be in %s"(i,a));
                assert(i in b, format!"%d should be in %s"(i,b));
            }
            else
            {
                assert(!(i in a), format!"%d should NOT be in %s"(i,a));
                assert(!(i in b), format!"%d should NOT be in %s"(i,b));
            }
        }
    }
    // union test
    unittest
    {
        IntervalSet a, b, res;
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));

        // a: -
        // b:   -
        a = IntervalSet(42);
        b = IntervalSet(51);
        res = IntervalSet("42 51");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));

        // a: ---
        // b:    ---
        a = IntervalSet(10, 20);
        b = IntervalSet(21, 30);
        res = IntervalSet("10-30");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));

        // a: ---
        // b:   ---
        a = IntervalSet(10, 20);
        b = IntervalSet(20, 30);
        res = IntervalSet("10-30");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));

        // a: ---
        // b:     ---
        a = IntervalSet(42, 51);
        b = IntervalSet(100, 200);
        res = IntervalSet("42-51 100-200");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));

        // a: -------
        // b:   ---
        a = IntervalSet(10, 100);
        b = IntervalSet(50, 60);
        res = IntervalSet("10-100");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));

        // a: -----
        // b:    -----
        a = IntervalSet(10, 20);
        b = IntervalSet(15, 25);
        res = IntervalSet("10-25");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));

        // a: -----
        // b:     --
        a = IntervalSet(10, 20);
        b = IntervalSet(20, 25);
        res = IntervalSet("10-25");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));

        // a: ---
        // b:  --- ---
        a = IntervalSet("5-15");
        b = IntervalSet("10-20 30-40");
        res = IntervalSet("5-20 30-40");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));

        // a:  ---
        // b: ---  ---
        a = IntervalSet("15-25");
        b = IntervalSet("10-20 30-40");
        res = IntervalSet("10-25 30-40");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));

        // a:   ---
        // b: --- ---
        a = IntervalSet("20-30");
        b = IntervalSet("10-20 30-40");
        res = IntervalSet("10-40");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));

        // a:     ---
        // b: ---  ---
        a = IntervalSet("25-35");
        b = IntervalSet("10-20 30-40");
        res = IntervalSet("10-20 25-40");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));

        // a:       ---
        // b: ---  ---
        a = IntervalSet("35-45");
        b = IntervalSet("10-20 30-40");
        res = IntervalSet("10-20 30-45");
        assert((a | b) == res, format!"%s|%s != %s"(a,b,res));
        assert((a | b) == (b | a), format!"%s|%s != %s|%s"(a,b,b,a));
    }
    // intersection test
    unittest
    {
        // intersections with empty should always return empty
        IntervalSet a, b, res;
        immutable IntervalSet empty;
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));

        a = IntervalSet();
        b = IntervalSet(42);
        assert((a & b) == empty, format!"%s&%s != %s"(a,b,empty));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        a = IntervalSet();
        b = IntervalSet("41-51");
        assert((a & b) == empty, format!"%s&%s != %s"(a,b,empty));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        a = IntervalSet();
        b = IntervalSet("36 42-51 100-115");
        assert((a & b) == empty, format!"%s&%s != %s"(a,b,empty));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a: -
        // b:   -
        a = IntervalSet(42);
        b = IntervalSet(51);
        res = IntervalSet();
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a: ---
        // b:    ---
        a = IntervalSet(10, 20);
        b = IntervalSet(21, 30);
        res = IntervalSet();
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a: ---
        // b:   ---
        a = IntervalSet(10, 20);
        b = IntervalSet(20, 30);
        res = IntervalSet("20");
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a: ---
        // b:     ---
        a = IntervalSet(42, 51);
        b = IntervalSet(100, 200);
        res = IntervalSet();
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a: -------
        // b:   ---
        a = IntervalSet(10, 100);
        b = IntervalSet(50, 60);
        res = IntervalSet("50-60");
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a: -----
        // b:    -----
        a = IntervalSet(10, 20);
        b = IntervalSet(15, 25);
        res = IntervalSet("15-20");
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a: -----
        // b:     --
        a = IntervalSet(10, 20);
        b = IntervalSet(20, 25);
        res = IntervalSet("20");
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a: ---
        // b:  --- ---
        a = IntervalSet("5-15");
        b = IntervalSet("10-20 30-40");
        res = IntervalSet("10-15");
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a:  ---
        // b: ---  ---
        a = IntervalSet("15-25");
        b = IntervalSet("10-20 30-40");
        res = IntervalSet("15-20");
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a:   ---
        // b: --- ---
        a = IntervalSet("20-30");
        b = IntervalSet("10-20 30-40");
        res = IntervalSet("20 30");
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a:     ---
        // b: ---  ---
        a = IntervalSet("25-35");
        b = IntervalSet("10-20 30-40");
        res = IntervalSet("30-35");
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));

        // a:       ---
        // b: ---  ---
        a = IntervalSet("35-45");
        b = IntervalSet("10-20 30-40");
        res = IntervalSet("35-40");
        assert((a & b) == res, format!"%s&%s != %s"(a,b,res));
        assert((a & b) == (b & a), format!"%s&%s != %s&%s"(a,b,b,a));
    }
    // difference test
    unittest
    {
        IntervalSet a, b, res1, res2;
        immutable IntervalSet empty;
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        a = IntervalSet();
        b = IntervalSet(42);
        res1 = empty;
        res2 = b;
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        a = IntervalSet();
        b = IntervalSet("41-51");
        res1 = empty;
        res2 = b;
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        a = IntervalSet();
        b = IntervalSet("36 42-51 100-115");
        res1 = empty;
        res2 = b;
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a: -
        // b:   -
        a = IntervalSet(42);
        b = IntervalSet(51);
        res1 = a;
        res2 = b;
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a: ---
        // b:    ---
        a = IntervalSet(10, 20);
        b = IntervalSet(21, 30);
        res1 = a;
        res2 = b;
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a: ---
        // b:   ---
        a = IntervalSet(10, 20);
        b = IntervalSet(20, 30);
        res1 = IntervalSet("10-19");
        res2 = IntervalSet("21-30");
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a: ---
        // b:     ---
        a = IntervalSet(42, 51);
        b = IntervalSet(100, 200);
        res1 = a;
        res2 = b;
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a: -------
        // b:   ---
        a = IntervalSet(10, 100);
        b = IntervalSet(50, 60);
        res1 = IntervalSet("10-49 61-100");
        res2 = empty;
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a: -----
        // b:    -----
        a = IntervalSet(10, 20);
        b = IntervalSet(15, 25);
        res1 = IntervalSet("10-14");
        res2 = IntervalSet("21-25");
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a: -----
        // b:     --
        a = IntervalSet(10, 20);
        b = IntervalSet(20, 25);
        res1 = IntervalSet("10-19");
        res2 = IntervalSet("21-25");
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a: ---
        // b:  --- ---
        a = IntervalSet("5-15");
        b = IntervalSet("10-20 30-40");
        res1 = IntervalSet("5-9");
        res2 = IntervalSet("16-20 30-40");
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a:  ---
        // b: ---  ---
        a = IntervalSet("15-25");
        b = IntervalSet("10-20 30-40");
        res1 = IntervalSet("21-25");
        res2 = IntervalSet("10-14 30-40");
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a:   ---
        // b: --- ---
        a = IntervalSet("20-30");
        b = IntervalSet("10-20 30-40");
        res1 = IntervalSet("21-29");
        res2 = IntervalSet("10-19 31-40");
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a:     ---
        // b: ---  ---
        a = IntervalSet("25-35");
        b = IntervalSet("10-20 30-40");
        res1 = IntervalSet("25-29");
        res2 = IntervalSet("10-20 36-40");
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));

        // a:       ---
        // b: ---  ---
        a = IntervalSet("35-45");
        b = IntervalSet("10-20 30-40");
        res1 = IntervalSet("41-45");
        res2 = IntervalSet("10-20 30-34");
        assert((a - b) == res1, format!"%s-%s != %s"(a,b,res1));
        assert((b - a) == res2, format!"%s-%s != %s"(b,a,res2));
        assert((a - empty) == a, format!"%s-%s != %s"(a,empty,a));
        assert((b - empty) == b, format!"%s-%s != %s"(b,empty,b));
    }
    // is subset (Interval in IntervalSet)
    unittest
    {
        // a: -
        // b: -
        Interval a = Interval(42);
        IntervalSet b = IntervalSet("42");
        assert(a in b, format!"%s NOT in %s"(a,b));

        // a: -
        // b:   -
        a = Interval(42);
        b = IntervalSet("51");
        assert(!(a in b), format!"%s in %s"(a,b));

        // a:  -
        // b: ---
        a = Interval(42);
        b = IntervalSet("40-50");
        assert(a in b, format!"%s NOT in %s"(a,b));

        // a:  --
        // b: ----
        a = Interval(42,45);
        b = IntervalSet("40-50");
        assert(a in b, format!"%s NOT in %s"(a,b));

        // a:  --
        // b: ---- ---
        a = Interval(42,45);
        b = IntervalSet("40-50 60-70");
        assert(a in b, format!"%s NOT in %s"(a,b));

        // a:       --
        // b: ---- ---
        a = Interval(65,70);
        b = IntervalSet("40-50 60-70");
        assert(a in b, format!"%s NOT in %s"(a,b));

        // a: ---
        // b:  ---
        a = Interval(40,50);
        b = IntervalSet("45-55");
        assert(!(a in b), format!"%s in %s"(a,b));

        // a:  ---
        // b: ---
        a = Interval(45,55);
        b = IntervalSet("40-50");
        assert(!(a in b), format!"%s in %s"(a,b));
    }
    // is subset (IntervalSet in IntervalSet)
    unittest
    {
        IntervalSet a, b;
        assert(a in b, format!"%s NOT in %s"(a,b));

        // Empty set in various sets
        a = IntervalSet();
        b = IntervalSet(42);
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(b,a));

        a = IntervalSet();
        b = IntervalSet("40-50");
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(b,a));

        a = IntervalSet();
        b = IntervalSet("40-50 100-150");
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(b,a));

        // Singleton in various sets
        a = IntervalSet(42);
        b = IntervalSet(42);
        assert(a in b, format!"%s NOT in %s"(a,b));

        a = IntervalSet(42);
        b = IntervalSet("40-50");
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(b,a));

        a = IntervalSet(42);
        b = IntervalSet("40-50 100-150");
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(b,a));

        // Interval in various sets
        a = IntervalSet("42-45");
        b = IntervalSet(42);
        assert(!(a in b), format!"%s in %s"(a,b));

        a = IntervalSet("42-45");
        b = IntervalSet("40-50");
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(b,a));

        a = IntervalSet("42-45");
        b = IntervalSet("40-50 100-150");
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(b,a));

        // IntervalSet in IntervalSet
        // a: ---
        // b: ---
        a = IntervalSet("10-20");
        b = IntervalSet("10-20");
        assert(a in b, format!"%s NOT in %s"(a,b));

        // a: ---
        // b:  ---
        a = IntervalSet("10-20");
        b = IntervalSet("15-25");
        assert(!(a in b), format!"%s in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(a,b));

        // a: ---
        // b: --- ---
        a = IntervalSet("10-20");
        b = IntervalSet("10-20 50-60");
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(a,b));

        // a:     ---
        // b: --- ---
        a = IntervalSet("50-60");
        b = IntervalSet("10-20 50-60");
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(a,b));

        // a:  -
        // b: --- ---
        a = IntervalSet("14-16");
        b = IntervalSet("10-20 50-60");
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(a,b));

        // a:      -
        // b: --- ---
        a = IntervalSet("54-56");
        b = IntervalSet("10-20 50-60");
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(a,b));

        // a: -    -    - ---
        // b: --- --- --- ---
        a = IntervalSet("10 35 60 70-80");
        b = IntervalSet("10-20 30-40 50-60 70-80");
        assert(a in b, format!"%s NOT in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(a,b));

        // a: ---
        // b:  --- ---
        a = IntervalSet("5-15");
        b = IntervalSet("10-20 30-40");
        assert(!(a in b), format!"%s in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(a,b));

        // a:  ---
        // b: ---  ---
        a = IntervalSet("15-25");
        b = IntervalSet("10-20 30-40");
        assert(!(a in b), format!"%s in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(a,b));

        // a:   ---
        // b: --- ---
        a = IntervalSet("20-30");
        b = IntervalSet("10-20 30-40");
        assert(!(a in b), format!"%s in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(a,b));

        // a:     ---
        // b: ---  ---
        a = IntervalSet("25-35");
        b = IntervalSet("10-20 30-40");
        assert(!(a in b), format!"%s in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(a,b));

        // a:       ---
        // b: ---  ---
        a = IntervalSet("35-45");
        b = IntervalSet("10-20 30-40");
        assert(!(a in b), format!"%s in %s"(a,b));
        assert(!(b in a), format!"%s in %s"(a,b));
    }
}
