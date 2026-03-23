#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import shutil
import stat
import subprocess
import sys
import textwrap
from pathlib import Path


AGENTS_MARKER_START = "<!-- superpowers-lite:start -->"
AGENTS_MARKER_END = "<!-- superpowers-lite:end -->"
EXCLUDE_MARKER_START = "# superpowers-lite:start"
EXCLUDE_MARKER_END = "# superpowers-lite:end"
SKILL_OWNER_MARKER = ".superpowers-lite-owner"


def resolve_path(path: str | Path) -> Path:
    return Path(path).expanduser().resolve()


def path_exists(path: Path) -> bool:
    return path.exists() or path.is_symlink()


def remove_path(path: Path) -> None:
    if not path_exists(path):
        return
    if path.is_symlink() or path.is_file():
        path.unlink()
        return
    shutil.rmtree(path)


def read_text(path: Path) -> str:
    if not path.is_file():
        return ""
    return path.read_text(encoding="utf-8")


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def make_executable(path: Path) -> None:
    current_mode = path.stat().st_mode
    path.chmod(current_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def normalize_path_string(path: str | Path) -> str:
    return os.path.normcase(str(resolve_path(path)))


def path_within(child: str | Path, root: str | Path) -> bool:
    try:
        resolve_path(child).relative_to(resolve_path(root))
        return True
    except ValueError:
        return False


def default_codex_home() -> Path:
    return resolve_path(os.environ.get("CODEX_HOME", str(Path.home() / ".codex")))


def strip_managed_block(text: str, start_marker: str, end_marker: str) -> str:
    result: list[str] = []
    skip = False
    for line in text.splitlines():
        if line == start_marker:
            skip = True
            continue
        if line == end_marker:
            skip = False
            continue
        if not skip:
            result.append(line)

    while result and result[-1] == "":
        result.pop()
    return "\n".join(result)


def update_managed_block_file(path: Path, managed_text: str, start_marker: str, end_marker: str) -> None:
    cleaned = strip_managed_block(read_text(path), start_marker, end_marker).rstrip("\n")
    managed = managed_text.rstrip("\n")

    sections: list[str] = []
    if cleaned:
        sections.append(cleaned)
    sections.append("\n".join([start_marker, managed, end_marker]))
    write_text(path, "\n\n".join(sections) + "\n")


def remove_managed_block_file(path: Path, start_marker: str, end_marker: str) -> None:
    if not path.is_file():
        return
    cleaned = strip_managed_block(read_text(path), start_marker, end_marker)
    if cleaned:
        write_text(path, cleaned.rstrip("\n") + "\n")
    else:
        write_text(path, "")


def render_bootstrap(repo_root: Path) -> None:
    skill_path = repo_root / "skills" / "using-superpowers" / "SKILL.md"
    if not skill_path.is_file():
        raise FileNotFoundError(f"missing skill file: {skill_path}")

    content = (
        "<EXTREMELY_IMPORTANT>\n"
        "You have superpowers.\n\n"
        "**Below is the full content of your 'superpowers-lite:using-superpowers' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**\n\n"
        f"{read_text(skill_path).rstrip()}\n"
        "</EXTREMELY_IMPORTANT>\n"
    )
    write_text(repo_root / "bootstrap.md", content)


def render_codex_bundle(repo_root: Path, output_dir: Path, logical_root: Path) -> None:
    command = [
        sys.executable,
        str(repo_root / "scripts" / "render-platform-bundle.py"),
        "--platform",
        "codex",
        "--output",
        str(output_dir),
        "--logical-root",
        str(logical_root),
    ]
    subprocess.run(command, check=True)


def owner_marker_path(target: Path) -> Path:
    return target / SKILL_OWNER_MARKER


def expected_skill_source(install_root: Path, skill_name: str) -> Path:
    return install_root / "skills" / skill_name


def resolve_link_target(link_path: Path) -> Path:
    raw_target = os.readlink(link_path)
    target_path = Path(raw_target)
    if not target_path.is_absolute():
        target_path = link_path.parent / target_path
    return resolve_path(target_path)


def is_managed_skill_target(target: Path, install_root: Path) -> bool:
    if not path_exists(target):
        return False

    expected_source = expected_skill_source(install_root, target.name)
    expected_source_string = normalize_path_string(expected_source)

    if target.is_symlink():
        try:
            return normalize_path_string(resolve_link_target(target)) == expected_source_string
        except OSError:
            return False

    marker_path = owner_marker_path(target)
    if marker_path.is_file():
        owner = marker_path.read_text(encoding="utf-8").strip()
        return normalize_path_string(owner) == expected_source_string
    return False


def link_or_copy_file(source: Path, destination: Path) -> None:
    if not source.is_file() or path_exists(destination):
        return

    destination.parent.mkdir(parents=True, exist_ok=True)
    try:
        destination.symlink_to(source)
    except OSError:
        shutil.copy2(source, destination)


def install_skill_target(source_skill: Path, target: Path) -> None:
    remove_path(target)

    try:
        target.symlink_to(source_skill, target_is_directory=True)
        return
    except OSError:
        pass

    shutil.copytree(source_skill, target)
    write_text(owner_marker_path(target), f"{resolve_path(source_skill)}\n")


def validate_skill_targets(staging_root: Path, codex_home: Path, install_root: Path) -> None:
    skills_root = codex_home / "skills"
    for skill_dir in sorted((staging_root / "skills").iterdir()):
        if not skill_dir.is_dir():
            continue

        target = skills_root / skill_dir.name
        if path_exists(target) and not is_managed_skill_target(target, install_root):
            raise RuntimeError(f"refusing to replace existing path: {target}")


def install_global(repo_root: Path, codex_home: Path, install_root: Path | None = None) -> None:
    codex_home = resolve_path(codex_home)
    install_root = resolve_path(install_root or (codex_home / "vendor_imports" / "superpowers-lite"))
    staging_root = Path(f"{install_root}.tmp")

    render_bootstrap(repo_root)
    (codex_home / "skills").mkdir(parents=True, exist_ok=True)
    install_root.parent.mkdir(parents=True, exist_ok=True)

    remove_path(staging_root)
    render_codex_bundle(repo_root, staging_root, install_root)
    validate_skill_targets(staging_root, codex_home, install_root)

    remove_path(install_root)
    shutil.move(str(staging_root), str(install_root))

    for skill_dir in sorted((install_root / "skills").iterdir()):
        if not skill_dir.is_dir():
            continue
        install_skill_target(skill_dir, codex_home / "skills" / skill_dir.name)

    update_managed_block_file(
        codex_home / "AGENTS.md",
        read_text(install_root / "AGENTS.md"),
        AGENTS_MARKER_START,
        AGENTS_MARKER_END,
    )

    print(f"Installed Codex bundle to {install_root}")
    print(f"Linked skills into {codex_home / 'skills'}")
    print(f"Updated {codex_home / 'AGENTS.md'} with managed Superpowers Lite bootstrap block")


def uninstall_global(codex_home: Path, install_root: Path | None = None) -> None:
    codex_home = resolve_path(codex_home)
    install_root = resolve_path(install_root or (codex_home / "vendor_imports" / "superpowers-lite"))
    skills_root = codex_home / "skills"

    if skills_root.is_dir():
        for target in skills_root.iterdir():
            if is_managed_skill_target(target, install_root):
                remove_path(target)

    remove_managed_block_file(codex_home / "AGENTS.md", AGENTS_MARKER_START, AGENTS_MARKER_END)
    remove_path(install_root)

    print(f"Removed Codex bundle from {install_root}")
    print(f"Removed managed Superpowers Lite bootstrap block from {codex_home / 'AGENTS.md'}")


def sh_quote(value: str | Path) -> str:
    return "'" + str(value).replace("'", "'\"'\"'") + "'"


def ps_quote(value: str | Path) -> str:
    return "'" + str(value).replace("'", "''") + "'"


def cmd_escape(value: str | Path) -> str:
    return str(value).replace("%", "%%").replace('"', '""')


def windows_ps_sibling(path: Path) -> Path:
    return path.with_suffix(".ps1") if path.suffix else Path(f"{path}.ps1")


def windows_cmd_sibling(path: Path) -> Path:
    return path.with_suffix(".cmd") if path.suffix else Path(f"{path}.cmd")


def build_shell_launcher(project_root: Path, codex_home: Path) -> str:
    return textwrap.dedent(
        f"""\
        #!/usr/bin/env bash

        set -euo pipefail

        PROJECT_ROOT={sh_quote(project_root)}
        CODEX_HOME={sh_quote(codex_home)}

        cd "$PROJECT_ROOT"
        export CODEX_HOME
        CODEX_BIN="${{CODEX_BIN:-codex}}"

        if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
            printf 'superpowers-lite launcher: command not found: %s\\n' "$CODEX_BIN" >&2
            exit 127
        fi

        exec "$CODEX_BIN" "$@"
        """
    )


def build_shell_uninstaller(project_root: Path, artifact_root: Path) -> str:
    return textwrap.dedent(
        f"""\
        #!/usr/bin/env bash

        set -euo pipefail

        PROJECT_ROOT={sh_quote(project_root)}
        ARTIFACT_ROOT={sh_quote(artifact_root)}
        EXCLUDE_MARKER_START={sh_quote(EXCLUDE_MARKER_START)}
        EXCLUDE_MARKER_END={sh_quote(EXCLUDE_MARKER_END)}

        remove_git_exclude() {{
            if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                return 0
            fi

            local exclude_file
            local tmp_file
            exclude_file="$(cd "$PROJECT_ROOT" && git rev-parse --git-path info/exclude)"
            case "$exclude_file" in
                /*) ;;
                *) exclude_file="${{PROJECT_ROOT}}/${{exclude_file}}" ;;
            esac

            if [ ! -f "$exclude_file" ]; then
                return 0
            fi

            tmp_file="$(mktemp "${{TMPDIR:-/tmp}}/superpowers-lite-exclude.XXXXXX")"
            awk -v start="$EXCLUDE_MARKER_START" -v end="$EXCLUDE_MARKER_END" '
                $0 == start {{ skip = 1; next }}
                $0 == end {{ skip = 0; next }}
                !skip {{ print }}
            ' "$exclude_file" > "$tmp_file"
            mv "$tmp_file" "$exclude_file"
        }}

        remove_git_exclude
        printf 'Removing project-local Superpowers Lite from %s\\n' "$ARTIFACT_ROOT"
        exec /bin/sh -c 'rm -rf "$1"' sh "$ARTIFACT_ROOT"
        """
    )


def build_cmd_launcher(project_root: Path, codex_home: Path) -> str:
    return textwrap.dedent(
        f"""\
        @echo off
        setlocal

        set "SUPERPOWERS_LITE_PROJECT_ROOT={cmd_escape(project_root)}"
        set "SUPERPOWERS_LITE_CODEX_HOME={cmd_escape(codex_home)}"
        if defined CODEX_BIN (
            set "SUPERPOWERS_LITE_CODEX_BIN=%CODEX_BIN%"
        ) else (
            set "SUPERPOWERS_LITE_CODEX_BIN=codex"
        )

        cd /d "%SUPERPOWERS_LITE_PROJECT_ROOT%"
        set "CODEX_HOME=%SUPERPOWERS_LITE_CODEX_HOME%"
        "%SUPERPOWERS_LITE_CODEX_BIN%" %*
        """
    )


def build_ps_launcher(project_root: Path, codex_home: Path) -> str:
    return textwrap.dedent(
        f"""\
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        Set-Location -LiteralPath {ps_quote(project_root)}
        $env:CODEX_HOME = {ps_quote(codex_home)}
        $codexBin = if ($env:CODEX_BIN) {{ $env:CODEX_BIN }} else {{ 'codex' }}

        & $codexBin @args
        exit $LASTEXITCODE
        """
    )


def build_cmd_uninstaller() -> str:
    return textwrap.dedent(
        """\
        @echo off
        setlocal

        "%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
        """
    )


def build_ps_uninstaller(project_root: Path, artifact_root: Path) -> str:
    cleanup_artifact_root = cmd_escape(artifact_root)
    return textwrap.dedent(
        f"""\
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        $ProjectRoot = {ps_quote(project_root)}
        $ArtifactRoot = {ps_quote(artifact_root)}
        $ExcludeMarkerStart = {ps_quote(EXCLUDE_MARKER_START)}
        $ExcludeMarkerEnd = {ps_quote(EXCLUDE_MARKER_END)}

        function Write-Utf8File([string]$Path, [string]$Content) {{
            $directory = Split-Path -Parent $Path
            if ($directory) {{
                New-Item -ItemType Directory -Force -Path $directory | Out-Null
            }}

            $encoding = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($Path, $Content, $encoding)
        }}

        function Remove-ManagedBlockText([string]$Content, [string]$StartMarker, [string]$EndMarker) {{
            $result = New-Object System.Collections.Generic.List[string]
            $skip = $false

            foreach ($line in ($Content -split "`r?`n")) {{
                if ($line -eq $StartMarker) {{
                    $skip = $true
                    continue
                }}

                if ($line -eq $EndMarker) {{
                    $skip = $false
                    continue
                }}

                if (-not $skip) {{
                    $null = $result.Add($line)
                }}
            }}

            while ($result.Count -gt 0 -and $result[$result.Count - 1] -eq '') {{
                $result.RemoveAt($result.Count - 1)
            }}

            return [string]::Join("`n", $result)
        }}

        function Get-GitExcludePath() {{
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {{
                return $null
            }}

            & git -C $ProjectRoot rev-parse --is-inside-work-tree 1>$null 2>$null
            if ($LASTEXITCODE -ne 0) {{
                return $null
            }}

            $gitPath = (& git -C $ProjectRoot rev-parse --git-path info/exclude 2>$null | Select-Object -First 1)
            if (-not $gitPath) {{
                return $null
            }}

            $gitPath = $gitPath.Trim()
            if ([System.IO.Path]::IsPathRooted($gitPath)) {{
                return $gitPath
            }}

            return Join-Path $ProjectRoot $gitPath
        }}

        function Remove-GitExcludeBlock() {{
            $excludePath = Get-GitExcludePath
            if (-not $excludePath -or -not (Test-Path -LiteralPath $excludePath)) {{
                return
            }}

            $existing = Get-Content -LiteralPath $excludePath -Raw
            $cleaned = Remove-ManagedBlockText -Content $existing -StartMarker $ExcludeMarkerStart -EndMarker $ExcludeMarkerEnd
            if ($cleaned.Length -gt 0) {{
                $cleaned = $cleaned.TrimEnd("`r", "`n") + "`n"
            }}

            Write-Utf8File -Path $excludePath -Content $cleaned
        }}

        Remove-GitExcludeBlock
        Write-Host "Removing project-local Superpowers Lite from $ArtifactRoot"

        $cleanupPath = Join-Path ([System.IO.Path]::GetTempPath()) ("superpowers-lite-uninstall-" + [Guid]::NewGuid().ToString() + ".cmd")
        $cleanupContent = "@echo off`r`nping 127.0.0.1 -n 2 >nul`r`nrmdir /s /q ""{cleanup_artifact_root}""`r`ndel ""%~f0""`r`n"
        Write-Utf8File -Path $cleanupPath -Content $cleanupContent

        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cleanupPath -WindowStyle Hidden | Out-Null
        """
    )


def write_project_helpers(project_root: Path, artifact_root: Path, codex_home: Path) -> None:
    shell_launcher = artifact_root / "codex"
    shell_uninstaller = artifact_root / "uninstall"
    cmd_launcher = artifact_root / "codex.cmd"
    ps_launcher = artifact_root / "codex.ps1"
    cmd_uninstaller = artifact_root / "uninstall.cmd"
    ps_uninstaller = artifact_root / "uninstall.ps1"

    write_text(shell_launcher, build_shell_launcher(project_root, codex_home))
    write_text(shell_uninstaller, build_shell_uninstaller(project_root, artifact_root))
    write_text(cmd_launcher, build_cmd_launcher(project_root, codex_home))
    write_text(ps_launcher, build_ps_launcher(project_root, codex_home))
    write_text(cmd_uninstaller, build_cmd_uninstaller())
    write_text(ps_uninstaller, build_ps_uninstaller(project_root, artifact_root))

    make_executable(shell_launcher)
    make_executable(shell_uninstaller)


def git_exclude_path(project_root: Path) -> Path | None:
    try:
        subprocess.run(
            ["git", "-C", str(project_root), "rev-parse", "--is-inside-work-tree"],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

    result = subprocess.run(
        ["git", "-C", str(project_root), "rev-parse", "--git-path", "info/exclude"],
        check=True,
        capture_output=True,
        text=True,
    )
    relative_path = result.stdout.strip()
    if not relative_path:
        return None

    candidate = Path(relative_path)
    return candidate if candidate.is_absolute() else project_root / candidate


def ensure_git_exclude(project_root: Path, artifact_root: Path) -> None:
    default_artifact_root = project_root / ".superpowers-lite"
    if normalize_path_string(artifact_root) != normalize_path_string(default_artifact_root):
        return

    exclude_path = git_exclude_path(project_root)
    if exclude_path is None:
        return

    existing = read_text(exclude_path).rstrip("\n")
    if EXCLUDE_MARKER_START in existing.splitlines():
        return

    sections: list[str] = []
    if existing:
        sections.append(existing)
    sections.append("\n".join([EXCLUDE_MARKER_START, ".superpowers-lite/", EXCLUDE_MARKER_END]))
    write_text(exclude_path, "\n\n".join(sections) + "\n")


def remove_git_exclude(project_root: Path) -> None:
    exclude_path = git_exclude_path(project_root)
    if exclude_path is None or not exclude_path.is_file():
        return

    cleaned = strip_managed_block(read_text(exclude_path), EXCLUDE_MARKER_START, EXCLUDE_MARKER_END)
    if cleaned:
        write_text(exclude_path, cleaned.rstrip("\n") + "\n")
    else:
        write_text(exclude_path, "")


def install_project(
    repo_root: Path,
    project_root: Path,
    artifact_root: Path | None = None,
    codex_home: Path | None = None,
    global_codex_home: Path | None = None,
    inherit_global_config: bool = True,
) -> None:
    project_root = resolve_path(project_root)
    artifact_root = resolve_path(artifact_root or (project_root / ".superpowers-lite"))
    codex_home = resolve_path(codex_home or (artifact_root / "codex-home"))
    global_codex_home = resolve_path(global_codex_home or default_codex_home())

    artifact_root.mkdir(parents=True, exist_ok=True)
    codex_home.mkdir(parents=True, exist_ok=True)

    if inherit_global_config:
        link_or_copy_file(global_codex_home / "config.toml", codex_home / "config.toml")
        link_or_copy_file(global_codex_home / "auth.json", codex_home / "auth.json")

    install_global(repo_root, codex_home)
    write_project_helpers(project_root, artifact_root, codex_home)
    ensure_git_exclude(project_root, artifact_root)

    print(f"Installed project-local Codex home to {codex_home}")
    print(f"Created launcher at {artifact_root / 'codex'}")
    print(f"Created Windows launcher at {artifact_root / 'codex.cmd'}")
    print(f"Created uninstaller at {artifact_root / 'uninstall'}")
    print(f"Created Windows uninstaller at {artifact_root / 'uninstall.cmd'}")
    print(f"Start Codex for this project with: {artifact_root / 'codex'}")


def uninstall_project(
    project_root: Path,
    artifact_root: Path | None = None,
    codex_home: Path | None = None,
    install_root: Path | None = None,
) -> None:
    project_root = resolve_path(project_root)
    artifact_root = resolve_path(artifact_root or (project_root / ".superpowers-lite"))
    codex_home = resolve_path(codex_home or (artifact_root / "codex-home"))

    if path_exists(codex_home) and not path_within(codex_home, artifact_root):
        uninstall_global(codex_home, install_root)

    remove_git_exclude(project_root)
    remove_path(artifact_root)

    print(f"Removed project-local Codex home from {codex_home}")
    print(f"Removed project launcher at {artifact_root / 'codex'}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    install_global_parser = subparsers.add_parser("install-global")
    install_global_parser.add_argument("--repo-root", required=True, type=Path)
    install_global_parser.add_argument("--codex-home", type=Path)
    install_global_parser.add_argument("--install-root", type=Path)

    uninstall_global_parser = subparsers.add_parser("uninstall-global")
    uninstall_global_parser.add_argument("--codex-home", type=Path)
    uninstall_global_parser.add_argument("--install-root", type=Path)

    install_project_parser = subparsers.add_parser("install-project")
    install_project_parser.add_argument("--repo-root", required=True, type=Path)
    install_project_parser.add_argument("--project-root", required=True, type=Path)
    install_project_parser.add_argument("--artifact-root", type=Path)
    install_project_parser.add_argument("--codex-home", type=Path)
    install_project_parser.add_argument("--global-codex-home", type=Path)
    install_project_parser.add_argument("--no-inherit-global-config", action="store_true")

    uninstall_project_parser = subparsers.add_parser("uninstall-project")
    uninstall_project_parser.add_argument("--project-root", required=True, type=Path)
    uninstall_project_parser.add_argument("--artifact-root", type=Path)
    uninstall_project_parser.add_argument("--codex-home", type=Path)
    uninstall_project_parser.add_argument("--install-root", type=Path)

    return parser.parse_args()


def main() -> None:
    args = parse_args()

    if args.command == "install-global":
        install_global(resolve_path(args.repo_root), args.codex_home or default_codex_home(), args.install_root)
        return

    if args.command == "uninstall-global":
        uninstall_global(args.codex_home or default_codex_home(), args.install_root)
        return

    if args.command == "install-project":
        install_project(
            repo_root=resolve_path(args.repo_root),
            project_root=args.project_root,
            artifact_root=args.artifact_root,
            codex_home=args.codex_home,
            global_codex_home=args.global_codex_home,
            inherit_global_config=not args.no_inherit_global_config,
        )
        return

    if args.command == "uninstall-project":
        uninstall_project(
            project_root=args.project_root,
            artifact_root=args.artifact_root,
            codex_home=args.codex_home,
            install_root=args.install_root,
        )
        return

    raise RuntimeError(f"unsupported command: {args.command}")


if __name__ == "__main__":
    main()
