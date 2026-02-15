{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        {
          pkgs,
          ...
        }:
        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              zola
              nodePackages.prettier
              markdownlint-cli
              libwebp

              (writeShellScriptBin "fix" ''
                echo "Running Prettier..."
                prettier --write "content/**/*.md"
                echo "Done."
              '')

              (writeShellScriptBin "check" ''
                echo "Running Markdownlint..."
                markdownlint "content/**/*.md"
              '')

              (writeShellScriptBin "convert" ''
                #!/usr/bin/env bash
                if [ -z "$1" ]; then
                  echo "Usage: convert <image-file>"
                  exit 1
                fi

                INPUT_FILE="$1"
                OUTPUT_FILE="''${INPUT_FILE%.*}.webp"

                echo "Converting $INPUT_FILE to $OUTPUT_FILE..."

                cwebp -q 80 "$INPUT_FILE" -o "$OUTPUT_FILE"

                echo "Done!"
              '')

              (writeShellScriptBin "new" ''
                #!/usr/bin/env bash
                if [ -z "$1" ]; then
                    read -p "Enter filename: " SLUG
                else
                    SLUG="$1"
                fi
                SLUG=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
                if [ -z "$SLUG" ]; then echo "Error: Slug required."; exit 1; fi
                DATE=$(date +%F)
                FILENAME="content/blog/''${DATE}-''${SLUG}.md"
                if [ -f "$FILENAME" ]; then echo "Error: Exists."; exit 1; fi

                cat <<EOF > "$FILENAME"
                +++
                title = "TITLE_IS_MISSING"
                description = ""
                date = ''${DATE}
                updated = ''${DATE}
                draft = true

                [taxonomies]
                tags = []

                [extra]
                lang = "ja"
                toc = true
                comment = false
                copy = true
                outdate_alert = false
                outdate_alert_days = 180
                math = false
                mermaid = false
                featured = false
                reaction = false
                +++;

                ここに本文を入力
                EOF
                echo "Created: $FILENAME"
              '')
            ];
          };
        };
    };
}
