# Crass Changelog

## 1.0.7 (2026-06-25)

### Security

- High: Fixed a denial of service vulnerability in which a large numeric exponent could consume disproportionate CPU and memory before the value was clamped. Exponents are now bounded before `10**exponent` is computed. (GHSA-6wmf-3r64-vcwv)

- Moderate: Fixed a scenario in which deeply nested simple blocks or functions could exhaust the Ruby stack and raise `SystemStackError`, or could result in excessive memory usage. Parser nesting is now limited to a configurable maximum depth via a new option (`:maximum_depth`, with a conservative default of 25). Constructs nested more deeply are discarded as an `:error` node with the value "maximum-depth-exceeded". (GHSA-6jxj-px6v-747w)

- Moderate: Fixed a scenario in which a long run of adjacent comments could exhaust the Ruby stack and raise `SystemStackError`. Discarded comments are now skipped iteratively rather than recursively. (GHSA-wwpr-jff3-395c)

- Moderate: Fixed a denial of service vulnerability in which inputs containing many non-ASCII characters could cause excessive CPU usage due to inefficient handling of multi-byte characters during tokenization. (GHSA-8vfg-2r28-hvhj)

## 1.0.6 (2020-01-12)

- Number values are now limited to a maximum of `Float::MAX` and a minimum of negative `Float::MAX`. (#11)

- Added project metadata to the gemspec. (#9 - @orien)

## 1.0.5 (2019-10-15)

- Removed test files from the gem. (#8 - @t-richards)

## 1.0.4 (2018-04-08)

- Fixed whitespace warnings. (#7 - @yahonda)

## 1.0.3 (2017-11-13)

- Added support for frozen string literals. (#3 - @flavorjones)

## 1.0.2 (2015-04-17)

- Fixed: An at-rule immediately followed by a `{}` simple block would have the block (and subsequent tokens until a semicolon) incorrectly appended to its prelude. This was super dumb and made me very sad.

## 1.0.1 (2014-11-16)

- Fixed: Modifications made to the block of an `:at_rule` node in a parse tree weren't reflected when that node was stringified. This was a regression introduced in 1.0.0.

## 1.0.0 (2014-11-16)

- Many parsing and tokenization tweaks to bring us into full compliance with the [14 November 2014 editor's draft](http://dev.w3.org/csswg/css-syntax-3/) of the CSS syntax spec. The most significant outwardly visible change is that quoted URLs like `url("foo")` are now returned as `:function` tokens and not `:url` tokens due to a change in the tokenization spec.

- Teensy tiny speed and memory usage improvements that you almost certainly won't notice.

- Fixed: A semicolon following a `@charset` rule would be omitted during serialization.

- Fixed: A multibyte char at the beginning of an id token could trigger an encoding error because `StringScanner#peek` is a jerkface.

## 0.2.1 (2014-07-22)

- Fixed: Error when the last property of a rule has no value and no terminating semicolon. [#2](https://github.com/rgrove/crass/issues/2)

## 0.2.0 (2013-10-10)

- Added a `:children` field to `:property` nodes. It's an array containing all the nodes that make up the property's value.

- Fixed: Incorrect value was given for `:property` nodes whose values contained functions.

- Fixed: When parsing the value of an at-rule's block as a list of rules, a selector containing a function (such as `#foo:not(.bar)`) would cause that property and the rest of the token stream to be discarded.

## 0.1.0 (2013-10-04)

- Tokenization is a little over 50% faster.

- Added tons of unit tests.

- Added `Crass.parse_properties` and `Crass::Parser.parse_properties`, which can be used to parse the contents of an HTML element's `style` attribute.

- Added `Crass::Parser.parse_rules`, which can be used to parse the contents of an `:at_rule` block like `@media` that may contain style rules.

- Fixed: `Crass::Parser#consume_at_rule` and `#consume_qualified_rule` didn't properly handle already-parsed `:simple_block` nodes in the input, which occurs when parsing rules in the value of an `:at_rule` block.

- Fixed: On `:property` nodes, `:important` is now set to `true` when the property is followed by an "!important" declaration.

- Fixed: "!important" is no longer included in the value of a `:property` node.

- Fixed: A variety of tokenization bugs uncovered by tests.

- Fixed: Added a workaround for a possible spec bug when an `:at_keyword` is encountered while consuming declarations.

## 0.0.2 (2013-09-30)

- Fixed: `:at_rule` nodes now have a `:name` key.

## 0.0.1 (2013-09-27)

- Initial release.
