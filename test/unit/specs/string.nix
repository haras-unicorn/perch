{ self, ... }:

{
  string_capitalize_noop_empty = (self.lib.string.capitalize "") == "";
  string_capitalize_first_len_1 = (self.lib.string.capitalize "a") == "A";
  string_capitalize_noop_upper_len_1 = (self.lib.string.capitalize "A") == "A";
  string_capitalize_first = (self.lib.string.capitalize "aaa") == "Aaa";
  string_capitalize_first_noop_upper = (self.lib.string.capitalize "Aaa") == "Aaa";
  string_capitalize_first_noop_upper_all = (self.lib.string.capitalize "AAA") == "AAA";

  string_wordSplit_empty = (self.lib.string.wordSplit "") == [ ];
  string_wordSplit_single = (self.lib.string.wordSplit "hello") == [ "hello" ];

  string_wordSplit_dashes =
    (self.lib.string.wordSplit "some-file-name") == [
      "some"
      "file"
      "name"
    ];
  string_wordSplit_underscores =
    (self.lib.string.wordSplit "some_file_name") == [
      "some"
      "file"
      "name"
    ];
  string_wordSplit_mixed_separators =
    (self.lib.string.wordSplit "some-file_name") == [
      "some"
      "file"
      "name"
    ];
  string_wordSplit_dedup_separators =
    (self.lib.string.wordSplit "some--file___name") == [
      "some"
      "file"
      "name"
    ];

  string_wordSplit_camelCase =
    (self.lib.string.wordSplit "someFileName") == [
      "some"
      "File"
      "Name"
    ];
  string_wordSplit_pascalCase =
    (self.lib.string.wordSplit "SomeFileName") == [
      "Some"
      "File"
      "Name"
    ];
  string_wordSplit_acronym_boundary =
    (self.lib.string.wordSplit "HTTPServer") == [
      "HTTP"
      "Server"
    ];
  string_wordSplit_acronym_chain =
    (self.lib.string.wordSplit "MyHTTPServer") == [
      "My"
      "HTTP"
      "Server"
    ];

  string_wordSplit_digits_boundary =
    (self.lib.string.wordSplit "sha256Sum") == [
      "sha"
      "256"
      "Sum"
    ];
  string_wordSplit_digits_inside_acronym =
    (self.lib.string.wordSplit "SHA256Sum") == [
      "SHA256"
      "Sum"
    ];

  string_wordSplit_spaces =
    (self.lib.string.wordSplit "some   file  name") == [
      "some"
      "file"
      "name"
    ];

  string_toTitle_noop_empty = (self.lib.string.toTitle "") == "";
  string_toTitle_single = (self.lib.string.toTitle "hello") == "Hello";
  string_toTitle_dashes = (self.lib.string.toTitle "some-file-name") == "Some File Name";
  string_toTitle_underscores = (self.lib.string.toTitle "some_file_name") == "Some File Name";
  string_toTitle_mixed = (self.lib.string.toTitle "some-file_name") == "Some File Name";
  string_toTitle_dedup_separators = (self.lib.string.toTitle "some--file___name") == "Some File Name";

  string_toTitle_camelCase = (self.lib.string.toTitle "someFileName") == "Some File Name";
  string_toTitle_pascalCase = (self.lib.string.toTitle "SomeFileName") == "Some File Name";
  string_toTitle_acronym_boundary = (self.lib.string.toTitle "HTTPServer") == "HTTP Server";
  string_toTitle_acronym_chain = (self.lib.string.toTitle "myHTTPServer") == "My HTTP Server";
  string_toTitle_digits_boundary = (self.lib.string.toTitle "sha256Sum") == "Sha 256 Sum";

  string_indent_noop_0 = (self.lib.string.indent 0 "a\nb") == "a\nb";
  string_indent_add_2_single = (self.lib.string.indent 2 "a") == "  a";
  string_indent_add_2_multi = (self.lib.string.indent 2 "a\nb") == "  a\n  b";
  string_indent_preserve_empty_lines = (self.lib.string.indent 2 "a\n\nb") == "  a\n\n  b";

  string_indent_dedent_2_single_exact = (self.lib.string.indent (-2) "  a") == "a";
  string_indent_dedent_2_single_less = (self.lib.string.indent (-2) " a") == "a";
  string_indent_dedent_2_single_none = (self.lib.string.indent (-2) "a") == "a";
  string_indent_dedent_2_multi_mixed = (self.lib.string.indent (-2) "  a\n b\na") == "a\nb\na";
  string_indent_dedent_preserve_empty_lines = (self.lib.string.indent (-2) "  a\n\n  b") == "a\n\nb";
}
