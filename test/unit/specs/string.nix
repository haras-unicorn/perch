{ self, ... }:

{
  string_capitalize_noop_empty = (self.lib.string.capitalize "") == "";
  string_capitalize_first_len_1 = (self.lib.string.capitalize "a") == "A";
  string_capitalize_noop_upper_len_1 = (self.lib.string.capitalize "A") == "A";
  string_capitalize_first = (self.lib.string.capitalize "aaa") == "Aaa";
  string_capitalize_first_noop_upper = (self.lib.string.capitalize "Aaa") == "Aaa";
  string_capitalize_first_noop_upper_all = (self.lib.string.capitalize "AAA") == "AAA";
}
