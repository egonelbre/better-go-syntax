require_relative '../directory'
require_relative PathFor[:textmate_tools]
require_relative './tokens.rb'

# 
# Setup grammar
# 
    Dir.chdir __dir__
    original_grammar = JSON.parse(IO.read("original.tmLanguage.json"))
    Grammar.convertSpecificIncludes(json_grammar: original_grammar, convert:["$self", "$base"], into: :$initial_context)
    grammar = Grammar.new(
        name: original_grammar["name"],
        scope_name: original_grammar["scopeName"],
        version: "",
        information_for_contributors: [
            "This code was auto generated by a much-more-readble ruby file",
            "see https://github.com/jeff-hykin/better-go-synta/blob/master",
        ],
    )
    # 
    # copy over all the repos
    # 
    for each_key, each_value in original_grammar["repository"]
        grammar[each_key.to_sym] = each_value
    end
#
#
# Contexts
#
#
    # this is equivlent to setting the {"patterns":[]} in the json file
    grammar[:$initial_context] = [
            # put new/updated patterns here
            :comments, # see below for the implementation of comments
            # spreads all the original patterns and puts them in this array
            *original_grammar["patterns"],
        ]
#
#
# Patterns
#
#
    # 
    # Comments
    # 
        # OLD WAY (original.tmLanguage.json)
        # "comments": {
        #         "patterns": [
        #             {
        #                 "begin": "/\\*",
        #                 "end": "\\*/",
        #                 "captures": {
        #                     "0": {
        #                         "name": "punctuation.definition.comment.go"
        #                     }
        #                 },
        #                 "name": "comment.block.go"
        #             },
        #             {
        #                 "begin": "//",
        #                 "beginCaptures": {
        #                     "0": {
        #                         "name": "punctuation.definition.comment.go"
        #                     }
        #                 },
        #                 "end": "$",
        #                 "name": "comment.line.double-slash.go"
        #             }
        #         ]
        #     },
        # NEW WAY:
        # this is the same as { "repository" : { "comments": } } inside the original json
        grammar[:comments, overwrite: true] = [
            # comments like this /* imma comment */
            PatternRange.new(
                tag_as: "comment.block",
                start_pattern: Pattern.new(
                    match: /\/\*/,
                    tag_as: 'punctuation.definition.comment'
                ),
                end_pattern: Pattern.new(
                    match: /\*\//,
                    tag_as: 'punctuation.definition.comment'
                ),
            ),
            # comments like this // imma comment
            PatternRange.new(
                tag_as: "comment.line.double-slash",
                start_pattern: Pattern.new(
                    match: /\/\//,
                    tag_as: "punctuation.definition.comment",
                ),
                end_pattern: @end_of_line,
            )
        ]
    # 
    # number literals
    # 
        grammar[:numeric_literals] = [
            :float,
            :integer,
        ]
        grammar[:float] = Pattern.new(
            tag_as: "constant.numeric.floating-point",
            match: /(\.\d+([Ee][-+]\d+)?i?)\b|\b\d+\.\d*(([Ee][-+]\d+)?i?\b)?/,
        )
        grammar[:integer] = Pattern.new(
            tag_as: "constant.numeric.integer.go",
            match: /\b((0x[0-9a-fA-F]+)|(0[0-7]+i?)|(\d+([Ee]\d+)?i?)|(\d+[Ee][-+]\d+i?))\b/,
        )
 
# Save (exports to json)
grammar_as_hash = grammar.to_h(inherit_or_embedded: :embedded)
IO.write(PathFor[:jsonSyntax ], JSON.pretty_generate(grammar_as_hash))
IO.write(PathFor[:languageTag], grammar.all_tags.to_a.sort.join("\n"))