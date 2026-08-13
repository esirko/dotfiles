alias mysql-check='i=0; SECONDS=0; until sudo mysql -e "SELECT 1" &>/dev/null; do printf "\rWaiting for MySQL... ${i} tries, ${SECONDS}s elapsed"; i=$((i+1)); sleep 1; done; printf "\rMySQL ready after ${i} tries, ${SECONDS}s elapsed\n"'
alias monolith-check='i=0; SECONDS=0; until [ "$(curl -s -o /dev/null -w "%{http_code}" http://api.github.localhost/octocat)" != "404" ]; do printf "\rWaiting for monolith... ${i} tries, ${SECONDS}s elapsed"; i=$((i+1)); sleep 1; done; printf "\rMonolith ready after ${i} tries, ${SECONDS}s elapsed\n"'
alias launch-check='i=0; SECONDS=0; until ps aux | grep -q "[l]aunch-deployer"; do printf "\rWaiting for launch-deployer... ${i} tries, ${SECONDS}s elapsed"; i=$((i+1)); sleep 1; done; printf "\rlaunch-deployer ready after ${i} tries, ${SECONDS}s elapsed\n"'


newcolor() {
  # === Configurable parameters ===
  SAT_MIN=60        # minimum saturation (0-100)
  SAT_MAX=100       # maximum saturation (0-100)
  VAL_MIN=40        # minimum value (0-100)
  VAL_MAX=60        # maximum value (0-100)
  VAL_BOOST=35      # value increase for titleBar.activeBackground
  SAT_BOOST=10      # saturation increase for titleBar.activeBackground
  SETTINGS_FILE="/workspaces/github/.vscode/settings.json"

  # === Generate random HSV ===
  HUE=$((RANDOM % 360))
  SAT=$((RANDOM % (SAT_MAX - SAT_MIN + 1) + SAT_MIN))
  VAL=$((RANDOM % (VAL_MAX - VAL_MIN + 1) + VAL_MIN))

  # === Compute active title bar HSV (boosted, capped at 100) ===
  SAT_ACTIVE=$((SAT + SAT_BOOST > 100 ? 100 : SAT + SAT_BOOST))
  VAL_ACTIVE=$((VAL + VAL_BOOST > 100 ? 100 : VAL + VAL_BOOST))

  echo "Base HSV: H=$HUE S=$SAT V=$VAL"
  echo "Active HSV: H=$HUE S=$SAT_ACTIVE V=$VAL_ACTIVE"

  # === HSV to RGB hex (pure bash, integer math) ===
  hsv_to_hex() {
    local h=$1 s=$2 v=$3
    # Scale: s and v are 0-100, we work in scaled integers
    # r,g,b will be 0-255
    if [[ $s -eq 0 ]]; then
      local rv=$((v * 255 / 100))
      printf '#%02x%02x%02x' "$rv" "$rv" "$rv"
      return
    fi
    local region=$((h / 60))
    local remainder=$((h % 60))
    # p = v * (100 - s) / 100, scaled to 0-255
    local p=$((v * (100 - s) * 255 / 10000))
    # q = v * (100 - s * remainder / 60) / 100, scaled to 0-255
    local q=$((v * (100 - s * remainder / 60) * 255 / 10000))
    # t = v * (100 - s * (60 - remainder) / 60) / 100, scaled to 0-255
    local t=$((v * (100 - s * (60 - remainder) / 60) * 255 / 10000))
    local vv=$((v * 255 / 100))
    case $region in
      0) printf '#%02x%02x%02x' "$vv" "$t" "$p" ;;
      1) printf '#%02x%02x%02x' "$q" "$vv" "$p" ;;
      2) printf '#%02x%02x%02x' "$p" "$vv" "$t" ;;
      3) printf '#%02x%02x%02x' "$p" "$q" "$vv" ;;
      4) printf '#%02x%02x%02x' "$t" "$p" "$vv" ;;
      *) printf '#%02x%02x%02x' "$vv" "$p" "$q" ;;
    esac
  }

  BASE_HEX=$(hsv_to_hex "$HUE" "$SAT" "$VAL")
  ACTIVE_HEX=$(hsv_to_hex "$HUE" "$SAT_ACTIVE" "$VAL_ACTIVE")

  echo "Base color: $BASE_HEX"
  echo "Active color: $ACTIVE_HEX"

  # === Build replacement block in a temp file ===
  TMPFILE=$(mktemp)
  cat > "$TMPFILE" <<EOF
    "workbench.colorCustomizations": {
      "terminal.foreground": "#EFEFEF",
      "terminal.background": "#202020",
      "activityBar.background": "${BASE_HEX}",
      "titleBar.activeBackground": "${ACTIVE_HEX}",
      "titleBar.activeForeground": "#F3FCF7",
      "titleBar.inactiveBackground": "${BASE_HEX}",
      "titleBar.inactiveForeground": "#F3FCF7",
      "statusBar.background": "${BASE_HEX}",
      "statusBar.foreground": "#F3FCF7",
      "statusBar.debuggingBackground": "${BASE_HEX}",
      "statusBar.debuggingForeground": "#F3FCF7",
      "statusBar.noFolderBackground": "${BASE_HEX}",
      "statusBar.noFolderForeground": "#F3FCF7"
    }
EOF

  # === Replace the block: delete matched range, read in temp file ===
  sed -i "/"'"workbench\.colorCustomizations"'"/,/^  }/ {
    /"'"workbench\.colorCustomizations"'"/ {
      r $TMPFILE
      d
    }
    d
  }" "$SETTINGS_FILE"

  echo "Color TMPFILE xxx: $TMPFILE"
  # rm "$TMPFILE"

  mkdir -p /workspaces/.vscode
  cp /workspaces/github/.vscode/launch.json /workspaces/.vscode
  cp /workspaces/github/.vscode/settings.json /workspaces/.vscode
  cp /workspaces/github/.vscode/tasks.json /workspaces/.vscode
}
