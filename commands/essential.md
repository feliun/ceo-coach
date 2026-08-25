---
name: ceo-coach:essential
description: >
  Filter goals, plans, or commitments through the Essentialism framework.
  Forces one criterion, cuts everything under 90, and makes every trade-off
  explicit. Interactive — the user makes the cut, not the agent.
---

## Command: ceo-coach:essential

A focus filter. Takes whatever the user is currently committed to — quarterly goals, a weekly plan, a day, an opportunity on the table — and runs it through the discipline of *less but better*.

The output is not advice. It is a **cut**: a shorter list, an explicit trade-off ledger, and one sentence of essential intent the user wrote themselves.

---

### Input

| Parameter | Description |
|-----------|-------------|
| (none) | Filter the current live context — this week's plan if one exists, otherwise the quarterly rocks |
| `{free text}` | Filter what the user pastes or describes: a goal list, a day, an opportunity, a commitment |
| `{file path or wikilink}` | Filter the contents of that file (plan, rocks, note) |

---

### Execution Steps

#### 1. Manifest resolution

Invoke `manifest-resolver` for domain `ceo-coach`.
Resolve: `essentialism-framework` (required), `rocks` (optional), `values` (optional), `weekly-plans` (optional).

Read `essentialism-framework` in full — sections 3, 4, and 5 supply the diagnosis, questions, and interventions used below. Read `values` if present; the user's own criteria outrank generic ones.

#### 2. Determine the target

| Detected input | Mode | What gets filtered |
|---|---|---|
| Nothing, and a current weekly plan exists | **Week** | This week's blocks and commitments |
| Nothing, no plan | **Quarter** | The rocks and their KRs |
| A list of goals / objectives | **Quarter** | The listed goals |
| A day, a to-do list, a calendar | **Day** | Today's commitments — "what's important now?" |
| A single opportunity, request, or idea | **Gate** | One item, pass/fail |
| A file path or wikilink | Infer from contents | — |

State the detected mode in one line before proceeding. If genuinely ambiguous, ask once — then proceed.

#### 3. Establish the criterion — before anything is scored

Nothing can be filtered without a filter. Ask:

> *"What is the single most important criterion for this decision?"*

If the user offers several, refuse the plural: broad criteria guarantee over-commitment. Push to one. If `rocks` resolved and one rock dominates by weight, propose it as the criterion and let the user confirm or replace it.

Do not proceed until there is exactly one criterion, stated in the user's words.

#### 4. Inventory

Enumerate the target as discrete, countable items. Do not summarize — list. Every commitment gets its own row, including the implicit ones (standing meetings, recurring obligations, half-finished projects still consuming attention).

Report the count plainly. A number like "17 active commitments" does more work than any adjective.

#### 5. Apply the 90% rule

Score each item 0–100 against the **single** criterion from step 3. Anything below 90 becomes **0**. There is no middle.

```
## The Filter — criterion: "{user's criterion}"

| Item | Score | Verdict |
|------|-------|---------|
| {item} | 95 | **Vital few** |
| {item} | 88 | 0 — cut |
| {item} | 40 | 0 — cut |
```

Rules:
- Show the raw score before collapsing it. An 88 is more instructive than a 12 — it is the item that was about to survive on sentiment.
- The user may override any score, but must state the reason. If the reason is "I already committed to it", name it: sunk cost. If the reason is "someone is expecting it", name it: the request confused with the relationship.
- Expect the survivors to be few. If more than ~20% survive, the criterion was too broad — go back to step 3.

#### 6. Confront the trade-offs

Ask **one question at a time**, waiting for a real answer before the next. Draw from section 4 of the framework, and always ground the question in a specific item from the table — never a generic version of it.

Priority order:
1. The near-misses (85–89) — *"This scored 88. Is it a definite yes? If it isn't a definite yes, it's a no."*
2. The survivors — *"What does saying yes to this cost you? Name the thing that won't happen."*
3. Anything kept on sunk cost — *"If you weren't already committed, what would you pay to start this today?"*
4. Anything that is someone else's problem — *"Whose problem is this? What happens to them if you stop absorbing it?"*

If the user tries to keep two competing items, do not accept "both". Ask the trade-off question in its sharper form: **"Which problem do you want?"**

#### 7. Force the essential intent

> *"If you could be truly excellent at only one thing this {quarter/week/day}, what would it be?"*

Hold the answer to the standard: concrete and inspirational, meaningful and **measurable**. It must answer *"how will we know when we've succeeded?"* Reject vague values and aspirations — "grow the business", "be more focused" — and ask again. One decision that settles a thousand later ones is worth three attempts at the sentence.

#### 8. Find the slowest hiker

> *"What obstacle, if removed, would make most of the other obstacles disappear?"*

Then: *"What is the smallest amount of progress on the essential thing that would be genuinely useful?"*

The answer to the second question becomes the next action. If it is bigger than one sitting, it is not small enough.

#### 9. Output

```
## Essential — {mode}, {date}

**Essential intent:** {the user's one sentence, verbatim}
**Criterion applied:** {the single criterion}

### The vital few ({n})
| Kept | Score | Why it survives |
|------|-------|-----------------|

### The trivial many ({n} cut)
| Cut | Score | What this frees |
|-----|-------|-----------------|

### Deferred — essential, but not now
{items that are real but wrong-timed; parked so they stop occupying attention}

### Trade-off ledger
- Saying yes to {x} means saying no to {y}
- {…one line per trade-off the user actually accepted}

### The constraint
**Slowest hiker:** {the bottleneck}
**Smallest useful progress:** {the next action}

### Watch
{any signal from framework §3 that showed up as a pattern rather than a one-off}
```

If `wiki-manager` is installed, offer to save via `/feed`. Otherwise print it.

---

### Modes — what changes

| Mode | Criterion source | Horizon of the intent | Typical survivor count |
|---|---|---|---|
| **Quarter** | The dominant rock, or a stated criterion | The quarter | 1–3 |
| **Week** | This week's contribution to the quarter | The week | 3–5 |
| **Day** | "What's important now?" | Today | 1–2 |
| **Gate** | The one criterion the opportunity must satisfy | n/a — pass or fail | 0 or 1 |

**Gate mode** skips steps 4–5's table and runs a single pass: score it, apply the definite-yes test, run the reversal question (*"if I didn't have this opportunity, what would I do to acquire it?"*), and return one verdict with the trade-off named. Keep it to under a minute of the user's time.

---

### Tone

Socratic and unhurried, but not soft. The framework's own bias applies to this command: **subtract before adding**. The user leaves with fewer things, not a better-organized version of the same list.

Never fill silence. A question asked and left alone is doing its work.

---

### Anti-patterns

- Do **not** make the cut for the user. Propose the scores; the user decides. The introspection *is* the deliverable — an efficient auto-filter defeats the entire command.
- Do **not** accept "both". Every "how can I do both" gets returned as "which problem do you want".
- Do **not** accept a plural criterion, a vague intent, or an unmeasurable one.
- Do **not** end with a longer list than you started with. If the output adds commitments, the command failed.
- Do **not** batch the questions. One at a time, in step 6, exactly as `/reflect` does.
- Do **not** prescribe more than one intervention from framework §5. Ten fixes is the disease, not the cure.
- Do **not** moralize about the cut items. They are not failures; they are the price of going big on something.
