paneLayoutFor = (root) ->
  activePane = atom.workspace.getActivePane()
  switch root.constructor.name
    when 'Pane'
      {activeItem} = root
      isActivePane = root is activePane
      root.getItems().map (item) ->
        title = item.getTitle()
        if item is activeItem
          title = '*' + title
          title = "[[#{title}]]" if isActivePane
        title
    when 'PaneAxis'
      children = root.getChildren()
      orientationChar = switch root.getOrientation()
        when 'vertical' then '-'
        when 'horizontal' then '|'
      key = "#{orientationChar}:#{children.length}"
      layout = {}
      layout[key] = children.map(paneLayoutFor)
      layout

module.exports = {
  paneLayoutFor
}
