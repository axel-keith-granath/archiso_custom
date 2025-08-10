# /root/.zprofile: Executed by Zsh on login.
#
# Check if we are on the main console (tty1), tmux is installed,
# and we are not already inside a tmux session.
if [ "$(tty)" = "/dev/tty1" ] && command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    # Start a new tmux session and run our welcome script in the first window.
    # It will leave a shell open after the script finishes.
    tmux new-session -s "main" -n "Welcome" "sh /root/interactive-script.sh; zsh"
fi