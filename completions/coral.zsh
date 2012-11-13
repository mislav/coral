if [[ ! -o interactive ]]; then
  return
fi

compctl -K _coral coral

_coral() {
  local word words completions
  read -cA words
  word="${words[2]}"

  if [ "${#words}" -eq 2 ]; then
    completions="$(coral commands)"
  else
    completions="$(coral completions "${word}")"
  fi

  reply=("${(ps:\n:)completions}")
}
