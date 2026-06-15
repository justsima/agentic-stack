---
name: llm-council
description: "Run a question, plan, decision, code review, or PR through a 5-advisor LLM Council with anonymized peer review and chairman synthesis. Each advisor uses a distinct REASONING METHOD (inversion, decomposition, analogy, naive questioning, dependency graphing) — not just a different persona. Based on Andrej Karpathy's LLM Council + DMAD research (ICLR 2025). MANDATORY TRIGGERS: 'council this', 'run the council', 'pressure-test this', 'stress-test this', 'war room this', 'debate this', 'convene the council'. DO NOT TRIGGER on simple factual questions, casual yes/no, lookups, or tasks with one obvious right answer. Reserve for decisions with genuine stakes and tradeoffs — cost is 11 sub-agent calls."
---

# LLM Council

Run a question, plan, or artifact through 5 independent advisors using **distinct reasoning methods**, then anonymized peer review, then chairman synthesis. The user has explicitly invoked this skill or pre-approved via AskUserQuestion — do not re-confirm.

This skill exists because single-model responses suffer from sycophancy ("AI kiss-ass disease") and confirmation bias. A structured council with method diversity and anonymized peer review reduces both.

## Why this works (research backing)

- **Method diversity beats persona diversity.** DMAD (ICLR 2025) shows same-model councils need distinct *reasoning methods*, not just different angles, to avoid converging on shared training-data biases.
- **Anonymized peer review** prevents model-brand bias and forces evaluation on content quality (Karpathy's key innovation).
- **Single round, no debate.** The 2025 conformity-drift literature shows multi-round debate makes models converge toward *wrong* answers. We do exactly one round.
- **Separate-context synthesis.** The chairman runs in a fresh dispatch reading critiques as input data — not as the tail of any critic's conversation. This prevents collapse to a single advisor's framing.

## When to use it

**Good:** Architecture decisions, scope/pricing/positioning tradeoffs, "should I X or Y" with real consequences, plan/PR pressure-testing, naming with stakes, hire-vs-build, migration strategies.

**Bad:** Factual lookups, "what's the syntax for X," summaries, simple yes/no, writing tasks, tasks with one obvious right answer.

If the question doesn't deserve the council, **say so directly** and answer normally instead of spawning 11 sub-agents.

## Execution flow

### Step 0: Pre-flight

1. **Parse the request.** Strip trigger phrases ("council this:", etc.) and identify whether the input is a question/plan/file path/PR URL.
   - PR URL or `#NNN` → fetch via `gh pr view` and include diff + description
   - File path → Read the file
   - Plain question/plan → use as-is
2. **Scope check.** If the question is trivial, ungrounded, or has one obvious answer, abort the council and say: "This doesn't need the council — [direct answer]. Reserve `/council` for decisions with real stakes."
3. **Auto-context.** Read these if they exist and aren't already in your context: `CLAUDE.md` (current dir + global), `README.md`, recent `git log --oneline -10`, any files the user referenced.

### Step 1: Frame the question

Reframe as neutral input:

```
QUESTION: [the core decision or thing being reviewed]
CONTEXT: [project context, constraints, recent changes]
WHAT'S AT STAKE: [why this matters — cost of getting it wrong]
```

Don't steer toward an answer. If genuinely ambiguous, ask ONE clarifying question before spawning agents.

### Step 2: Convene the council (5 parallel sub-agents)

Launch all 5 advisors **simultaneously in a single message with 5 Agent tool calls**. Sequential execution lets earlier responses bleed into later ones and defeats the purpose. Use `subagent_type: "claude"` and **`model: "opus"`** for critics — Opus 4.8, the max-tier model (set 2026-06-03 per the user; the `opus` alias resolves to the current top Opus, so it never goes stale). This replaced the original `model: "sonnet"` cost-discipline choice; the user is on Max 20x and prioritizes judgment quality over per-run cost.

**Advisor prompt template:**

```
You are [ADVISOR NAME] on an LLM Council reviewing a decision.

Your assigned reasoning method: [METHOD]
Your angle: [ANGLE]

The council was asked:
---
[framed question from Step 1]
---

Apply your reasoning method rigorously. Show your work using the method — don't just state opinions.

Rules:
- 150–300 words. No preamble. Straight into analysis.
- Name specific risks, opportunities, or issues. No vague concerns.
- If code: cite specific files, functions, patterns. If plan: cite specific steps, gaps, sequencing issues.
- Lean fully into your assigned angle. Do not hedge. Do not "balance." The synthesis comes later.
- End with your single strongest recommendation.
```

**The five advisors (method-specific instructions):**

| # | Name | Angle | Reasoning method instruction |
|---|------|-------|------------------------------|
| 1 | **The Contrarian** | What will fail? | **INVERSION**: "Assume this shipped exactly as proposed — and failed. Work backward: what was the cause? What looked safe but broke under pressure? What's the failure mode nobody is discussing? Show your inversion chain." |
| 2 | **First Principles Thinker** | What are we actually solving? | **DECOMPOSITION**: "Break this into atomic claims and assumptions. List them. Challenge each: is this actually true? Is it necessary? What changes if this assumption is wrong? Identify the load-bearing assumptions." |
| 3 | **The Expansionist** | What upside are we missing? | **ANALOGY**: "What adjacent domain, product, or system solved a similar problem differently? What would someone with 10× ambition do here? Where is this thinking too small? Name specific analogues and what they'd suggest." |
| 4 | **The Outsider** | Zero context, fresh eyes | **NAIVE QUESTIONING**: "You have zero context about this project. Based purely on what's in front of you, list every point that requires insider knowledge. What's confusing? What jargon is unexplained? What would you ask if you just joined? If you can't follow the reasoning, say so." |
| 5 | **The Executor** | What do you do Monday morning? | **DEPENDENCY GRAPHING**: "Map the dependencies: what blocks what? What's the critical path? What's the first thing that must happen, and what can't start until it finishes? What takes 5 minutes but everyone will forget? Show the execution sequence." |

**Natural tensions by design:** Contrarian↔Expansionist (downside↔upside), First-Principles↔Executor (rethink↔ship), Outsider keeps everyone honest.

### Step 3: Anonymous peer review (5 parallel sub-agents)

Collect the 5 advisor responses. **Randomize the labels** so Advisor 1 is not always Response A — generate a shuffled mapping like `{A → Outsider, B → Executor, C → Contrarian, D → Expansionist, E → First Principles}`. Keep this mapping in your scratch for de-anonymization at Step 4.

Launch 5 new reviewer sub-agents in parallel (single message, 5 Agent tool calls, `subagent_type: "claude"`, **`model: "opus"`** — Opus 4.8, same max-tier as the advisors). Each reviewer sees all 5 anonymized responses:

```
You are reviewing the outputs of an LLM Council. Five advisors independently answered:

---
[framed question]
---

**Response A:** [randomized advisor response]
**Response B:** [randomized advisor response]
**Response C:** [randomized advisor response]
**Response D:** [randomized advisor response]
**Response E:** [randomized advisor response]

Answer these three questions. Be specific. Reference responses by letter.

1. Which response is strongest? Why? (one sentence)
2. Which has the biggest blind spot? What is it missing? (one sentence)
3. What did ALL five responses miss that the council should consider? (This is the most valuable question — think hard.)

Under 150 words total. No preamble. Be direct.
```

### Step 4: Chairman synthesis (1 sub-agent, Opus 4.8)

Dispatch a single chairman agent with **`model: "opus"`** (Opus 4.8) — pin it explicitly so the chairman is never silently downgraded even if the parent session is on a lesser model. This agent gets EVERYTHING: the framed question, all 5 advisor responses (now de-anonymized with names and reasoning methods labelled), all 5 peer reviews, and the anonymization mapping. It runs in a fresh context, reading the critiques as input data — not as a continuation of any critic's conversation.

**Chairman prompt:**

```
You are the Chairman of an LLM Council. Five advisors independently analyzed this question, then peer-reviewed each other's responses anonymously. Your job is to produce the final verdict.

QUESTION:
[framed question]

ADVISOR RESPONSES (de-anonymized):
[Name + Reasoning Method + full response, for each of the 5]

PEER REVIEWS (with anonymization key, so you can attribute):
[All 5 peer reviews + the A→Name mapping]

Produce exactly this structure. Do not deviate.

## Council Verdict: [Topic — 5 words max]

### Where the council agrees
[Points multiple advisors converged on independently. These are high-confidence signals. Be specific — name which advisors agreed and on what.]

### Where the council clashes
[Genuine disagreements. Do not smooth these over. Present both sides and explain why reasonable advisors disagree.]

### Blind spots the council caught
[Things that only emerged in peer review — gaps individual advisors missed but reviewers flagged. Especially "what did ALL five miss" answers.]

### The recommendation
[A clear, actionable recommendation. Not "it depends." Not "consider both sides." A real answer. You may disagree with the majority if the dissent's reasoning is strongest — explain why if so.]

### The one thing to do first
[Single concrete next step. Not a list of ten things. One thing.]

### What you lose with this recommendation
[The cost of following this advice — what gets sacrificed, what the strongest dissent would warn about. Preserve dissent; don't bury it.]
```

### Step 5: Present to the user

Show the chairman's verdict directly. Do NOT add your own preamble like "here's what the council said." Just present the verdict. If the user wants to see individual advisor responses or peer reviews, offer to surface them — don't dump them by default.

## Cost discipline

- One full invocation = **11 sub-agent calls** (5 advisors + 5 reviewers + 1 chairman), **all on Opus 4.8** (set 2026-06-03). This is ~3-4× the cost/latency of the original Sonnet-critics + Opus-chairman mix — a deliberate quality-over-cost choice (the user, Max 20x). To revert to the cheaper mix, set critics back to `model: "sonnet"` in Steps 2 and 3.
- If the user runs it on a trivial question, you've wasted ~11× the tokens of a normal answer. The Step 0 scope check exists to prevent this.
- For very simple decisions, suggest the lite pattern instead: "This might just need a 3-perspective check — want a quick critic pass with Contrarian + First Principles + Executor only? Saves 8 calls."

## What this skill is NOT

- Not a debate framework. No multi-round arguments. One round, then synthesis.
- Not a majority-vote system. A 1-of-5 dissent on the right point beats four agreements on the wrong frame. The chairman is allowed (and encouraged) to side with the minority when reasoning warrants.
- Not a substitute for the user's judgment. The council surfaces angles and tradeoffs; the user decides.
- Not a true multi-model council. This implementation uses Claude sub-agents with method diversity. For true cross-model diversity (Karpathy's original), an OpenRouter version would be needed — that's a future upgrade, not v1.
