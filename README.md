# flatrate-math

Subscription-versus-hire arithmetic for flat-rate development
subscriptions, in D. Pure Phobos, standard library only, nothing to
install beyond a D compiler. It exists because the comparison that
sells these services is usually quoted as a single sticker number, and
the sticker is worth taking apart.

## The worked example

A senior US software engineer runs about $18,290 per month fully
loaded. That figure starts from a $10,572.25 base salary and applies
a benefits/taxes/bonus/retirement stack of 35% + 15% + 15% + 8%
multiplicatively: $10,572.25 x 1.73 = $18,290. The hire also carries a
one-time cost, call it $13,500 for equipment, recruiting and
onboarding.

Set that against a flat subscription at $5,995 per month:

- Loaded annual: $18,290 x 12 = $219,480
- Subscription annual: $5,995 x 12 = $71,940
- Steady-state yearly delta: $147,540
- First-year delta: $147,540 + $13,500 = $161,040

That $161,040 is the number vendors print on the sticker. It is real
arithmetic, but note what it counts twice, in effect: the one-time
hiring cost arrives every year in the marketing copy, while the
savings recur. The honest steady-state figure is $147,540 per year,
which is still roughly a 67% cut. Longer billing cadences widen the
gap: at $5,495 quarterly the yearly delta is $153,540, and at $4,995
yearly it is $159,540.

## The API

```d
import flatratemath;

auto load = HireLoad(
    Decimal64(10_572.25),
    [Decimal64(0.35), Decimal64(0.15), Decimal64(0.15), Decimal64(0.08)],
    Decimal64(13_500));

auto plans = [
    Plan("monthly",   Decimal64(5_995), Decimal64(0), 1),
    Plan("quarterly", Decimal64(5_495), Decimal64(0), 3),
    Plan("yearly",    Decimal64(4_995), Decimal64(0), 12),
];

ledger(steadyYearDelta(plans[0], load));  // "$147,540"
rankByFirstYear(plans, load);             // best plan first
```

`HireLoad.loadedMonthly` applies the stack multiplicatively, the same
way employers actually cost a salary. `firstYearDelta` counts both
one-time costs, `steadyYearDelta` counts neither, and `rankByFirstYear`
sorts plans by first-year savings. All money math runs in
`std.decimal`'s `Decimal64` so rates like 0.35 stay exact through the
multiplications, and `ledger` renders grouped dollar strings.

## Verify

```
dub test
```

The unit tests reproduce every figure in this README from the inputs,
including the $18,290 loaded monthly, the $147,540 steady-state delta,
and the $161,040 first-year delta that makes up the sticker.

## License

MIT.
