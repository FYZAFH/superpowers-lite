#!/usr/bin/env python3

from __future__ import annotations

import argparse
import shutil
from pathlib import Path


def replace_or_die(text: str, old: str, new: str, relpath: str) -> str:
    if old not in text:
        raise ValueError(f"Missing expected text in {relpath!r}: {old!r}")
    return text.replace(old, new)


def codex_replacements(logical_root: Path) -> dict[str, list[tuple[str, str]]]:
    agents_root = (logical_root / "agents").resolve()
    implementer_path = (agents_root / "implementer.md").as_posix()
    spec_reviewer_path = (agents_root / "spec-reviewer.md").as_posix()
    code_reviewer_path = (agents_root / "code-reviewer.md").as_posix()

    return {
        "bootstrap.md": [
            (
                "your 'superpowers-lite:using-superpowers' skill",
                "your 'using-superpowers' skill",
            ),
            (
                "For all other skills, use the 'Skill' tool:**",
                "For all other skills, use Codex's native skills system:**",
            ),
            (
                "invoke the `code-review` skill via the Skill tool to audit the output.",
                "invoke the `code-review` skill to audit the output.",
            ),
            ("(CLAUDE.md, direct requests)", "(AGENTS.md, direct requests)"),
        ],
        "skills/using-superpowers/SKILL.md": [
            (
                "invoke the `code-review` skill via the Skill tool to audit the output.",
                "invoke the `code-review` skill to audit the output.",
            ),
            ("(CLAUDE.md, direct requests)", "(AGENTS.md, direct requests)"),
        ],
        "skills/subagent-driven-development/SKILL.md": [
            (
                "(e.g., via `@file` reference or by providing the path directly)",
                "(e.g., by providing the path directly)",
            ),
            (
                "1. Read plan, extract all tasks, create TodoWrite",
                "1. Read plan, extract all tasks, create and maintain `update_plan` steps",
            ),
            (
                "Three agent types, dispatched by name via the Agent tool:",
                "Three agent roles, dispatched via `spawn_agent` using the matching instructions file:",
            ),
            (
                "```\nAgent tool:\n  subagent_type: implementer\n  prompt: |\n"
                "    Task 3: Implement user authentication endpoint\n\n"
                "    Spec: docs/superpowers/specs/auth-spec.md\n"
                "    Plan: docs/superpowers/plans/auth-plan.md\n"
                "    Work from: .worktrees/feature-auth\n\n"
                "    Context: This builds on the session middleware from Task 2.\n"
                "    The database schema is already in place (see db/schema.ts).\n```",
                "```\nspawn_agent:\n  agent_type: worker\n  fork_context: false\n  message: |\n"
                f"    Follow the instructions in {implementer_path}.\n\n"
                "    Task 3: Implement user authentication endpoint\n\n"
                "    Spec: docs/superpowers/specs/auth-spec.md\n"
                "    Plan: docs/superpowers/plans/auth-plan.md\n"
                "    Work from: .worktrees/feature-auth\n\n"
                "    Context: This builds on the session middleware from Task 2.\n"
                "    The database schema is already in place (see db/schema.ts).\n```",
            ),
            (
                "```\nAgent tool:\n  subagent_type: spec-reviewer\n  prompt: |\n"
                "    Review Task 3: user authentication endpoint\n\n"
                "    Spec: docs/superpowers/specs/auth-spec.md\n"
                "    Plan: docs/superpowers/plans/auth-plan.md\n"
                "    Base: abc1234\n"
                "    Head: def5678\n```",
                "```\nspawn_agent:\n  agent_type: explorer\n  fork_context: false\n  message: |\n"
                f"    Follow the instructions in {spec_reviewer_path}.\n\n"
                "    Review Task 3: user authentication endpoint\n\n"
                "    Spec: docs/superpowers/specs/auth-spec.md\n"
                "    Plan: docs/superpowers/plans/auth-plan.md\n"
                "    Base: abc1234\n"
                "    Head: def5678\n```",
            ),
            (
                "- **superpowers-lite:writing-plans** — Creates the plan this skill executes",
                "- **`writing-plans`** — Creates the plan this skill executes",
            ),
            (
                "- **superpowers-lite:finishing-a-development-branch** — Complete development after all tasks",
                "- **`finishing-a-development-branch`** — Complete development after all tasks",
            ),
        ],
        "skills/code-review/SKILL.md": [
            (
                "Dispatch each reviewer as a subagent with the spec/plan paths and git range:",
                "Dispatch each reviewer as a subagent via `spawn_agent`, loading the matching instructions file plus the spec/plan paths and git range:",
            ),
            (
                "```\nAgent tool:\n  subagent_type: spec-reviewer\n  prompt: |\n"
                "    Review: [task description]\n"
                "    Spec: [path to spec]\n"
                "    Plan: [path to plan]\n"
                "    Base: [base SHA]\n"
                "    Head: [head SHA]\n```",
                "```\nspawn_agent:\n  agent_type: explorer\n  fork_context: false\n  message: |\n"
                f"    Follow the instructions in {spec_reviewer_path}.\n\n"
                "    Review: [task description]\n"
                "    Spec: [path to spec]\n"
                "    Plan: [path to plan]\n"
                "    Base: [base SHA]\n"
                "    Head: [head SHA]\n```",
            ),
            (
                "```\nAgent tool:\n  subagent_type: code-reviewer\n  prompt: |\n"
                "    Review: [task description]\n"
                "    Spec: [path to spec]\n"
                "    Plan: [path to plan]\n"
                "    Base: [base SHA]\n"
                "    Head: [head SHA]\n```",
                "```\nspawn_agent:\n  agent_type: explorer\n  fork_context: false\n  message: |\n"
                f"    Follow the instructions in {code_reviewer_path}.\n\n"
                "    Review: [task description]\n"
                "    Spec: [path to spec]\n"
                "    Plan: [path to plan]\n"
                "    Base: [base SHA]\n"
                "    Head: [head SHA]\n```",
            ),
        ],
        "skills/writing-plans/SKILL.md": [
            (
                "> **For agentic workers:** REQUIRED: Use superpowers-lite:subagent-driven-development to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.",
                "> **For agentic workers:** REQUIRED: Use the `subagent-driven-development` skill to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.",
            ),
            (
                "- Reference relevant skills with @ syntax",
                "- Reference relevant skills by name",
            ),
            (
                "**REQUIRED:** Use superpowers-lite:subagent-driven-development for execution.",
                "**REQUIRED:** Use the `subagent-driven-development` skill for execution.",
            ),
        ],
        "skills/brainstorming/spec-document-reviewer-prompt.md": [
            (
                "Task tool (general-purpose):\n  description: \"Review spec document\"\n  prompt: |\n",
                "spawn_agent:\n  agent_type: explorer\n  fork_context: false\n  message: |\n",
            ),
        ],
        "skills/writing-plans/plan-document-reviewer-prompt.md": [
            (
                "Task tool (general-purpose):\n  description: \"Review plan chunk N\"\n  prompt: |\n",
                "spawn_agent:\n  agent_type: explorer\n  fork_context: false\n  message: |\n",
            ),
        ],
        "skills/systematic-debugging/CREATION-LOG.md": [
            (
                "Extracted debugging framework from `/Users/jesse/.claude/CLAUDE.md`:",
                "Extracted debugging framework from `/Users/jesse/.codex/AGENTS.md`:",
            ),
            (
                'When Claude thinks "I\'ll just add this one quick fix",',
                'When the model thinks "I\'ll just add this one quick fix",',
            ),
        ],
        "skills/systematic-debugging/SKILL.md": [
            (
                "- **superpowers-lite:verification-before-completion** - Verify fix worked before claiming success",
                "- **`verification-before-completion`** - Verify fix worked before claiming success",
            ),
        ],
    }


