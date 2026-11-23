@NNNN @<module>
Feature: <what the actor can achieve, in plain language>
  As a <persona from the context page in docs/architecture/, "The people">
  I want <the thing they do>
  so that <the outcome they get>

  Spec: docs/specs/NNNN-<capability>/spec.md

  <One short paragraph of context when the feature needs it — a boundary that is easy
  to get wrong, or a distinction between two applications. Delete it otherwise.>

  Rule: <R1 — the requirement, stated as a sentence>

    @NNNN.R1
    Example: <the case where the rule is satisfied>
      Given <the starting situation>
      When <the actor does something>
      Then <what is observably true afterwards>

    @NNNN.R1
    Example: <the case where the rule bites>
      Given <the starting situation>
      When <the actor does something the rule forbids>
      Then <how the product protects the rule>

  # Guidance
  #  - This file is the spec's acceptance scenarios, executable. It is written when the spec is
  #    approved — before the code — and the spec links it instead of repeating the scenarios.
  #  - Every Example carries its requirement tag; every Rule is a requirement of the spec.
  #  - A scenario not yet passing is tagged @pending; none is pending once the spec is Implemented.
  #  - Business language only: no class, table, route, or column names.
  #  - Declarative, not UI-scripted: "when I publish the product", not "when I click Save".
  #  - Cover the happy path plus the failures that actually matter, not every permutation —
  #    an authorization refusal is always one that matters.
