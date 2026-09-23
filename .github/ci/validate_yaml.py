from __future__ import annotations

from pathlib import Path

import yaml


YAML_SUFFIXES = {".yml", ".yaml"}
SKIP_PARTS = {"dbt_packages", "target", ".git"}


def main() -> None:
    yaml_files = [
        path
        for path in Path(".").rglob("*")
        if path.is_file()
        and path.suffix.lower() in YAML_SUFFIXES
        and not any(part in SKIP_PARTS for part in path.parts)
    ]

    if not yaml_files:
        raise SystemExit("No YAML files found.")

    failures: list[str] = []

    for path in sorted(yaml_files):
        try:
            with path.open("r", encoding="utf-8") as handle:
                yaml.safe_load(handle)
            print(f"OK  {path}")
        except Exception as exc:
            failures.append(f"{path}: {exc}")

    if failures:
        print("\nYAML validation failed:")
        for failure in failures:
            print(f" - {failure}")
        raise SystemExit(1)

    print(f"\nValidated {len(yaml_files)} YAML files.")


if __name__ == "__main__":
    main()
