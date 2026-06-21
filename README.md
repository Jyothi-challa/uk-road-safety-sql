# UK Road Safety SQL Analysis (Stats19, 2025)

An exploratory SQL analysis of UK road collisions using the Department for Transport's **Stats19** dataset for 2025 (provisional). The project answers eight analytical questions using SQL joins, aggregations, conditional logic, window functions, and common table expressions.

**Tools:** MySQL · MySQL Workbench
**Dataset:** [UK Road Safety Data (Stats19)](https://www.data.gov.uk/dataset/cb7ae6f0-4be6-4935-9277-47e5ce24a11f/road-safety-data) — Collisions, Vehicles, Casualties files.

---

## Dataset overview

Three CSVs from data.gov.uk were imported into a MySQL schema named `road_safety`:

| Table | Description |
|-------|-------------|
| `collision` | One row per reported collision (time, location, severity, conditions) |
| `vehicle` | One row per vehicle involved (type, manoeuvre, driver age) |
| `casualty` | One row per casualty (sex, age band, severity of injury) |

Tables are joined on `collision_index` + `collision_ref_no`.

Total reported collisions in scope: **14,914** (2025 provisional data). Severity codes: `1 = Fatal`, `2 = Serious`, `3 = Slight`, `-1 = Missing`.

---

## Findings

### 1. Total collisions and severity breakdown (2025)

| Severity | Count |
|---|---:|
| Slight | 11,581 |
| Serious | 3,213 |
| Fatal | 120 |

The vast majority of collisions (~78%) are slight. Fatal collisions are rare in relative terms but represent the most serious outcomes the dataset is used to monitor.

### 2. Overall fatality rate

Approximately **0.80%** of all reported collisions in 2025 were fatal. Translated: roughly **1 in every 125 collisions** results in a death.

### 3. Time-of-day pattern

Collisions peak at **5pm (1,285 collisions)** and stay high across the afternoon rush (3–6pm: ~1,200/hour). A secondary morning peak occurs at **8am (988)**. The quietest hours are **3am–5am** (~100/hour). The shape mirrors commuting volume rather than any safety-specific factor.

### 4. Highest-fatality local authorities (within the top 10 by collision count)

The CTE selected the 10 local authorities with the most collisions (almost all London boroughs — `E09xxxxx` codes), then ranked them by fatal-collision rate:

| Local authority (ONS code) | Total | Fatal | Fatal rate |
|---|---:|---:|---:|
| E09000012 | 366 | 6 | **1.64%** |
| E09000025 | 387 | 3 | 0.78% |
| E08000012 | 438 | 3 | 0.68% |
| E09000010 | 420 | 2 | 0.48% |
| E09000008 | 436 | 2 | 0.46% |
| E09000028 | 439 | 2 | 0.46% |
| E09000033 | 538 | 2 | 0.37% |

E09000012 sits well above its peers at 1.64% — twice the next-highest. With only 6 fatal collisions, the confidence interval is wide, but the lead is large enough to warrant a closer look.

### 5. Wet vs dry road surfaces — serious-or-fatal rate

| Road condition | Total | Serious + Fatal | Rate |
|---|---:|---:|---:|
| **Wet** | 2,028 | 515 | **25.39%** |
| Dry | 12,025 | 2,716 | 22.59% |

Wet roads have a slightly higher serious-or-fatal rate (~2.8pp higher) — meaning per collision, wet conditions are marginally more dangerous. However, dry conditions account for **~85% of all collisions** in absolute terms, simply because dry days are far more common.

### 6. Weekend nights vs weekday nights

A proxy analysis for drink-driving, restricted to night-time hours (10pm–4am). "Weekend night" = Friday 10pm to Sunday 4am.

| Day type | Total | Serious + Fatal | Rate |
|---|---:|---:|---:|
| **Weekend night** | 662 | 179 | **27.04%** |
| Weekday night | 876 | 215 | 24.54% |

Weekend nights show a meaningful ~2.5pp higher serious-or-fatal rate than weekday nights — consistent with the conventional intuition about late-night weekend driving. *An initial cut that bucketed only Sat/Sun as weekend showed no difference; correctly including Friday-night-onwards in the weekend window surfaced the gap.* A direct drink-related analysis would require joining the separate **Contributory Factors** file — left as a follow-up.

### 7. Vehicle types most over-represented in fatal collisions

Vehicle types with ≥50 collisions, ranked by fatal rate:

| Vehicle type | Total | Fatal | Fatal rate |
|---|---:|---:|---:|
| Goods 7.5 tonnes and over (HGV) | 141 | 6 | **4.26%** |
| Motorcycle over 500cc | 504 | 17 | 3.37% |
| Goods vehicle — unknown weight | 302 | 9 | 2.98% |
| Other vehicle | 206 | 5 | 2.43% |
| Goods 3.5–7.5t | 92 | 2 | 2.17% |
| ... | | | |
| Car | 16,215 | 122 | 0.75% |
| Pedal cycle | 3,645 | 16 | 0.44% |
| Motorcycle 125cc and under | 1,810 | 6 | 0.33% |

The driver of fatality rate is **mass and speed**, not exposure alone: three of the top five are HGVs/goods vehicles. Large motorcycles (>500cc) — fast, motorway-capable, exposed riders — are the only non-goods entry in the top tier. Counter-intuitively, **small motorbikes and pedal cycles sit near the bottom** at 0.3–0.4%; they're typically urban and low-speed, so their collisions are mostly slight.

Cars dominate fatalities in **absolute** terms (122 deaths from 16,215 collisions) simply because of volume, but on a per-collision basis cars are far safer than HGVs or large motorbikes.

**Caveat:** the HGV ≥7.5t result is based on only 6 fatal collisions; the 4.26% has a wide error margin and may move by ±1–2pp on a different year of data.

### 8. Age and sex of fatal-collision casualties

176 casualties were recorded in fatal collisions in 2025.

| Sex | Count | Share |
|---|---:|---:|
| **Male** | 135 | **76.7%** |
| Female | 41 | 23.3% |

**Top age bands** (male):

| Age band | Fatal casualties |
|---|---:|
| 26–35 | 24 |
| 46–55 | 23 |
| 56–65 | 20 |
| 66–75 | 17 |
| 16–20 | 14 |

Casualties in fatal collisions skew heavily male (~77%), with the largest concentrations in working-age and older-male bands. The 16–20 male bracket appears with high count despite the small population size of that age group — consistent with the well-documented "young male driver" risk pattern. Older bands (66+) also feature prominently, reflecting greater frailty: an older casualty is less likely to survive a collision of any severity.

---

## Methodology and limitations

- **Provisional data.** 2025 figures are not yet finalised by DfT; counts and rates may shift slightly when the year is fully closed.
- **Drink-driving proxy.** There is no `drink_related` column on the collisions table. Drink-driving information lives in the separate Contributory Factors file, which was not loaded for this project. Q6 uses night-time hours as a behavioural proxy.
- **Wet/dry scope.** Q5 compares only road-surface codes `1` (dry) and `2` (wet/damp). Snow, ice, flood, oil, and mud (codes 3–7) were excluded to keep the comparison clean.
- **Small sample sizes** at the top of Q7 (HGV: n=6 fatal) and within Q4 (E09000012: n=6 fatal) mean those rates are indicative, not precise.
- **London-skewed top-10.** Q4's "top 10 by collision count" is dominated by London boroughs because London has the highest traffic volume — not necessarily the most dangerous roads. A per-capita or per-vehicle-mile normalisation would give a fairer comparison.
- **Joins.** Tables joined on `collision_index` + `collision_ref_no`. Casualty- and vehicle-level rows fan out from each collision, so `COUNT(*)` in joined queries counts casualties or vehicles, not collisions.


