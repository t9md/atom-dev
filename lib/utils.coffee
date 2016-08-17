paneLayoutFor = (root) ->
  activePane = atom.workspace.getActivePane()
  layout = {}
  children = root.getChildren()
  orientationChar = switch root.getOrientation()
    when 'vertical' then '-'
    when 'horizontal' then '|'

  key = "#{orientationChar}:#{children.length}"
  layout[key] = root.getChildren().map (child) ->
    switch child.constructor.name
      when 'Pane'
        {activeItem} = child
        isActivePane = child is activePane
        child.getItems().map (item) ->
          title = item.getTitle()
          if item is activeItem
            title = '*' + title
            title = "[[#{title}]]" if isActivePane
          title
      when 'PaneAxis'
        paneLayoutFor(child)
  layout

module.exports = {
  paneLayoutFor
}
