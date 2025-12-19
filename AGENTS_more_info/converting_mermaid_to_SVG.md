# Converting Mermaid Diagrams to SVG

This document describes the procedure used to generate SVG diagrams from Mermaid code for use in the CasualPlots.jl documentation.

## Why SVG?
SVG diagrams are scalable and can be viewed in any modern web browser or image viewer without needing specific Markdown extensions or plugins that support Mermaid. This makes them portable and reliable for inclusion in the repository.

## The Procedure

Since strictly local command-line tools for Mermaid (like `mmdc` from `@mermaid-js/mermaid-cli`) were not available in the environment, we utilized the [Kroki](https://kroki.io) API. Kroki is a free service that renders text-based diagrams into images.

### Steps

1.  **Extract Mermaid Code**: Identify the mermaid code blocks (e.g., `flowchart TD`, `sequenceDiagram`, `stateDiagram-v2`) from the source markdown files.
2.  **Compress**: The source code string is compressed using zlib (level 9).
3.  **Base64 Encode**: The compressed data is then encoded using URL-safe Base64 encoding.
4.  **Construct URL**: The final URL is constructed as:
    `https://kroki.io/mermaid/svg/<payload>`
    where `<payload>` is the compressed and encoded string.
5.  **Download**: A GET request to this URL returns the rendered SVG file, which is then saved to disk.

### Implementation Script (Python)

The python script `tools/mermaid2SVG-utility.py` automates this process. It:
1.  Scans the `AGENTS_more_info/Mermaid/` directory for `.md` files.
2.  Extracts the Mermaid code block from each file.
3.  Applies fixes (e.g., converting escaped `\\n` to `\n` for proper newline rendering).
4.  Generates the corresponding SVG file in `AGENTS_more_info/Diagrams/` via Kroki.

## Maintenance
To update the diagrams:
1.  Modify the Mermaid definitions in `AGENTS_more_info/Mermaid/*.md`.
2.  Run the utility script:
    ```bash
    python3 tools/mermaid2SVG-utility.py
    ```
3.  The SVG files in `AGENTS_more_info/Diagrams/` will be updated automatically.
