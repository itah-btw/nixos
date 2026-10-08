local lexers = vis.lexers

local colors = {
  base00 = "#0f0f0f",
  base01 = "#3b403c",
  base02 = "#454b46",
  base03 = "#5b615c",
  base04 = "#d9cdb5",
  base05 = "#f4decd",
  base08 = "#f16e65",
  base09 = "#71b4d6",
  base0A = "#7ec97e",
  base0B = "#ef934d",
  base0C = "#96cde9",
  base0D = "#f4b88a",
  base0E = "#96e996",
  base0F = "#bef4be",
}

lexers.colors = colors
local fg = ",fore:" .. colors.base05 .. ","
local bg = ",back:" .. colors.base00 .. ","

lexers.STYLE_DEFAULT = bg .. fg
lexers.STYLE_NOTHING = bg
lexers.STYLE_CLASS = "fore:" .. colors.base0A .. ",bold"
lexers.STYLE_COMMENT = "fore:" .. colors.base03 .. ",italics"
lexers.STYLE_CONSTANT = "fore:" .. colors.base0F
lexers.STYLE_DEFINITION = "fore:" .. colors.base04
lexers.STYLE_ERROR = "fore:" .. colors.base08 .. ",italics"
lexers.STYLE_FUNCTION = "fore:" .. colors.base0D
lexers.STYLE_KEYWORD = "fore:" .. colors.base0E
lexers.STYLE_LABEL = "fore:" .. colors.base0C
lexers.STYLE_NUMBER = "fore:" .. colors.base09
lexers.STYLE_OPERATOR = "fore:" .. colors.base0C
lexers.STYLE_REGEX = "fore:" .. colors.base08
lexers.STYLE_STRING = "fore:" .. colors.base0B
lexers.STYLE_PREPROCESSOR = "fore:" .. colors.base0F
lexers.STYLE_TAG = "fore:" .. colors.base04
lexers.STYLE_TYPE = "fore:" .. colors.base0C
lexers.STYLE_VARIABLE = fg
lexers.STYLE_WHITESPACE = "fore:" .. colors.base02
lexers.STYLE_EMBEDDED = "back:" .. colors.base01
lexers.STYLE_IDENTIFIER = fg
lexers.STYLE_ATTRIBUTE = "fore:" .. colors.base0C

lexers.STYLE_LINENUMBER = "fore:" .. colors.base03 .. ",back:" .. colors.base00
lexers.STYLE_LINENUMBER_CURSOR = "fore:" .. colors.base05 .. ",back:" .. colors.base00
lexers.STYLE_CURSOR = "fore:" .. colors.base00 .. ",back:" .. colors.base05
lexers.STYLE_CURSOR_PRIMARY = lexers.STYLE_CURSOR
lexers.STYLE_CURSOR_LINE = "back:" .. colors.base01
lexers.STYLE_COLOR_COLUMN = "back:" .. colors.base01
lexers.STYLE_SELECTION = "back:" .. colors.base02
lexers.STYLE_STATUS = "back:" .. colors.base00 .. ",fore:" .. colors.base05
lexers.STYLE_STATUS_FOCUSED = "back:" .. colors.base01 .. ",fore:" .. colors.base05
lexers.STYLE_SEPARATOR = lexers.STYLE_DEFAULT
lexers.STYLE_INFO = "fore:default,back:default,bold"
lexers.STYLE_EOF = "fore:" .. colors.base03

lexers.STYLE_HEADING = "fore:" .. colors.base0E .. ",bold"
lexers.STYLE_CITATION_BLOCK = lexers.STYLE_LABEL
lexers.STYLE_LINK_BLOCK = lexers.STYLE_LABEL
lexers.STYLE_CODE_BLOCK = lexers.STYLE_EMBEDDED
lexers.STYLE_DIRECTIVE = lexers.STYLE_KEYWORD
lexers.STYLE_SUBSTITUTION = lexers.STYLE_VARIABLE
lexers.STYLE_INLINE_LITERAL = lexers.STYLE_EMBEDDED
lexers.STYLE_ROLE = lexers.STYLE_CLASS
lexers.STYLE_INTERPRETED = lexers.STYLE_STRING
lexers.STYLE_LINE = "bold"
for i = 1, 5 do
  lexers["STYLE_H" .. i] = lexers.STYLE_HEADING
end
lexers.STYLE_IMAGE = lexers.STYLE_LABEL
lexers.STYLE_STRIKE = "italics"
lexers.STYLE_TAGGED = lexers.STYLE_EMBEDDED
lexers.STYLE_TAGGED_AREA = lexers.STYLE_EMBEDDED
lexers.STYLE_TABLE_SEP = lexers.STYLE_LABEL
lexers.STYLE_HEADER_CELL_CONTENT = lexers.STYLE_LABEL
