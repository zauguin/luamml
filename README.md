# Automated LuaLaTeX math to MathML conversion
**Highly experimental! At this point all interfaces may change without prior warning and many features aren't implemented yet. It is not ready for anything beyond simple experiments.**

This is an attempt to implement automatic conversion of LuaLaTeX inline and display math expressions into MathML code to aid with tagging.
It works best with `unicode-math`, but it can also be used with traditional math fonts if mappings to Unicode are provided.

## Installation
Run `l3build install` to install `luamml` into your local `texmf` tree.

## Demo
Run `lualatex test_tex` to see all equations from [our example file](./test_tex.tex) converted into MathML. 

To test it on your own files, add `\usepackage{luamml}` and `\tracingmathml=2` to your preamble.
Also see a [`tagpdf` experiment using this to tag PDF formulas](https://github.com/u-fischer/tagpdf/blob/develop/experiments/exp-mathml-lua.tex).
