#
# zsh-cache : cache tools for zsh commands
#
# this module can be disabled with 'export SCWRYPTS__ZSH_CACHE_ENABLED=false'
# all library functions implement pass-through mocks so code does not break when disabled
#
normalize.boolean --mode export --variable SCWRYPTS__ZSH_CACHE_ENABLED --default true >/dev/null

# primary cache command 'zsh-cache()' which caches output for the current runtime
use zsh-cache/command-output

# invoke to manually reset cache; provides { .all | .persistent | .runtime }
use zsh-cache/reset
