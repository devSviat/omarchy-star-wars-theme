#!/bin/bash
# Fetch the wallpapers this theme is built around, and build what derives
# from them:
#
#   ./tools/get-wallpapers.sh
#
# They are third-party Star Wars artwork, so the repository does not ship
# them. This downloads each one from 4kwallpapers.com, refuses any file whose
# SHA-256 differs from the one pinned below, and then:
#
#   - names the Sith wallpaper 00-… so it sorts first (Omarchy's default);
#   - darkens the strip under the bar on the wallpapers listed in
#     tools/bar-scrim.sh;
#   - builds unlock.png, preview-unlock.png and the orrery wallpaper from the
#     Ahsoka orrery artwork (tools/generate-orrery.sh).
#
# Files already present are kept, so it is safe to rerun. The artwork belongs
# to its owners; the downloads are for your own desktop.
set -euo pipefail

cd "$(dirname "$0")/.."
BASE=https://4kwallpapers.com/images/wallpapers

# sha256  source file  name in backgrounds/
WALLPAPERS=(
  "2be9ad6f00f309e86ae262ae739d28430e1eb1218455d896d83f3baa8a458790 sith-star-wars-lightsaber-dark-background-3840x2160-5554.jpg 00-sith-star-wars-lightsaber-dark-background-3840x2160-5554.jpg"
  "a6baccf4087da2625edfdce69455735ad11d9438e4761d893dcd1380bdaae5f8 ahsoka-tano-2023-5650x2160-12818.jpg ahsoka-tano-2023-5650x2160-12818.jpg"
  "9e0ac80047362325cc83bf45463a34eb09a6ec0d03939721b3b296ab44093b11 amandla-stenberg-3840x2160-17156.jpg amandla-stenberg-3840x2160-17156.jpg"
  "df37d0e73d061a0c4123dd0ab1e7148d588b6fec5cb74446978c52c6940e3290 kylo-ren-star-wars-dark-background-lightsaber-cosplay-5k-8k-3840x2160-7587.jpg kylo-ren-star-wars-dark-background-lightsaber-cosplay-5k-8k-3840x2160-7587.jpg"
  "a0780d6391e8cb4a5f5a81aa40cb648bd455ef54b5cf4c70e70f17c3c7a429c8 kylo-ren-star-wars-the-rise-of-skywalker-black-background-3840x2160-873.jpg kylo-ren-star-wars-the-rise-of-skywalker-black-background-3840x2160-873.jpg"
  "cd6cb6656f68657f42cc0c900fe6a618df6ed160eac3790a6bc1603b43cb636f nostalgic-room-3840x2160-17078.jpg nostalgic-room-3840x2160-17078.jpg"
  "8f03e8d35653f82682b10eb1511c7991a18e7b3aac7251db7444948a8ead2625 sev-clone-troopers-star-wars-republic-commando-3840x2160-302.jpg sev-clone-troopers-star-wars-republic-commando-3840x2160-302.jpg"
  "e8a5bec0d2ab5a464b5303d81e503d7b4cf400223ed6cb12f8733727b2ea2c77 star-wars-maul-3840x2160-25269.jpg star-wars-maul-3840x2160-25269.jpg"
  "6d24f8939a7356e3018c320b50ad43da4109f2dc1df8372ca78fdb983f1a1310 the-mandalorian-season-2-tv-series-2020-3840x2160-2765.jpg the-mandalorian-season-2-tv-series-2020-3840x2160-2765.jpg"
)
# The untouched Ahsoka orrery artwork, the input to generate-orrery.sh.
ORRERY="d81fbfc1c4903e68cb587c266f3300fafe538ef806dd32f04a75a7ff08fcc332 star-wars-ahsoka-3840x2160-12833.jpg"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Download one file into $TMP and check it against its pinned hash.
fetch() {
  local sha=$1 name=$2
  curl -fsSL --proto '=https' -A 'Mozilla/5.0' -o "$TMP/$name" "$BASE/$name"
  if [[ $(sha256sum "$TMP/$name" | cut -d' ' -f1) != "$sha" ]]; then
    echo "checksum mismatch for $name — the source file changed; not using it" >&2
    return 1
  fi
}

mkdir -p backgrounds
for entry in "${WALLPAPERS[@]}"; do
  read -r sha source target <<<"$entry"
  if [[ -f backgrounds/$target ]]; then
    echo "have   $target"
    continue
  fi
  fetch "$sha" "$source"
  mv "$TMP/$source" "backgrounds/$target"
  echo "got    $target"
done

./tools/bar-scrim.sh

if [[ ! -f unlock.png || ! -f preview-unlock.png || ! -f backgrounds/star-wars-ahsoka-orrery-3840x2160.png ]]; then
  read -r sha source <<<"$ORRERY"
  fetch "$sha" "$source"
  ./tools/generate-orrery.sh "$TMP/$source"
fi
