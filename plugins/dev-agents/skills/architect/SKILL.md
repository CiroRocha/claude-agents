---
name: architect
description: Decide the best architecture for a new project, system, module or feature. Assesses complexity, starts 1–3 `architect` agents with different design lenses, has them vote on each other's proposals when there are 2 or more, and presents a recommended design plus ranked alternatives with clear tradeoffs. Use when the user asks how to architect, design or structure something new, asks to compare architectural approaches, or invokes /architect.
---

# Architect: design panel orchestrator

You (the main conversation) are the orchestrator. You do not design the solution yourself. You frame the problem, run a panel of `architect` agents, tally their votes, and present the result. You can start agents and they can't, so the orchestration stays here.

## Step 1: Build the design brief

1. **Understand the request.** What is being built, and is it a new system, a new module in an existing codebase, or a feature?
2. **Look at the existing context**, if you're in a repo: the stack, the structure and any relevant existing patterns. Keep it quick. The agents will look deeper.
3. **Fill the gaps that matter.** If any of these are unknown *and* would change the architecture, ask the user, in **one** batch of up to 4 questions using AskUserQuestion:
   - Scale: users, requests per second, data volume, growth
   - Hard constraints: stack, cloud, budget, compliance, deadlines
   - Team: size and skills; who will operate it
   - Quality priorities: latency, availability, consistency, cost, time to market

   Don't ask about anything the codebase or the request already answers. Where it's safe, assume a sensible default and record it as an assumption.
4. **Write the brief**, the same text every agent will get:

```
## Design brief
Problem: ...
Context: existing codebase/stack, or greenfield
Functional requirements: ...
Hard constraints (must be met): ...
Quality priorities (ranked): ...
Assumptions: ...
Out of scope: ...
```

## Step 2: Choose the panel size

| Complexity | Signals | Agents |
|---|---|---|
| **Low** | A single module or feature, one obvious place in an existing codebase, few integrations, low risk | **1** (solo mode) |
| **Medium** | Several components or services, a new data model, a few integrations, real tradeoffs between approaches | **2** |
| **High** | A new system, distributed or real-time needs, high scale, strict reliability or compliance needs, expensive to reverse | **3** |

When the signals fall between two levels, choose the lower one. Tell the user which level you chose and why, in one line.

## Step 3: Assign lenses

Each agent gets a different lens, so the proposals actually differ. Pick the lenses that fit the problem:

- **Pragmatic**: the fewest moving parts, reuses the existing stack, fastest to ship and easiest to operate *(always include this one)*
- **Scale & performance**: throughput, latency, horizontal growth
- **Evolvability**: modularity, clear boundaries, testability, room for future features and team growth
- **Reliability & security**: failure isolation, data integrity, threat model, compliance
- **Cost-efficiency**: minimal infrastructure and running costs
- **Data-centric**: data modelling, consistency, analytics and lineage

Defaults: with 1 agent, Pragmatic. With 2, Pragmatic and whichever of the others matters most for this problem. With 3, Pragmatic, Scale & performance and Evolvability, swapping in Reliability & security, Cost or Data when the brief calls for them.

## Step 4: Proposal round (in parallel)

Start all the agents **in one message** using the Agent tool with the `architect` agent. Use the exact name shown in the available agent list: when installed from the plugin it's `dev-agents:architect`. Each prompt contains:
- "Phase 1: Propose."
- The full design brief
- Its lens
- In solo mode: "You are the only architect (solo mode); include 1–2 alternatives."

Wait until every agent has finished before going on.

## Step 5: Voting round (medium and high complexity only)

**Low complexity (solo mode): skip this step entirely.** There's no vote and no scoring. The agent's primary proposal is the recommendation, and its alternatives are the secondary options, in the order the agent gave them. Go straight to Step 6.

For 2 or 3 agents:

1. Label the proposals **A, B, C** in random order, not in lens order.
2. Send each agent all the proposals plus the rubric below, with "Phase 2: Vote." If SendMessage is available, use it to continue the same agents, so they keep their context. Otherwise start them again with the brief included.
3. **Rubric.** Score each criterion 1–5. The weights come from the brief's quality priorities. These are the default weights:

| Criterion | Default weight |
|---|---|
| Meets hard requirements and constraints | ×3 (any "NOT MET" means automatic last place) |
| Simplicity and operational burden | ×2 |
| Fit with the existing stack and team | ×2 |
| Scalability for the stated load | ×1 |
| Evolvability and maintainability | ×1 |
| Risk and reversibility | ×1 |
| Cost (build and run) | ×1 |

Increase the weight of whatever the brief ranks as a top priority.

4. **Tally the votes.**
   - Drop each agent's score for its own proposal.
   - Score every proposal yourself as one more voter. You haven't written a proposal, so you're the neutral judge.
   - For each proposal, compute the average weighted score across the voters that remain.
   - **Tie-break**, in this order: fewer unmet requirements, then a higher hard-requirements score, then the simpler design.
   - If two proposals came out nearly the same, say so. When independent lenses agree, that is a strong signal.

## Step 6: Present the decision

Use this format. Lead with the recommendation and keep it scannable:

```
# Architecture recommendation: <problem>

**Complexity:** Medium → 2 architects (Pragmatic, Reliability & security)

## ✅ Recommended: <name>   (score 4.3 / 5)
Summary, components, flow (an ASCII diagram if it helps), key decisions.
**Why it won:** the 2–3 deciding factors from the vote.
**What you're giving up:** its main weaknesses, stated honestly.

## Alternatives
### 🥈 <name>   (score 3.8 / 5)
Short summary. **Choose this instead if:** <conditions>.
### 🥉 <name>   (score 3.1 / 5)
...

## Tradeoff matrix
| | Recommended | Alt 1 | Alt 2 |
|---|---|---|---|
| Time to ship | | | |
| Ops burden | | | |
| Scalability | | | |
| Cost | | | |
| Reversibility | | | |

## Vote breakdown
A short per-voter table, plus any disagreements worth knowing about.

## Risks & open questions
## Suggested next steps
```

- **In solo mode**, leave out the scores, the "Why it won" line and the Vote breakdown section. Instead, give the agent's reasons for preferring the primary design. Keep the alternatives (with "Choose this instead if"), the tradeoff matrix, the risks and the next steps.
- Put the improvements the voters suggested into the recommended design, where they don't conflict with each other, and say which ones you applied.
- If an assumption you made drove the decision, point it out. "If you actually need multi-region, the second alternative wins" is the kind of thing the user needs to know.
- After presenting, offer once to save the result as an Architecture Decision Record (for example `docs/adr/NNNN-<slug>.md`) or to start implementing it. Don't write any files unless the user asks.
