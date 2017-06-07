{Range, CompositeDisposable} = require 'atom'
settings = require './settings'

module.exports =
  disposables: null
  config: settings.config

  activate: ->
    @disposables = new CompositeDisposable

    # for scope in ['atom-text-editor.vim-mode-plus', 'atom-text-editor', 'atom-workspace']
    #   @disposables.add atom.commands.add(scope, 'dev:propagate', @propagate)

    @disposables.add atom.commands.add 'atom-workspace',
      'dev:log-vim-state-mode': => @logVimStateMode()
      'dev:set-var-in-dev-tools': => @setVarInDevTools()
      'dev:throw-error': => @throwError()
      'dev:log-pane-layout': => @logPaneLayout()

  logPaneLayout: ->
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

    root = atom.workspace.getActivePane().getContainer().getRoot()
    inspect = require('util').inspect()
    console.log inspect(paneLayoutFor(root), depth: 10)

  throwError: ->
    try
      throw new Error('sample Error')
    catch error
      throw error

  setVarInDevTools: ->
    atom.openDevTools()
    console.clear()
    code = """
      e = atom.workspace.getActiveTextEditor()
      el = atom.views.getView(e)
      c = e.getLastCursor()
      s = e.getLastSelection()
      p = atom.workspace.getActivePane()
      """
    compiledCode = require('coffee-script').compile(code, bare: true)
    require('vm').runInThisContext(compiledCode)

  deactivate: ->
    @disposables?.dispose()

  consumeVimMode: (@vimModeService) ->

  logVimStateMode: ->
    vimState = @vimModeService.getEditorState(atom.workspace.getActiveTextEditor())
    console.log {mode: vimState.mode, submode: vimState.mode}
