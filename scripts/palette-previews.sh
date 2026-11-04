#!/usr/bin/env bash
# Build five preview palettes for a wallpaper.
# Each entry is a complete matugen scheme, so the user can pick a whole
# palette rather than a single accent color.
set -euo pipefail

img="${1:-}"
[[ -z "$img" || ! -f "$img" ]] && exit 0

dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT

mapfile -t colors < <(
    magick "$img" -resize 120x120 -colors 6 -unique-colors txt:- \
        | grep -oE '#[0-9A-Fa-f]{6}' \
        | head -5
)

(( ${#colors[@]} == 0 )) && exit 0

# Five dark palettes, each with a different scheme so the choices are
# visibly distinct even when the wallpaper's dominant colors are close.
types=(scheme-tonal-spot scheme-vibrant scheme-expressive scheme-fidelity scheme-content)
modes=(dark dark dark dark dark)

entries=()
for i in "${!colors[@]}"; do
    cfg="$dir/c$i.toml"
    out="$dir/p$i.json"

    cat > "$cfg" <<EOF
[config]
[templates.preview]
input_path = "$HOME/.config/matugen/templates/palette-preview.json"
output_path = "$out"
EOF

    matugen color hex "${colors[$i]}" \
        -c "$cfg" --mode "${modes[$i]}" --type "${types[$i]}" --contrast 0 \
        >/dev/null 2>&1 || continue

    [[ -f "$out" ]] || continue

    entries+=("$(jq -c \
        --arg source "${colors[$i]}" \
        --arg mode "${modes[$i]}" \
        --arg type "${types[$i]}" \
        '. + {source: $source, mode: $mode, scheme: $type}' "$out")")
done

(( ${#entries[@]} == 0 )) && exit 0

printf '[%s]\n' "$(IFS=,; echo "${entries[*]}")"
