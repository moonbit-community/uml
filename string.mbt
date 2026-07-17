///|
fn String::optional_text(self : String) -> String? {
  let trimmed = self.trim()
  guard trimmed.length() > 0 else { None }
  Some(trimmed.to_owned())
}

///|
fn String::optional_integer(self : String) -> Int? {
  guard self.length() > 0 else { None }
  Some(@string.parse_int(self) catch { _ => 0 })
}
