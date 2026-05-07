#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
template_path="$repo_root/matugen/templates/quickshell-colors.json"
output_path="$HOME/.cache/quickshell-dev-colorscheme/colors.json"
mode="dark"
scheme="scheme-tonal-spot"
image_path=""
source_color=""

usage() {
    printf 'Usage: %s (--image PATH | --color HEX) [--mode dark|light] [--scheme SCHEME] [--output PATH]\n' "$0" >&2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image)
            image_path="${2:-}"
            shift 2
            ;;
        --color)
            source_color="${2:-}"
            shift 2
            ;;
        --mode)
            mode="${2:-}"
            shift 2
            ;;
        --scheme)
            scheme="${2:-}"
            shift 2
            ;;
        --output)
            output_path="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 2
            ;;
    esac
done

if [[ -n "$image_path" && -n "$source_color" ]] || [[ -z "$image_path" && -z "$source_color" ]]; then
    usage
    exit 2
fi

if [[ "$mode" != "dark" && "$mode" != "light" ]]; then
    usage
    exit 2
fi

if [[ ! -f "$template_path" ]]; then
    printf 'Missing matugen template: %s\n' "$template_path" >&2
    exit 1
fi

mkdir -p "$(dirname "$output_path")"

tmp_config="$(mktemp)"
trap 'rm -f "$tmp_config"' EXIT

cat > "$tmp_config" <<EOF
[config]
version_check = false

[templates.quickshell]
input_path = '$template_path'
output_path = '$output_path'
EOF

if [[ -n "$image_path" ]]; then
    matugen --source-color-index 0 image "$image_path" --mode "$mode" --type "$scheme" -c "$tmp_config"
else
    matugen color hex "$source_color" --mode "$mode" --type "$scheme" -c "$tmp_config"
fi

touch "$output_path"
