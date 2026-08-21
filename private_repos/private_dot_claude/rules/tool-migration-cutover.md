# Tool-Migration Cutover: Verify the Replacement Is *Operational* Before Deprecating the Incumbent

Promoted to a skill: invoke `tool-migration-cutover` before deprecating
any incumbent tool in favour of a replacement — it carries the rule that
removal is gated on a *positive operational signal* (not config presence),
the per-tool signal table, how to check a runner actually ran, and the
stage-as-draft pattern for the waiting period.