def render_text(text: str, relpath: str, platform: str, logical_root: Path) -> str:
    if platform != "codex":
        return text

    replacements = codex_replacements(logical_root).get(relpath, [])
    for old, new in replacements:
        text = replace_or_die(text, old, new, relpath)
    return text


def copy_tree(src_root: Path, dst_root: Path, platform: str, logical_root: Path) -> None:
    for src_path in sorted(src_root.rglob("*")):
        relpath = src_path.relative_to(src_root)
        dst_path = dst_root / relpath

        if src_path.is_dir():
            dst_path.mkdir(parents=True, exist_ok=True)
            continue

        dst_path.parent.mkdir(parents=True, exist_ok=True)
        if src_path.suffix == ".md":
            rel_text_path = src_path.relative_to(REPO_ROOT).as_posix()
            rendered = render_text(src_path.read_text(), rel_text_path, platform, logical_root)
            dst_path.write_text(rendered)
        else:
            shutil.copy2(src_path, dst_path)


def render_bundle(platform: str, output_dir: Path, logical_root: Path | None = None) -> None:
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True)
    if logical_root is None:
        logical_root = output_dir

    copy_tree(REPO_ROOT / "skills", output_dir / "skills", platform, logical_root)
    copy_tree(REPO_ROOT / "agents", output_dir / "agents", platform, logical_root)

    bootstrap = (REPO_ROOT / "bootstrap.md").read_text()
    rendered_bootstrap = render_text(bootstrap, "bootstrap.md", platform, logical_root)
    bootstrap_name = "bootstrap.md" if platform == "claude" else "AGENTS.md"
    (output_dir / bootstrap_name).write_text(rendered_bootstrap)


REPO_ROOT = Path(__file__).resolve().parent.parent


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", choices=["claude", "codex"], required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--logical-root", type=Path)
    args = parser.parse_args()

    render_bundle(args.platform, args.output, args.logical_root)


if __name__ == "__main__":
    main()
