# Add User ~/bin to PATH
PATH=$HOME/bin:$PATH
export PATH

# Load optional local dotfiles (not tracked in repo)
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
  [ -r "$file" ] && source "$file"
done
unset file
