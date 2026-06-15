---
name: job-application-helper
description: Generate tailored answers for job application questions based on your own profile. Use when the user shares a job description or application questions and needs help crafting responses. Supports all question types including behavioral, motivational, technical, and short-answer application form questions. Generates natural, human-sounding responses that are professional yet friendly.
---

# Job Application Helper

Generate job application answers tailored to **your** background and the specific role.

> **One-time setup:** copy `references/profile.template.md` → `references/profile.md` and fill it with your own background. `profile.md` is git-ignored and never ships — it stays private on your machine.

## Workflow

1. Ask for the job description (and the specific questions) if not provided.
2. Read `references/profile.md` to load the user's background. If it doesn't exist yet, tell them to create it from `references/profile.template.md`.
3. Analyze the job requirements and identify the strongest matches with the user's experience.
4. Generate answers that connect the user's specific experience to what the role needs.

## Writing Style Rules

Follow these strictly to produce natural, human-sounding responses:

**Do:** Write in first person as the user. Professional but conversational tone. Keep short answers ~2–4 sentences, longer ones ~4–6. Vary sentence openers. Use contractions naturally (I've, I'm, that's). Include specific numbers and outcomes from the user's real experience. Connect past experience directly to the role's requirements.

**Never:** Use bullet points/numbered lists inside answers. Use clichés like "I am excited to" or "I am passionate about." Use filler or corporate jargon. Over-explain or pad. Overuse em dashes/semicolons. Start several sentences in a row with "I". Invent experience, employers, metrics, or credentials — only use what's in `profile.md`.

## Answer Patterns

- **"Why this role?"** — connect a specific aspect of the user's current work to what the role offers; mention something concrete about the company if known.
- **"Tell me about yourself"** — lead with current role + a key achievement; 1–2 relevant past experiences; end with what draws the user to this opportunity.
- **"Why should we hire you?"** — most relevant experience match, backed by a specific result; confident, not arrogant.
- **Behavioral** — pick a real story; brief situation, focus on actions + a measurable outcome (STAR internally, natural narrative on the page).
- **Technical** — draw from the user's actual stack and projects; be specific about tools, scale, outcomes.
- **Weakness/challenge** — a real growth area with concrete steps taken to improve.

## Example Transformation

**Bad:** "I am excited about this opportunity because I am passionate about <field> and believe my skills would be a great fit for your team."

**Good:** "I spent the last year leading a database migration that moved billions of rows with zero downtime, so the infrastructure challenges in this role are exactly what I want to keep building on. The focus on real-time pipelines caught my attention because that's where I've been pushing hardest lately."

*(The "good" version is concrete, in the user's voice, ties real experience to the role, and avoids clichés — replace specifics with the user's actual work from `profile.md`.)*

## Resources

`references/profile.md` (you create it from the template) holds the user's complete professional background — work history, skills, certifications, current projects, key achievements. Always read it before generating answers.
