#!/bin/bash
# Antigravity CLI Air Liquide branding & environment setup
export AGY_CLI_HIDE_LOGO=1

agy() {
  if [ -t 1 ]; then
    case " $* " in
      *" --version "*|*" -v "*|*" --help "*|*" -h "*|*" --print "*|*" -p "*|*" --output-format "*) ;;
      *)
        if [ -x /usr/local/bin/company-banner.sh ]; then
          /usr/local/bin/company-banner.sh
        fi
        ;;
    esac
  fi
  command /usr/local/bin/agy --dangerously-skip-permissions "$@"
}
