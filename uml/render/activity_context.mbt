///|
/// Activity nodes retain declaration-time style snapshots. Apply the selected
/// theme before reduction without replacing their font settings and properties.
fn @flow.ActivityDiagram::with_render_context(
  self : @flow.ActivityDiagram,
  color_scheme : @style.ColorScheme,
) -> @flow.ActivityDiagram {
  let bind = (style : @style.DocumentStyle) => {
    style.with_color_scheme(color_scheme)
  }
  let nodes : Array[@flow.ActivityNode] = self.nodes.map(node => {
    match node {
      @flow.Repeat(value) =>
        @flow.Repeat({ ..value, style: bind(value.style), })
      @flow.EndIf(value) => @flow.EndIf({ ..value, style: bind(value.style), })
      @flow.EndSwitch(value) =>
        @flow.EndSwitch({ ..value, style: bind(value.style), })
      @flow.If(value) => @flow.If({ ..value, style: bind(value.style), })
      @flow.ElseIf(value) =>
        @flow.ElseIf({ ..value, style: bind(value.style), })
      @flow.While(value) => @flow.While({ ..value, style: bind(value.style), })
      @flow.RepeatWhile(value) =>
        @flow.RepeatWhile({ ..value, style: bind(value.style), })
      @flow.Switch(value) =>
        @flow.Switch({ ..value, style: bind(value.style), })
      @flow.RepeatAction(action) =>
        @flow.RepeatAction({ ..action, style: bind(action.style), })
      @flow.Backward(backward) =>
        @flow.Backward({
          ..backward,
          action: { ..backward.action, style: bind(backward.action.style), },
        })
      @flow.StyledAction(action) =>
        @flow.StyledAction({ ..action, style: bind(action.style), })
      @flow.Partition(group) =>
        @flow.Partition({ ..group, style: bind(group.style), })
      @flow.StyledNote(note) =>
        @flow.StyledNote({ ..note, style: bind(note.style), })
      _ => node
    }
  })
  { nodes, instructions: @flow.reduce(nodes), style: bind(self.style), }
}
