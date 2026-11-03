---
name: dev:specifier
description: This skill should be used when creating feature specifications. Auto-triggers on requests like "create a spec", "design a feature", "plan a feature", "write a specification", or when discussing planning new functionality.
---

# Dev Specifier

Routes spec requests to the `/dev:brief` workflow, so there is one spec process and one template.

## When This Skill Activates

This skill auto-triggers when the user:
- Asks to "create a spec" or "write a specification"
- Wants to "plan a feature" or "design a new feature"
- Mentions needing to document requirements
- Discusses planning implementation for a new feature
- Says "I need to spec out..." or "Let's plan..."

## Core Principle

**80% planning, 20% execution.** Invest heavily in understanding the problem before writing code.

## What To Do

1. Derive a short kebab-case feature name from the request (for example "plan the payment integration" -> `payment-integration`).
2. Collect the requirements the user has already decided, from the request, into one paragraph. If they have not decided what to build yet, say that `/dev:brief` plans decided requirements and help them write those down first.
3. Run the brief command with both:

   ```
   Skill(skill="dev:brief", args="{feature-name} \"{requirements}\"")
   ```

   Pass `--linear LINEAR-XXX` or `--figma <url>` through if the user mentioned them.

4. Follow `/dev:brief` from there. It writes everything under `specs/{feature-name}/` at the repository root, leaves the spec as Draft for a human to approve, and points to `/dev:work` for execution.

## Example Triggers

- "I need to create a spec for user authentication"
- "Help me plan out the payment integration feature"
- "Let's write a specification for the new dashboard"
- "Can you help me design the notification system?"
- "I want to spec out the API changes"
