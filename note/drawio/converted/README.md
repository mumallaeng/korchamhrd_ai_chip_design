# Converted draw.io Sources

This folder contains generated conversion outputs for the `.drawio` files in `activities/korcham/notes/drawio`.

Original `.drawio` files are kept unchanged.

## Output Folders

| Folder | Format | Generation basis |
| :--- | :--- | :--- |
| `tikz/` | `.tikz` fragments | Parsed mxGraphModel geometry, labels, and edges |
| `tex/` | standalone LaTeX wrappers | `\input` wrapper for the matching TikZ fragment |
| `svg/` | `.structural.svg` and `.drawio.svg` | Structural SVG from parser and exact SVG exported by draw.io CLI |
| `png/` | `.png` | Rendered from draw.io-exported SVG when possible |
| `pdf/` | `.pdf` | Rendered from draw.io-exported SVG when possible |
| `json/` | normalized graph data | Parsed cells, geometry, styles, pages |
| `dot/` | Graphviz DOT | Source/target mxCell graph where explicit links exist |
| `graphviz-svg/` | DOT rendered SVG | Graphviz rendering of the DOT graph |
| `mermaid/` | Mermaid flowchart | Source/target mxCell graph where explicit links exist |

## Notes

- TikZ, DOT, Mermaid, and structural SVG are source-level approximations. They preserve labels, boxes, coordinates, and explicit source/target edges where possible, but they are not guaranteed to be pixel-identical to draw.io.
- `.drawio.svg` files are exported by the local draw.io CLI and are the closest visual preservation target.
- LaTeX engines were not assumed during generation; TikZ files are source outputs and should be compiled later on a TeX-enabled environment.
- `manifest.csv` lists every source diagram and generated target path.
- `conversion-errors.json` records conversion failures. Empty list means parser conversion succeeded.
