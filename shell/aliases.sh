# Editors
alias helix='hx'
alias v='nvim'
alias hx='hx'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'

# Git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -20'
alias gco='git checkout'

# Django (inside devcontainer)
alias pm='python manage.py'
alias pms='python manage.py shell_plus'
alias pmm='python manage.py migrate'
alias pmk='python manage.py makemigrations'
alias pmt='python manage.py test --keepdb --verbosity=2'

# Docker (from host)
alias dc='docker compose'
alias dce='docker compose exec'

# PATH
export PATH="$HOME/.local/bin:$PATH"
