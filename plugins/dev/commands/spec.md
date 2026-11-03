---
name: dev:spec
description: "Deprecated: renamed to /dev:brief. Runs /dev:brief with the same arguments."
argument-hint: <feature-name> [requirements...] [--no-interview] [--linear LINEAR-XXX] [--figma <figma-url>]
---

# /dev:spec (deprecated)

`/dev:spec` was renamed to `/dev:brief` in 1.2.0 and will be removed in a later release.

1. Tell the user in one line: "`/dev:spec` is now `/dev:brief`; running that."
2. Run it with the same arguments, unchanged:

   ```
   Skill(skill="dev:brief", args="$ARGUMENTS")
   ```

3. Follow `/dev:brief` from there. Its output files are the same as before (`specs/{feature-name}/spec.md`, `technical-spec.md`, and so on).
