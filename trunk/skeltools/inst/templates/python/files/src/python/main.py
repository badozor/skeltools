"""Project: {{name}} (created on {{date}})."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
TMP = ROOT / "tmp"


def main() -> None:
    print(f"Project root: {ROOT}")


if __name__ == "__main__":
    main()
