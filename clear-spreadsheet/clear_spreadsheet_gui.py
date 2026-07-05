#!/usr/bin/env python3
"""Simple drag-and-drop GUI for cleaning one or more .xlsx files."""

from __future__ import annotations

import sys
from pathlib import Path

from clear_spreadsheet import build_output_path, clean_workbook

try:
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk
except ImportError:  # pragma: no cover - depends on local Python build
    tk = None
    filedialog = None
    messagebox = None
    ttk = None

try:
    from tkinterdnd2 import DND_FILES, TkinterDnD
except ImportError:  # pragma: no cover - optional dependency on build machines only
    DND_FILES = None
    TkinterDnD = None


APP_TITLE = "clear-spreadsheet"


def unique_paths(paths: list[Path]) -> list[Path]:
    """Preserve order while removing duplicates after path normalization."""
    result: list[Path] = []
    seen: set[Path] = set()
    for path in paths:
        resolved = path.expanduser().resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        result.append(resolved)
    return result


def supported_xlsx_paths(paths: list[str | Path]) -> tuple[list[Path], list[Path]]:
    """Split candidate files into supported .xlsx files and everything else."""
    supported: list[Path] = []
    rejected: list[Path] = []
    for raw in paths:
        path = Path(raw).expanduser()
        if path.suffix.lower() == ".xlsx":
            supported.append(path)
        else:
            rejected.append(path)
    return unique_paths(supported), unique_paths(rejected)


class SpreadsheetCleanerGUI:
    def __init__(self) -> None:
        if tk is None or ttk is None or filedialog is None or messagebox is None:
            raise RuntimeError(
                "tkinter is not available in this Python build. "
                "Use a Python installation that includes Tk."
            )

        self.root = TkinterDnD.Tk() if TkinterDnD is not None else tk.Tk()
        self.root.title(APP_TITLE)
        self.root.geometry("760x540")
        self.root.minsize(680, 460)

        self.overwrite_existing = tk.BooleanVar(value=True)
        self.status_text = tk.StringVar(
            value="Drop one or more .xlsx files here, or click Add Files."
        )

        self.files: list[Path] = []
        self._build_ui()
        self._register_drop_targets()
        self._add_paths_from_cli(sys.argv[1:])

    def _build_ui(self) -> None:
        frame = ttk.Frame(self.root, padding=16)
        frame.pack(fill="both", expand=True)

        title = ttk.Label(
            frame,
            text="Drag and drop Excel files to clean hidden theme/table styling",
            font=("", 14, "bold"),
            wraplength=680,
        )
        title.pack(anchor="w")

        subtitle = ttk.Label(
            frame,
            text=(
                "The cleaned file is written next to the original as "
                "<filename>.cleaned.xlsx."
            ),
            wraplength=680,
        )
        subtitle.pack(anchor="w", pady=(6, 12))

        self.drop_zone = tk.Label(
            frame,
            text="Drop .xlsx files here",
            relief="groove",
            bd=2,
            padx=12,
            pady=28,
            bg="#f5f7fb",
            fg="#1f2937",
            font=("", 12, "bold"),
        )
        self.drop_zone.pack(fill="x")

        controls = ttk.Frame(frame)
        controls.pack(fill="x", pady=(12, 8))

        ttk.Button(controls, text="Add Files", command=self._choose_files).pack(
            side="left"
        )
        ttk.Button(controls, text="Clear List", command=self._clear_files).pack(
            side="left", padx=(8, 0)
        )
        ttk.Checkbutton(
            controls,
            text="Overwrite existing .cleaned.xlsx files",
            variable=self.overwrite_existing,
        ).pack(side="right")

        self.file_list = tk.Listbox(frame, activestyle="none")
        self.file_list.pack(fill="both", expand=True, pady=(0, 8))

        ttk.Button(frame, text="Clean Files", command=self._clean_files).pack(
            anchor="e", pady=(0, 10)
        )

        ttk.Label(
            frame, textvariable=self.status_text, wraplength=680, justify="left"
        ).pack(anchor="w")

    def _register_drop_targets(self) -> None:
        if DND_FILES is None:
            self.drop_zone.config(text="Drag-and-drop unavailable. Use Add Files.")
            self.status_text.set(
                "tkinterdnd2 is not installed, so drag-and-drop is disabled."
            )
            return

        # Register both the highlighted drop area and the list so repeated drops
        # remain convenient after the first batch has already been added.
        for widget in (self.drop_zone, self.file_list):
            widget.drop_target_register(DND_FILES)
            widget.dnd_bind("<<Drop>>", self._on_drop)

    def _parse_drop_event(self, data: str) -> list[Path]:
        raw_items = self.root.tk.splitlist(data)
        return [Path(item) for item in raw_items]

    def _on_drop(self, event) -> None:
        self._add_paths(self._parse_drop_event(event.data))

    def _add_paths_from_cli(self, argv: list[str]) -> None:
        if not argv:
            return
        self._add_paths([Path(arg) for arg in argv])

    def _choose_files(self) -> None:
        selected = filedialog.askopenfilenames(
            title="Choose Excel files",
            filetypes=[("Excel Workbook", "*.xlsx")],
        )
        self._add_paths([Path(item) for item in selected])

    def _add_paths(self, paths: list[Path]) -> None:
        accepted, rejected = supported_xlsx_paths(paths)
        added = 0
        existing = {path.resolve() for path in self.files}

        for path in accepted:
            resolved = path.resolve()
            if resolved in existing:
                continue
            self.files.append(resolved)
            self.file_list.insert("end", str(resolved))
            existing.add(resolved)
            added += 1

        if rejected:
            self.status_text.set(
                f"Added {added} file(s). Ignored {len(rejected)} non-.xlsx file(s)."
            )
        elif added:
            self.status_text.set(f"Added {added} file(s).")
        elif accepted:
            self.status_text.set("Those files are already in the list.")

    def _clear_files(self) -> None:
        self.files.clear()
        self.file_list.delete(0, "end")
        self.status_text.set("File list cleared.")

    def _clean_files(self) -> None:
        if not self.files:
            messagebox.showinfo(APP_TITLE, "Add at least one .xlsx file first.")
            return

        successes: list[Path] = []
        failures: list[str] = []

        for path in self.files:
            output_path = build_output_path(path, "cleaned")
            try:
                summary = clean_workbook(
                    input_path=path,
                    output_path=output_path,
                    overwrite=self.overwrite_existing.get(),
                )
                successes.append(summary.output_path)
            except Exception as exc:  # pragma: no cover - exercised by manual runs
                failures.append(f"{path.name}: {exc}")

        if successes and not failures:
            lines = ["Done.", "Output file(s):"]
            lines.extend(f"- {path}" for path in successes)
            self.status_text.set("\n".join(lines))
            if len(successes) == 1:
                dialog_lines = ["Done.", str(successes[0])]
            else:
                dialog_lines = ["Done.", f"{len(successes)} file(s) written."]
            messagebox.showinfo(APP_TITLE, "\n".join(dialog_lines))
            return

        summary_lines = []
        if successes:
            summary_lines.append(f"Done: {len(successes)} file(s)")
        if failures:
            summary_lines.append("Failed:")
            summary_lines.extend(failures)
        messagebox.showwarning(APP_TITLE, "\n".join(summary_lines))
        self.status_text.set("\n".join(summary_lines))

    def run(self) -> None:
        self.root.mainloop()


def main() -> int:
    app = SpreadsheetCleanerGUI()
    app.run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
