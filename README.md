Summary
-------

Babel Bridge let's you generate parsers 100% in Ruby code. It is a memoizing Parsing Expression Grammar (PEG) generator like Treetop, but it doesn't require special file-types or new syntax. Overall focus is on simplicity and usability over performance.

Example
-------

``` ruby
require "babel_bridge"

class MyParser < BabelBridge::Parser

  # foo rule: match "foo" optionally followed by the :bar rule
  rule :foo, "foo", :bar?

  # bar rule: match "bar"
  rule :bar, "bar"
end

# create one more instances of your parser
parser = parser

parser.parse "foo" # matches "foo"
#  => FooNode1 > "foo"

parser.parse "foobar" # matches "foobar"
# => FooNode1
#  "foo"
#  BarNode1 > "bar"

parser.parse "fribar" # fails to match
# => nil

parser.parse "foobarbar" # fails to match entire input
# => nil
```

Babel Bridge is a parser-generator for Parsing Expression Grammars

Goals
-----

* Allow expression 100% in ruby
* Productivity through Simplicity and Understandability first
* Performance second

Features
--------

``` ruby

# returns the BabelBridge::Rule instance for that rule
rule = MyParser[:foo]
# => rule :foo, "foo", :bar?

# nice human-readable view of the rule with extra info:
rule.to_s
# rule :foo, node_class: MyParser::FooNode
#         variant_class: MyParser::FooNode1, pattern: "foo", :bar?

# returns the code necessary for generating the rule and all its variants
# (minus any class_eval code)
rule.inspect
# => rule :foo, "foo", :bar?

# returns the Node class for a rule
MyParser.node_class(:foo)
# => MyParser::FooNode

MyParser.node_class(:foo) do
  # class_eval inside the rule's Node-class
end

# parses Text starting with the MyParser.root_rule
# The root_rule is defined automatically by the first rule defined, but can be set by:
#   MyParser.root_rule=v
# where v is the symbol name of the rule or the actual rule object from MyParser[rule]
text = "foobar"
parser.parse(text)

# do a one-time parse with :bar set as the root-rule
text = "bar"
parser.parse(text, :rule => :bar)

# relax requirement to match entire input
parser.parse "foobar and then something", :partial_match => true

# parse failure
parser.parse "foo is not immediately followed by bar"

# human readable parser failure info
puts parser.parser_failure_info
```

Parser failure info output:
```
Parsing error at line 1 column 4 offset 3

Source:
...
foo<HERE> is not immediately followed by bar
...

Parser did not match entire input.

Parse path at failure:
  FooNode1

Expecting:
  "bar" BarNode1
```
NOTE: This is an evolving feature, this output is as-of 0.5.1 and may not match the current version.

Defining Rules
--------------

Inside the parser class, a rule is defined as follows:

``` ruby
class MyParser < BabelBridge::Parser
  rule :rule_name, pattern
end
```

Where:

* :rule_name    is a symbol
* pattern       see Patterns below

You can also add new rules outside the class definition by:

``` ruby
MyParser.rule :rule_name, pattern
```

Patterns
--------

Patterns are a list of pattern elements, matched in order:

Example:

``` ruby
rule :my_rule, "match", "this", "in", "order"  # matches "matchthisinorder"
```

Pattern Elements
----------------

Pattern elements are basic-pattern-element or extended-pattern-element ( expressed as a hash). Internally, they are "compiled" into instances of PatternElement with optimized lambda functions for parsing.

## Basic Pattern Elements (basic_element)

``` ruby
:my_rule      # matches the Rule named :my_rule
:my_rule?     # optional: optionally matches Rule :my_rule
:my_rule!     # negative: success only if it DOESN'T match Rule :my_rule
"string"      # matches the string exactly
/regex/       # matches the regex exactly
```

## Advanced Pattern Elements

``` ruby

# success if basic_element could be matched, but the input is not consumed
could.match(basic_element)

# negative (two equivelent methods)
dont.match(basic_element)
match!(basic_element)

# optional (two equivelent methods)
optionally.match(basic_element)
match?(basic_element)

# match 1 or more
many(basic_element)

# match 1 or more of one basic_element delimited by another basic_element)
many(basic_element, delimiter_basic_element)

# match 0 or more
many?(basic_element)

```

## Custom Pattern Element Parser

Custom pattern elements are not generally needed, but for certain patterns, particularly context sensative ones, we provide a way to do it.

``` ruby
class MyParser < BabelBridge::Parser

  # custom parser to match an all upper-case word followed by any number of characters before that word is repeated
  rule :foo, (custom_parser do |parent_node|
    offset = parent_node.next
    src = parent_node.src

    # Note, the \A anchors the search at the beginning of the string
    if src[offset..-1].index(/\A[A-Z]+/) == 0
      endpattern=$~.to_s
      if i = src.index(endpattern, offset + endpattern.length)
        range = offset..(i + endpattern.length)
        BabelBridge::TerminalNode.new(parent_node, range, "endpattern")
      end
    end
  end)
end

parser = parser
parser.parse "END this is in the middle END"
# => FooNode1 > "END this is in the middle END"

parser.parse "DRUID this is in the middle DRUID"
# => FooNode1 > "DRUID this is in the middle DRUID"

parser.parse "DRUID this is in the middle DRUI"
# => nil
```

Structure
---------

* Each Rule defines a subclass of Node
* Each RuleVariant defines a subclass of the parent Rule's node-class

Therefor you can easily define code to be shared across all variants as well as define code specific to one variant.
