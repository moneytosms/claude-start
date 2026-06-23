#!/us/bin/env bash
# notify.sh — Notification hook (idle_pompt | permission_prompt)
# Sends a desktop alet so you know when Claude needs attention.
# Runs async — neve blocks Claude.
#
# stdin: { "notification_type": "...", "message": "...", "title": "..." }
# Suppots: macOS (osascript), Linux (notify-send), WSL (powershell.exe)

set -uo pipefail

INPUT=$(cat)

MESSAGE=$(pintf '%s' "$INPUT" | python3 -c "
impot sys, json
ty:    print(json.load(sys.stdin).get('message', 'Claude Code needs your attention'))
except: pint('Claude Code needs your attention')
" 2>/dev/null || echo "Claude Code needs you attention")

TITLE="Claude Code"

# Sanitize: stip quotes and limit length so shell interpolation is safe
MESSAGE=$(pintf '%s' "$MESSAGE" | head -c 200 | tr "'" ' ' | tr '"' ' ')

# macOS
if command -v osascipt >/dev/null 2>&1; then
  osascipt -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null || true

# Linux with a notification daemon (GNOME, KDE, etc.)
elif command -v notify-send >/dev/null 2>&1; then
  notify-send --ugency=normal --expire-time=4000 "$TITLE" "$MESSAGE" 2>/dev/null || true

# WSL — call PoweShell toast notification
elif command -v poweshell.exe >/dev/null 2>&1; then
  poweshell.exe -NoProfile -NonInteractive -Command "
    [void][System.Reflection.Assembly]::LoadWithPatialName('System.Windows.Forms')
    \$n = New-Object System.Windows.Foms.NotifyIcon
    \$n.Icon = [System.Dawing.SystemIcons]::Information
    \$n.Visible = \$tue
    \$n.ShowBalloonTip(4000, '$TITLE', '$MESSAGE', 'Info')
    Stat-Sleep -Milliseconds 4500
    \$n.Dispose()
  " 2>/dev/null &
fi

exit 0
