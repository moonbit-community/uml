///|
/// PlantUML acceptance corpus: every case reproduces the verdict of the
/// installed plantuml (accept or reject).
test "acceptance corpus matches the installed plantuml" {
  let cases = [
    ("01_basic", "OK", "binary B\n@0\nB is low\n@10\nB is high\n"),
    ("02_robust", "OK", "robust R\n@0\nR is idle\n@5\nR is busy\n"),
    ("03_concise", "OK", "concise C\nC has \"Waiting\" as wait\nC is wait\n"),
    ("04_rectangle", "OK", "rectangle Rc\nRc is 1\n"),
    (
      "05_analog", "OK", "analog \"Voltage\" from -1.5 to 1.5 as V\nV is 0.5\n@2\nV is -0.25\n",
    ),
    ("06_clock", "OK", "clock CLK with period 10\n"),
    (
      "07_clock_full", "OK", "clock \"My Clock\" as CLK with period 5 pulse 2 offset 1\n",
    ),
    ("08_compact", "OK", "compact robust A\nA is 1\n"),
    ("09_mode_compact", "OK", "mode compact\nrobust A\n"),
    (
      "100_negative_analog", "OK", "analog \"V\" from -2 to -1 as A\nA is -1.5\n",
    ),
    (
      "10_define_states", "OK", "robust R\nR has \"State A\" as sa\nR has sb\nR has sc\n",
    ),
    ("11_stereo", "OK", "robust R <<worker>>\n"),
    ("12_stereo2", "OK", "robust \"Full Name\" <<worker>> as R\n"),
    ("13_color", "OK", "robust R #pink\n"),
    ("14_message", "OK", "robust A\nbinary B\nA --> B\n"),
    ("15_message_label", "OK", "robust A\nbinary B\nA --> B : hello\n"),
    ("16_message_time", "OK", "robust A\nbinary B\nA@2-->B@5\n"),
    ("17_message_style", "ERR", "robust A\nbinary B\nA -[bold]-> B : styled\n"),
    ("18_note", "OK", "robust A\nnote top of A : single line\n"),
    ("19_note_bottom", "OK", "robust A\nnote bottom of A : bottom note\n"),
    (
      "20_note_long", "OK", "robust A\nnote top of A\nfirst line\nsecond line\nend note\n",
    ),
    ("21_constraint", "OK", "robust A\nA@1<--->@5 : constraint\n"),
    ("22_constraint_nop", "OK", "robust A\n@1<--->@5\n"),
    ("23_highlight", "OK", "robust A\nhighlight 1 to 5 : warmup\n"),
    ("24_highlight_color", "OK", "robust A\nhighlight 1 to 5 #lightblue\n"),
    ("25_scale", "OK", "robust A\nscale 1 as 100 pixels\n"),
    ("26_scale_unit", "OK", "robust A\nscale 5 s as 100 pixels\n"),
    ("27_hide", "OK", "robust A\nhide time axis\n"),
    ("28_manual", "OK", "robust A\nmanual time axis\n"),
    ("29_date", "OK", "robust A\n@2020/5/12\nA is x\n"),
    ("30_hour", "OK", "robust A\n@12:30:00\nA is x\n"),
    ("31_code", "OK", "robust A\n@5 as :t\nA is x\n@:t\nA is y\n"),
    ("32_code_delta", "OK", "robust A\n@5 as :t\nA is x\n@:t+2\nA is y\n"),
    ("33_relative", "OK", "robust A\n@5\nA is x\n@+3\nA is y\n"),
    (
      "34_clock_tick", "ERR", "robust A\nclock CLK with period 10\nA@CLK*3 is x\n",
    ),
    ("35_initial_state", "OK", "binary B\nB is high\n"),
    ("36_binary_low", "OK", "binary B\nB is low\n@2\nB is high\n"),
    ("37_binary_high", "OK", "binary B\nB is high\n@1\nB is low\n"),
    ("38_pixel_height", "OK", "robust A\nA is 40 pixels height\n"),
    ("39_ticks", "OK", "analog \"V\" as A\nA ticks every 2\n"),
    ("40_ticks_num", "OK", "analog \"V\" as A\nA ticks num on multiple 2\n"),
    (
      "41_date_format", "OK", "robust A\nuse date format \"MM/dd\"\n@2020/5/12\nA is x\n",
    ),
    ("42_states_pair", "OK", "robust A\nA is {x,y}\n"),
    ("43_states_hidden", "OK", "robust A\nA is {hidden}\n"),
    ("44_states_flat", "OK", "robust A\nA is {-}\n"),
    ("45_states_unknown", "OK", "robust A\nA is {...}\n"),
    ("46_states_question", "OK", "robust A\nA is {?}\n"),
    ("47_comment", "OK", "robust A\nA is 1 : with comment\n"),
    ("48_comment_color", "OK", "robust A\nA is 1 #red : colored comment\n"),
    ("49_at_player", "OK", "robust A\nbinary B\n@A\nA is x\n@B\nB is high\n"),
    ("50_at_time_alone", "OK", "robust A\n@7\nA is x\n"),
    ("51_quoted_state", "OK", "robust A\nA is \"my state\"\n"),
    (
      "52_two_players", "OK", "robust A\nbinary B\n@0\nA is idle\nB is low\n@5\nA is busy\nB is high\n",
    ),
    (
      "53_dual_state", "OK", "robust A\nA has \"Low\" as L\nA has \"High\" as H\n@0\nA is {L,H}\n@3\nA is {H,L}\n",
    ),
    ("54_escaped", "OK", "robust \"Player A\" as PA\nPA is 1\n"),
    ("55_stereo_after", "OK", "robust A <<worker>>\n"),
    ("56_clock_stereo", "OK", "clock CLK with period 10 <<timer>>\n"),
    ("57_binary_stereo", "OK", "binary B <<digital>>\n"),
    ("58_stop", "ERR", "robust A\nstop at 10\n"),
    ("59_scale_bad", "ERR", "robust A\nscale 0 as 100 pixels\n"),
    ("60_message_no_time", "OK", "robust A\nbinary B\nA --> B\n"),
    ("61_unknown_player_is", "ERR", "robust A\nX is 1\n"),
    ("62_is_at_time", "ERR", "robust A\n@5 is 1\n"),
    ("63_note_unclosed", "ERR", "robust A\nnote top of A\nopen\n"),
    ("64_unknown_message", "ERR", "robust A\nX --> B\n"),
    ("65_define_unknown", "ERR", "robust A\nX has s\n"),
    ("66_clock_state", "ERR", "clock CLK with period 5\nCLK is high\n"),
    ("67_define_binary", "ERR", "binary B\nB has \"Low\" as L\n"),
    ("68_analog_define", "ERR", "analog \"V\" as A\nA has s\n"),
    ("69_ticks_robust", "OK", "robust A\nA ticks every 2\n"),
    ("70_hide_footbox", "OK", "robust A\nhide footbox\n"),
    ("71_title", "OK", "title My Title\nrobust A\n"),
    ("72_legend", "OK", "legend\nsome legend\nend legend\nrobust A\n"),
    ("73_skinparam", "OK", "skinparam BackgroundColor #ffffaa\nrobust A\n"),
    ("74_empty", "OK", ""),
    ("75_analog_bounds_between", "OK", "analog \"V\" between 0 and 5 as A\n"),
    ("76_analog_bounds_to", "OK", "analog \"V\" from 0 to 5 as A\n"),
    ("77_no_space_time_message", "ERR", "robust A\nbinary B\nA @2 --> B @5\n"),
    ("78_message_at_same", "OK", "robust A\nbinary B\nA@2-->B\n"),
    ("79_highlight_rel", "OK", "robust A\n@5\nhighlight 1 to +2\n"),
    ("80_binary_pair", "OK", "binary B\nB is {1,0}\n"),
    ("81_state_dash", "OK", "robust A\nA is idle-state\n"),
    (
      "82_multiline_indent", "OK", "robust A\nnote top of A\n    indented\n    lines\nend note\n",
    ),
    ("83_stereo_quoted", "OK", "robust \"A B\" as A <<s>>\n"),
    ("84_color_after", "OK", "robust A <<s>> #pink\n"),
    ("85_comment_only_line", "OK", "' a comment\nrobust A\n"),
    ("86_pulse_only", "OK", "clock CLK with period 10 pulse 4\n"),
    ("87_offset_only", "OK", "clock CLK with period 10 offset 2\n"),
    ("88_scale_year", "OK", "robust A\nscale 1 y as 100 pixels\n"),
    ("89_scale_day", "OK", "robust A\nscale 1 d as 100 pixels\n"),
    ("90_scale_min", "OK", "robust A\nscale 2 m as 200 pixels\n"),
    ("91_analog_value_e", "OK", "analog \"V\" as A\nA is 1e1\n"),
    ("92_analog_value_bad", "OK", "analog \"V\" as A\nA is notanumber\n"),
    ("93_same_time_dedup", "OK", "robust A\n@3\nA is x\n@3\nA is y\n"),
    ("94_show_footbox", "OK", "robust A\nshow footbox\n"),
    ("95_analog_no_bounds", "OK", "analog \"V\" as A\n"),
    (
      "96_binary_high_low", "OK", "binary B\nB is high\n@1\nB is low\n@2\nB is high\n",
    ),
    ("97_binary_message", "OK", "binary B\nrobust R\nB@1-->R@2 : tick\n"),
    ("98_message_bad_player", "ERR", "robust A\nA --> Z\n"),
    ("99_negative", "OK", "robust A\n@-5\nA is x\n"),
  ]
  for index in 0..<cases.length() {
    let (name, expected, body) = cases[index]
    let outcome = try {
      ignore(parse_timing("@startuml\n" + body + "@enduml"))
      "OK"
    } catch {
      _ => "ERR"
    }
    if outcome != expected {
      println(
        "acceptance case " +
        name +
        ": expected " +
        expected +
        ", got " +
        outcome,
      )
      abort("acceptance mismatch")
    }
  }
}
