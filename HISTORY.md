Crass Change History
====================

git
---

* Added `Crass::Parser#parse_rules` and a convenient class method of the same
  name, which can be used to parse the contents of an `:at_rule` block that may
  contain style rules, such as `@media`.

* Fixed: `Crass::Parser#consume_at_rule` and `#consume_qualified_rule` didn't
  properly handle already-parsed `:simple_block` nodes in the input, which
  occurs when parsing rules in the value of an `:at_rule` block.

* Fixed: "!important" is no longer included in the `:value` of a `:property`
  node.


0.0.2 (2013-09-30)
------------------

* Fixed: `:at_rule` nodes now have a `:name` key.


0.0.1 (2013-09-27)
------------------

* Initial release.

