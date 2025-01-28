# Development

## Generating the help doc
```sh
# Clone panvimdoc
git clone https://github.com/kdheepak/panvimdoc

# Generate it from README.md
cd panvimdoc
./panvimdoc.sh --project-name auto-input-switch.nvim --input-file ../README.md --toc true --shift-heading-level-by -1

# Overwrite the old one
cp -f doc/auto-input-switch.nvim.txt ../doc/
```

