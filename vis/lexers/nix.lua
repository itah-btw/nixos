-- Nix LPeg lexer. Written for this config: vis 0.9 ships no nix lexer, so .nix
-- files opened with the stock ftdetect table get no highlighting at all.
--
-- ${...} is matched as one EMBEDDED span rather than by embedding this lexer
-- into itself: `lex:embed(lex, …)` puts the lexer in its own _CHILDREN list and
-- add_lexer recurses into it without a cycle guard (lexer.lua:1128), which
-- overflows the stack while building the grammar. Interpolations are therefore
-- highlighted as inline blocks, not as fully-lexed Nix.
local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

lex:add_rule("whitespace", lex:tag(lexer.WHITESPACE, lexer.space ^ 1))

lex:add_rule("keyword", lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
lex:add_rule("builtin", lex:tag(lexer.FUNCTION_BUILTIN, lex:word_match(lexer.FUNCTION_BUILTIN)))

-- ${ … } up to the matching brace. A `}` inside a nested string literal ends the
-- span early; that is cosmetic only, and counting quotes properly needs a
-- second parser.
local function interp_end(input, index)
  local depth, i = 1, index
  while i <= #input do
    local c = input:sub(i, i)
    if c == "{" then
      depth = depth + 1
    elseif c == "}" then
      depth = depth - 1
      if depth == 0 then
        return i + 1
      end
    end
    i = i + 1
  end
  return #input + 1
end

-- Both string forms stop before `${` so the interpolation rule gets a turn.
-- `''${` is the indented-string escape for a literal `${` and `''` inside a run
-- is an escaped quote rather than a terminator, hence the negative lookaheads
-- rather than lexer.range.
-- Char classes must use S, not P: lpeg.P on a multi-character string builds a
-- *sequence*, so `any - P('"\\$')` subtracts nothing and the string rule then
-- swallows `${…}`. Only the ESCAPED backslash uses P.
local dq_body = (lexer.any - S('"\\$'))
  + P("\\") * lexer.any
  + (P("${") * lpeg.Cmt(P(true), function(input, index)
    return interp_end(input, index)
  end))
  + P("$") * -P("{")
local dq_str = P('"') * dq_body ^ 0 * P('"') ^ -1
local iq_body = (lexer.any - S("'\\$"))
  + P("\\") * lexer.any
  + "''${"
  + (P("${") * lpeg.Cmt(P(true), function(input, index)
    return interp_end(input, index)
  end))
  + P("$") * -P("{")
local indented_str = P("''") * iq_body ^ 0 * P("''") ^ -1

lex:add_rule("string", lex:tag(lexer.STRING, dq_str + indented_str))

-- Nix paths: <nixpkgs>, ./rel, ../rel, /abs, ~/home, and bare a/b. Match only
-- the forms Nix actually tokenizes as paths; `.foo` like before would get eaten
-- as a relative path when it's really a selection.
lex:add_rule(
  "path",
  lex:tag(
    lexer.STRING,
    ("<" * (lexer.any - ">" - "\n") ^ 0 * ">")
      + (P("./") * (lexer.alnum + S("./_~-")) ^ 1)
      + (P("../") * (lexer.alnum + S("./_~-")) ^ 1)
      + (P("~/") * (lexer.alnum + S("./_~-")) ^ 1)
      + (P("/") * -P("/") * (lexer.alnum + S("./_~-")) ^ 1)
      + (lexer.alpha * -P(".") * (lexer.alnum + S("._-")) ^ 0 * P("/") * (lexer.alnum + S("./_~-")) ^ 1)
  )
)

lex:add_rule("comment", lex:tag(lexer.COMMENT, lexer.to_eol("#") + lexer.range("/*", "*/", false, false, true)))

lex:add_rule("number", lex:tag(lexer.NUMBER, lexer.float + lexer.hex_num + lexer.dec_num))

lex:add_rule("identifier", lex:tag(lexer.IDENTIFIER, lexer.word))

-- `...` is the ellipsis argument, not three dots.
lex:add_rule(
  "operator",
  lex:tag(
    lexer.OPERATOR,
    ("..." * -P("."))
      + P("++")
      + P("//")
      + P("==")
      + P("!=")
      + P("<=")
      + P(">=")
      + P("&&")
      + P("||")
      + P("->")
      + P("::")
      + S("=+-*/<>!&|?:.@;,{}()[]")
  )
)

lex:add_fold_point(lexer.OPERATOR, "{", "}")
lex:add_fold_point(lexer.OPERATOR, "[", "]")
lex:add_fold_point(lexer.COMMENT, "/*", "*/")
lex:add_fold_point(lexer.STRING, '"', '"')
lex:add_fold_point(lexer.STRING, "''", "''")

lex:set_word_list(lexer.KEYWORD, {
  "assert",
  "else",
  "if",
  "in",
  "inherit",
  "let",
  "or",
  "rec",
  "then",
  "with",
})

lex:set_word_list(lexer.FUNCTION_BUILTIN, {
  "abort",
  "addErrorContext",
  "all",
  "any",
  "attrNames",
  "attrValues",
  "baseNameOf",
  "builtins",
  "compareVersions",
  "concatLists",
  "concatMap",
  "concatStringsSep",
  "currentSystem",
  "deepSeq",
  "derivation",
  "derivationStrict",
  "dirOf",
  "elem",
  "elemAt",
  "fetchClosure",
  "fetchGit",
  "fetchTarball",
  "fetchTree",
  "filter",
  "filterSource",
  "findFile",
  "floor",
  "fromJSON",
  "fromTOML",
  "functionArgs",
  "genList",
  "getEnv",
  "getFlake",
  "groupBy",
  "hasAttr",
  "hashFile",
  "head",
  "import",
  "intersectAttrs",
  "isAttrs",
  "isBool",
  "isFloat",
  "isFunction",
  "isInt",
  "isList",
  "isNull",
  "isPath",
  "isString",
  "length",
  "lessThan",
  "listToAttrs",
  "map",
  "mapAttrs",
  "mapAttrsToList",
  "match",
  "null",
  "parseDrvName",
  "partition",
  "path",
  "pathExists",
  "placeholder",
  "readDir",
  "readFile",
  "removeAttrs",
  "replaceStrings",
  "seq",
  "sort",
  "split",
  "splitVersion",
  "storePath",
  "sub",
  "substring",
  "tail",
  "toFile",
  "toJSON",
  "toPath",
  "toString",
  "toXML",
  "trace",
  "true",
  "false",
  "tryEval",
  "typeOf",
})

lexer.property["scintillua.comment"] = "#"

return lex
