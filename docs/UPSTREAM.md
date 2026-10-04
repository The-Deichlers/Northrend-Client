# Upstream Synchronization

Northrend is intentionally a maintained downstream client rather than a detached one-time fork.

## Sources

Primary upstream sources:

1. `SatyPardus/wotlk-rebuild`, especially its `development` branch.
2. `whoahq/whoa`, the original project lineage.

The imported Git history must remain intact so provenance is clear.

## Intake policy

Do not periodically overwrite the `northrend` branch with upstream.

Instead:

1. Review upstream commits for relevant fixes or implementations.
2. Prefer small cherry-picks or clearly scoped merges.
3. Resolve conflicts in favor of verified 3.3.5a behavior, not branding alone.
4. Preserve Northrend-specific build, documentation, test, and integration work.
5. Re-test networking/world-entry changes against `northrend-test`.

## Internal names

Many internal types, macros, paths, and filenames still contain `Whoa` or `WHOA_`. These are implementation identifiers inherited from upstream and are not automatically renamed.

The user-facing product name and produced client binary are **Northrend**.

Internal renames should happen only when they materially improve maintainability and do not create disproportionate upstream merge conflicts.

## Attribution

Never remove upstream authorship or rewrite historical commits merely for branding. New Northrend work should be committed normally on top of the preserved history.
