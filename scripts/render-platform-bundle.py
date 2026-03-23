#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


CUSTOM_AGENT_MARKER = "# superpowers-lite:managed"


def replace_or_die(text: str, old: str, new: str, relpath: str) -> str:
    if old not in text:
        raise ValueError(f"Missing expected text in {relpath!r}: {old!r}")
    return text.replace(old, new)


def replace_any_or_die(text: str, olds: list[str], new: str, relpath: str) -> str:
    for old in olds:
        if old in text:
            return text.replace(old, new)
    raise ValueError(f"Missing expected text in {relpath!r}: one of {olds!r}")


def codex_replacements() -> dict[str, list[tuple[str | list[str], str]]]:
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
                "Three custom subagents, dispatched by name via `spawn_agent`:",
            ),
            (
                "```\nAgent tool:\n  subagent_type: implementer\n  prompt: |\n"
                "    Task 3: Implement user authentication endpoint\n\n"
                "    Spec: docs/superpowers/specs/auth-spec.md\n"
                "    Plan: docs/superpowers/plans/auth-plan.md\n"
                "    Work from: .worktrees/feature-auth\n\n"
                "    Context: This builds on the session middleware from Task 2.\n"
                "    The database schema is already in place (see db/schema.ts).\n```",
                "```\nspawn_agent:\n  agent_type: implementer\n  fork_context: false\n  message: |\n"
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
                "```\nspawn_agent:\n  agent_type: spec-reviewer\n  fork_context: false\n  message: |\n"
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
                "Dispatch each reviewer as a subagent via `spawn_agent`, using the matching custom subagent plus the spec/plan paths and git range:",
            ),
            (
                "```\nAgent tool:\n  subagent_type: spec-reviewer\n  prompt: |\n"
                "    Review: [task description]\n"
                "    Spec: [path to spec]\n"
                "    Plan: [path to plan]\n"
                "    Base: [base SHA]\n"
                "    Head: [head SHA]\n```",
                "```\nspawn_agent:\n  agent_type: spec-reviewer\n  fork_context: false\n  message: |\n"
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
                "```\nspawn_agent:\n  agent_type: code-reviewer\n  fork_context: false\n  message: |\n"
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
                [
                    "- **superpowers-lite:verification-before-completion** - Verify fix worked before claiming success",
                    "- **superpowers:verification-before-completion** - Verify fix worked before claiming success",
                ],
                "- **`verification-before-completion`** - Verify fix worked before claiming success",
            ),
        ],
    }


def render_text(text: str, relpath: str, platform: str) -> str:
    if platform != "codex":
        return text

    replacements = codex_replacements().get(relpath, [])
    for old, new in replacements:
        if isinstance(old, list):
            text = replace_any_or_die(text, old, new, relpath)
        else:
            text = replace_or_die(text, old, new, relpath)
    return text


def parse_front_matter(text: str) -> tuple[dict[str, str], str]:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return {}, text

    end_index = None
    for index in range(1, len(lines)):
        if lines[index] == "---":
            end_index = index
            break

    if end_index is None:
        return {}, text

    metadata: dict[str, str] = {}
    front_lines = lines[1:end_index]
    body = "\n".join(lines[end_index + 1 :]).lstrip("\n")

    index = 0
    while index < len(front_lines):
        line = front_lines[index]
        if not line.strip():
            index += 1
            continue

        if line.endswith(": |"):
            key = line.split(":", 1)[0].strip()
            index += 1
            block: list[str] = []
            while index < len(front_lines):
                next_line = front_lines[index]
                if next_line.startswith("  "):
                    block.append(next_line[2:])
                    index += 1
                    continue
                if next_line == "":
                    block.append("")
                    index += 1
                    continue
                break
            metadata[key] = "\n".join(block).rstrip()
            continue

        if ":" in line:
            key, value = line.split(":", 1)
            metadata[key.strip()] = value.strip().strip('"').strip("'")

        index += 1

    return metadata, body


def render_codex_agent(source_path: Path, output_path: Path) -> None:
    metadata, body = parse_front_matter(source_path.read_text())
    name = metadata.get("name", source_path.stem)
    description = " ".join(metadata.get("description", "").split())
    if not description:
        description = f"Superpowers Lite custom subagent: {name}"

    content = "\n".join(
        [
            CUSTOM_AGENT_MARKER,
            f"name = {json.dumps(name)}",
            f"description = {json.dumps(description)}",
            f"developer_instructions = {json.dumps(body.strip())}",
            "",
        ]
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content)


def copy_tree(src_root: Path, dst_root: Path, platform: str) -> None:
    for src_path in sorted(src_root.rglob("*")):
        relpath = src_path.relative_to(src_root)
        dst_path = dst_root / relpath

        if src_path.is_dir():
            dst_path.mkdir(parents=True, exist_ok=True)
            continue

        dst_path.parent.mkdir(parents=True, exist_ok=True)
        if src_path.suffix == ".md":
            rel_text_path = src_path.relative_to(REPO_ROOT).as_posix()
            rendered = render_text(src_path.read_text(), rel_text_path, platform)
            dst_path.write_text(rendered)
        else:
            shutil.copy2(src_path, dst_path)


def render_codex_bundle(output_dir: Path) -> None:
    copy_tree(REPO_ROOT / "skills", output_dir / ".agents" / "skills", "codex")

    agents_root = output_dir / ".codex" / "agents"
    for agent_path in sorted((REPO_ROOT / "agents").glob("*.md")):
        render_codex_agent(agent_path, agents_root / f"{agent_path.stem}.toml")

    bootstrap = (REPO_ROOT / "bootstrap.md").read_text()
    rendered_bootstrap = render_text(bootstrap, "bootstrap.md", "codex")
    (output_dir / "AGENTS.md").write_text(rendered_bootstrap)


def render_bundle(platform: str, output_dir: Path, logical_root: Path | None = None) -> None:
    del logical_root

    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True)

    if platform == "codex":
        render_codex_bundle(output_dir)
        return

    copy_tree(REPO_ROOT / "skills", output_dir / "skills", platform)
    copy_tree(REPO_ROOT / "agents", output_dir / "agents", platform)

    bootstrap = (REPO_ROOT / "bootstrap.md").read_text()
    (output_dir / "bootstrap.md").write_text(bootstrap)


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
