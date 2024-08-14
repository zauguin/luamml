# LuaMML: Automated LuaLaTeX math to MathML conversion
This is an attempt to implement automatic conversion of LuaLaTeX inline and display math expressions into MathML code to aid with tagging.
It works best with `unicode-math`, but it can also be used with traditional math fonts if mappings to Unicode are provided.

## Installation
Run `l3build install` to install `luamml` into your local `texmf` tree.

## Usage
Add `\usepackage[tracing]{luamml-demo}` to print MathML to the terminal or `\usepackage[files]{luamml-demo}` to generate separate files with MathML output.
Alternatively it can be used with latex-lab to automatically integrate with tagging infrastucture.

<!-- Also see a [`tagpdf` experiment using this to tag PDF formulas](https://github.com/u-fischer/tagpdf/blob/develop/experiments/exp-mathml-lua.tex). -->

<!-- If you are very brave you can also try running `pdflatex test_pdf` and afterwards run `./pdfmml.lua test_pdf.lua` to get pdflatex formulas converted. -->
