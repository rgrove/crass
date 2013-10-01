Crass
=====

Crass is a Ruby CSS parser based on the [CSS Syntax Module Level 3][css] draft.

* [Home](https://github.com/rgrove/crass/)
* [API Docs](http://rubydoc.info/github/rgrove/crass/master)

[![Build Status](https://travis-ci.org/rgrove/crass.png?branch=master)](https://travis-ci.org/rgrove/crass?branch=master)
[![Gem Version](https://badge.fury.io/rb/crass.png)](http://badge.fury.io/rb/crass)

Features
--------

* Pure Ruby, with no runtime dependencies other than Ruby 1.9.x or higher.

* Tokenizes and parses CSS according to the rules defined in the
  [CSS Syntax Module Level 3][css] draft.

* Extremely tolerant of broken or invalid CSS. If a browser can handle it, Crass
  should be able to handle it too.

* Optionally includes comments in the token stream.

* Optionally preserves certain CSS hacks, such as the IE "*" hack, which would
  otherwise be discarded according to CSS3 tokenizing rules.

* Capable of serializing the parse tree back to CSS while maintaining all
  original whitespace, comments, and indentation.

[css]: http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/

Problems
--------

* It's pretty slow.

* Crass only parses the CSS syntax; it doesn't understand what any of it means,
  doesn't coalesce selectors, etc. You can do this yourself by consuming the
  parse tree, though.

* While any node in the parse tree (or the parse tree as a whole) can be
  serialized back to CSS with perfect fidelity, changes made to those nodes
  (except for wholesale removal of nodes) are not reflected in the serialized
  output.

* Unit tests aren't complete yet.

* Probably tons of other things. Did I mention it's very new and experimental?

Installing
----------

```
gem install crass
```

...but only if you're brave. Seriously, this thing will almost certainly kill
your family and poop on your pets.

Examples
--------

Say you have a string containing the following simple CSS:

```css
/* Comment! */
a:hover {
  color: #0d8bfa;
  text-decoration: underline;
}
```

Parsing it is simple:

```ruby
tree = Crass.parse(css, :preserve_comments => true)
```

This returns a big fat ugly parse tree, which looks like this:

```ruby
[{:node=>:comment, :pos=>0, :raw=>"/* Comment! */", :value=>" Comment! "},
 {:node=>:whitespace, :pos=>14, :raw=>"\n"},
 {:node=>:style_rule,
  :selector=>
   {:node=>:selector,
    :value=>"a:hover",
    :tokens=>
     [{:node=>:ident, :pos=>15, :raw=>"a", :value=>"a"},
      {:node=>:colon, :pos=>16, :raw=>":"},
      {:node=>:ident, :pos=>17, :raw=>"hover", :value=>"hover"},
      {:node=>:whitespace, :pos=>22, :raw=>" "}]},
  :children=>
   [{:node=>:whitespace, :pos=>24, :raw=>"\n  "},
    {:node=>:property,
     :name=>"color",
     :value=>"#0d8bfa",
     :tokens=>
      [{:node=>:ident, :pos=>27, :raw=>"color", :value=>"color"},
       {:node=>:colon, :pos=>32, :raw=>":"},
       {:node=>:whitespace, :pos=>33, :raw=>" "},
       {:node=>:hash,
        :pos=>34,
        :raw=>"#0d8bfa",
        :type=>:unrestricted,
        :value=>"0d8bfa"},
       {:node=>:semicolon, :pos=>41, :raw=>";"}]},
    {:node=>:whitespace, :pos=>42, :raw=>"\n  "},
    {:node=>:property,
     :name=>"text-decoration",
     :value=>"underline",
     :tokens=>
      [{:node=>:ident,
        :pos=>45,
        :raw=>"text-decoration",
        :value=>"text-decoration"},
       {:node=>:colon, :pos=>60, :raw=>":"},
       {:node=>:whitespace, :pos=>61, :raw=>" "},
       {:node=>:ident, :pos=>62, :raw=>"underline", :value=>"underline"},
       {:node=>:semicolon, :pos=>71, :raw=>";"}]},
    {:node=>:whitespace, :pos=>72, :raw=>"\n"}]},
 {:node=>:whitespace, :pos=>74, :raw=>"\n"}]
```

If you want, you can stringify the parse tree:

```ruby
css = Crass::Parser.stringify(tree)
```

...which gives you back exactly what you put in!

```css
/* Comment! */
a:hover {
  color: #0d8bfa;
  text-decoration: underline;
}
```

Wasn't that exciting?

A Note on Versioning
--------------------

Crass's version number currently has a "0.x" prefix, indicating that it's a new
project under heavy development. **As long as the version number starts with
"0.x", minor revisions may introduce breaking changes.** You've been warned!

Once Crass reaches version 1.0.0, it will adhere strictly to
[SemVer 2.0][semver].

[semver]:http://semver.org/spec/v2.0.0.html

Contributing
------------

The best way to contribute right now is to use Crass and [create issues][issue]
when you run into problems.

Pull requests that fix bugs are more than welcome as long as they include tests.
Please adhere to the style and format of the surrounding code, or I might ask
you to change things.

If you want to add a feature or refactor something, please get in touch first to
make sure I'm on board with your idea and approach; I'm pretty picky, and I'd
hate to have to turn down a pull request you spent a lot of time on.

[issue]: https://github.com/rgrove/crass/issues/new

License
-------

Copyright (c) 2013 Ryan Grove (ryan@wonko.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the ‘Software’), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
