Crass Change History
====================

? (git)
-------

* Fixed: A multibyte char at the beginning of an id token could trigger an
  encoding error because StringScanner#peek is a jerkface.

0.2.1 (2014-07-22)
------------------

* Fixed: Error when the last property of a rule has no value and no terminating
  semicolon. [#2][]

[#2]:https://github.com/rgrove/crass/issues/2


0.2.0 (2013-10-10)
------------------

* Added a `:children` field to `:property` nodes. It's an array containing all
  the nodes that make up the property's value.

* Fixed: Incorrect value was given for `:property` nodes whose values contained
  functions.

* Fixed: When parsing the value of an at-rule's block as a list of rules, a
  selector containing a function (such as "#foo:not(.bar)") would cause that
  property and the rest of the token stream to be discarded.


0.1.0 (2013-10-04)
------------------

* Tokenization is a little over 50% faster.

* Added tons of unit tests.

* Added `Crass.parse_properties` and `Crass::Parser.parse_properties`, which can
  be used to parse the contents of an HTML element's `style` attribute.

* Added `Crass::Parser.parse_rules`, which can be used to parse the contents of
  an `:at_rule` block like `@media` that may contain style rules.

* Fixed: `Crass::Parser#consume_at_rule` and `#consume_qualified_rule` didn't
  properly handle already-parsed `:simple_block` nodes in the input, which
  occurs when parsing rules in the value of an `:at_rule` block.

* Fixed: On `:property` nodes, `:important` is now set to `true` when the
  property is followed by an "!important" declaration.

* Fixed: "!important" is no longer included in the value of a `:property` node.

* Fixed: A variety of tokenization bugs uncovered by tests.

* Fixed: Added a workaround for a possible spec bug when an `:at_keyword` is
  encountered while consuming declarations.


0.0.2 (2013-09-30)
------------------

* Fixed: `:at_rule` nodes now have a `:name` key.


0.0.1 (2013-09-27)
------------------

* Initial release.
