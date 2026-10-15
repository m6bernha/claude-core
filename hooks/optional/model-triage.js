#!/usr/bin/env node
// UserPromptSubmit hook: injects a compact model-triage reminder.
// Fires only on substantive prompts. Biased toward escalation per user rule:
// "don't miss an opus task when an opus task is needed".

const fs = require('fs');
let raw = '';
try { raw = fs.readFileSync(0, 'utf8'); } catch (e) {}

let payload = {};
try { payload = JSON.parse(raw || '{}'); } catch (e) {}

const prompt = (payload.prompt || '').trim();

const TRIVIAL = /^(y|yes|no|n|ok|okay|thanks|thank you|continue|go|do it|confirmed|stop|wait)$/i;
if (prompt.length < 40 || TRIVIAL.test(prompt)) {
  process.exit(0);
}

const OPUS_CUES = /\b(architect|architecture|design (system|pattern)|refactor (the|entire|whole)|migrate|migration strategy|redesign|multi-file|cross-cutting|trade[- ]?off|tradeoffs?|novel|from scratch|greenfield|system design|scalability|security (review|audit|model)|threat model|data model|schema design|plan (out|the)|strategy|roadmap)\b/i;
const HAIKU_CUES = /\b(rename|typo|formatting|lint fix|add comment|update (readme|docs? only)|bump version|changelog)\b/i;

let suggestion;
if (OPUS_CUES.test(prompt)) {
  suggestion = 'OPUS-TIER SIGNALS DETECTED. Default to opus for this task or any agent you spawn. Do not downshift unless scope is clearly narrower than it reads.';
} else if (HAIKU_CUES.test(prompt)) {
  suggestion = 'Likely haiku-tier (mechanical). Sonnet fine for a single agent; consider haiku agents (doc-updater) when available.';
} else {
  suggestion = 'Sonnet-tier likely. Before ANY Agent/Task spawn: audit scope — if it involves architecture, cross-file refactor, security design, or a novel problem, escalate to opus.';
}

const out = [
  '<model-triage>',
  suggestion,
  'Rule: when uncertain, escalate to opus — a missed opus task costs more than a wasted opus call.',
  '</model-triage>'
].join('\n');

process.stdout.write(out);
process.exit(0);
