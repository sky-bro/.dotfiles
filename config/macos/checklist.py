"""Edit the software and configuration choices in an interactive terminal."""

import curses
import os
import subprocess
import sys
from dataclasses import dataclass, field


def installed_packages(*command):
    env = dict(os.environ, HOMEBREW_NO_AUTO_UPDATE="1")
    try:
        result = subprocess.run(
            command, stdin=subprocess.DEVNULL, capture_output=True,
            text=True, check=True, env=env, timeout=5,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    return {line.split()[0] for line in result.stdout.splitlines() if line.strip()}


@dataclass
class Choice:
    default: str
    selected: bool
    configuration: bool
    installed: list = field(default_factory=list)

    def status(self):
        if self.configuration:
            return "Configuration"
        count = self.installed.count(True)
        total = len(self.installed)
        if count == total:
            return "Installed"
        if None in self.installed:
            return "Unknown" if not count else f"{count}/{total} detected"
        return f"Partial ({count}/{total})" if count else "Not installed"


def read_choices(rows):
    inventory = {
        "brew": installed_packages("brew", "list", "--formula", "--full-name"),
        "cask": installed_packages("brew", "list", "--cask", "-1"),
        "mas": installed_packages("mas", "list"),
    }
    choices = {}
    for row in rows.splitlines():
        name, default, selected, kind, install_id = row.split("\t")
        choice = choices.setdefault(name, Choice(default, selected == "on", kind == "config"))
        if kind == "config":
            continue
        if kind == "plugin":
            choice.installed.append(install_id == "yes")
            continue
        installed = inventory[kind]
        choice.installed.append(None if installed is None else install_id in installed)
    return list(choices.items())


def checklist(screen, choices):
    cursor = 0
    start = 0
    while True:
        screen.erase()
        height, width = screen.getmaxyx()
        if height >= 7 and width >= 46:
            visible = height - 6
            start = min(start, max(0, len(choices) - visible))
            start = max(0, min(start, cursor), cursor - visible + 1)
            screen.addnstr(0, 0, "Software and configuration", width - 1, curses.A_BOLD)
            screen.addnstr(2, 0, "    Item                    Default  Status", width - 1)
            for row, (name, choice) in enumerate(choices[start : start + visible], start=3):
                box = "[x]" if choice.selected else "[ ]"
                text = f"{box} {name:23} {choice.default:8} {choice.status()}"
                style = curses.A_REVERSE if start + row - 3 == cursor else curses.A_NORMAL
                screen.addnstr(row, 0, text, width - 1, style)
            screen.addnstr(height - 3, 0, f"{cursor + 1}/{len(choices)}", width - 1)
            screen.addnstr(height - 2, 0, "S  Software off/defaults   C  Config off/defaults", width - 1)
            screen.addnstr(height - 1, 0, "Up/Down  Space toggle  Enter review  Esc cancel", width - 1)
        else:
            screen.addnstr(0, 0, "Enlarge terminal or press Esc to cancel", width - 1)
        key = screen.getch()
        if key in (27, ord("q")):
            return False
        if key == curses.KEY_UP:
            cursor = max(0, cursor - 1)
        elif key == curses.KEY_DOWN:
            cursor = min(len(choices) - 1, cursor + 1)
        elif key == ord(" "):
            choices[cursor][1].selected = not choices[cursor][1].selected
        elif key in (ord("s"), ord("S"), ord("c"), ord("C")):
            configuration = key in (ord("c"), ord("C"))
            section = [choice for _, choice in choices if choice.configuration == configuration]
            restore_defaults = not any(choice.selected for choice in section)
            for choice in section:
                choice.selected = restore_defaults and choice.default == "on"
        elif key in (10, 13, curses.KEY_ENTER):
            return True


def main():
    if not sys.argv[1]:
        print("No setup choices available.")
        return 0
    print("Reading installed packages...", flush=True)
    choices = read_choices(sys.argv[1])
    try:
        if not curses.wrapper(checklist, choices):
            return 130
    except KeyboardInterrupt:
        return 130
    except curses.error:
        print("Cannot open the checklist. Check TERM, or use --check.", file=sys.stderr)
        return 2
    # The terminal stays on stdout. Descriptor 3 carries the choices back to setup.sh.
    with os.fdopen(3, "w") as result:
        for name, choice in choices:
            action = "with" if choice.selected else "without"
            print(f"{action}:{name}", file=result)
    return 0


if __name__ == "__main__":
    sys.exit(main())
