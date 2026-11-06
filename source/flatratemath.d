/**
 * FlatrateMath: subscription-vs-hire arithmetic for flat-rate dev
 * subscriptions. Pure Phobos, no dependencies, no I/O. All money is
 * integer cents; ledger renders rounded to the nearest dollar.
 *
 * Every figure in the doctests reproduces the worked example from the
 * README: a senior US software engineer at about $18,290/month fully
 * loaded (35% benefits, 15% payroll tax, 15% bonus, 8% retirement on a
 * $10,572.25 base) against a $5,995/month flat subscription with a
 * $13,500 one-time hiring cost.
 */
module flatratemath;

import std.conv : to;
import std.format : format;
import std.algorithm.sorting : sort;

/// Divide with round-half-up on non-negative operands.
long divRoundHalfUp(long a, long b) pure @safe nothrow
{
    return (a + b / 2) / b;
}

/// A billing cadence for a flat-rate plan.
struct Plan
{
    string name;        /// plan label
    long monthlyCents;  /// per-month rate in cents
    long upfrontCents;  /// one-time start fee in cents
    int monthsPerBill;  /// billing cadence (1, 3, 12)
}

/// The on-payroll side: burden stack in basis points applied
/// multiplicatively to a base salary, plus the one-time hiring cost.
struct HireLoad
{
    long baseCents;     /// base salary per month in cents
    int[] stackBps;     /// e.g. [3500, 1500, 1500, 800]
    long upfrontCents;  /// one-time hiring cost in cents

    /// Fully loaded monthly cost: base times the multiplicative stack,
    /// rounded half-up to the cent.
    long loadedCents() const pure @safe nothrow
    {
        long multBps = 10_000;
        foreach (s; stackBps) multBps += s;
        return divRoundHalfUp(baseCents * multBps, 10_000);
    }
}

/// First-year cost of a plan: every bill in 12 months plus upfront.
long firstYearCost(Plan p) pure @safe nothrow
{
    return p.monthlyCents * 12 + p.upfrontCents;
}

/// First-year delta of plan vs hire: what the subscription saves in
/// year one, counting both one-time costs.
long firstYearDelta(Plan p, HireLoad h) pure @safe nothrow
{
    return h.loadedCents * 12 + h.upfrontCents - firstYearCost(p);
}

/// Steady-state yearly delta once both one-time costs are sunk.
long steadyYearDelta(Plan p, HireLoad h) pure @safe nothrow
{
    return h.loadedCents * 12 - p.monthlyCents * 12;
}

/// Plans sorted by first-year delta, best first.
Plan[] rankByFirstYear(Plan[] plans, HireLoad h) pure @safe
{
    auto copy = plans.dup;
    copy.sort!((a, b) => firstYearDelta(a, h) > firstYearDelta(b, h));
    return copy;
}

/// Render cents as a ledger string rounded to the nearest dollar,
/// e.g. 14753988 -> "$147,540".
string ledger(long cents) pure @safe
{
    long sign = cents < 0 ? -1 : 1;
    long absCents = cents * sign;
    long dollars = divRoundHalfUp(absCents, 100);
    string digits = dollars.to!string;
    string grouped;
    for (size_t i = 0; i < digits.length; i++) {
        if (i > 0 && (digits.length - i) % 3 == 0) grouped ~= ',';
        grouped ~= digits[i];
    }
    return format!("%s$%s")(sign < 0 ? "-" : "", grouped);
}

version (FlatrateMathDemo)
void main()
{
    import std.stdio : writeln;

    auto load = HireLoad(1_057_225, [3500, 1500, 1500, 800], 1_350_000);

    auto plans = [
        Plan("monthly",   599_500, 0, 1),
        Plan("quarterly", 549_500, 0, 3),
        Plan("yearly",    499_500, 0, 12),
    ];

    writeln("loaded monthly: ", ledger(load.loadedCents));
    foreach (p; rankByFirstYear(plans, load))
        writeln(p.name, " first-year delta: ",
            ledger(firstYearDelta(p, load)));
}

unittest
{
    auto load = HireLoad(1_057_225, [3500, 1500, 1500, 800], 1_350_000);

    // 10,572.25 * 1.73 = 18,289.99 (reads as the $18,290 sticker input)
    assert(load.loadedCents == 1_828_999);

    auto monthly = Plan("monthly", 599_500, 0, 1);
    auto quarterly = Plan("quarterly", 549_500, 0, 3);
    auto yearly = Plan("yearly", 499_500, 0, 12);

    // Steady state: 18,290x12 - 5,995x12 = 147,540 (at dollar precision)
    assert(ledger(steadyYearDelta(monthly, load)) == "$147,540");
    // First year adds the hire's one-time cost: the $161,040 sticker.
    assert(ledger(firstYearDelta(monthly, load)) == "$161,040");
    assert(ledger(steadyYearDelta(quarterly, load)) == "$153,540");
    assert(ledger(steadyYearDelta(yearly, load)) == "$159,540");

    // Ranking: yearly plan saves the most, monthly the least.
    auto ranked = rankByFirstYear([monthly, quarterly, yearly], load);
    assert(ranked[0].name == "yearly");
    assert(ranked[$ - 1].name == "monthly");

    assert(ledger(147_539_88) == "$147,540");
    assert(ledger(-123_400) == "-$1,234");
    assert(divRoundHalfUp(2_500, 100) == 25);
    assert(divRoundHalfUp(2_499, 100) == 25);
    assert(divRoundHalfUp(2_440, 100) == 24);
}
