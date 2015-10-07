{CompositeDisposable} = require 'atom'
settings = require './settings'
{Range} = require 'atom'
vm = require 'vm'
coffee = require 'coffee-script'

module.exports =
  disposables: null
  config: settings.config
  clipboardHistory: []
  lastPasted: {}

  activate: (state) ->
    @patchClipboard()
    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add 'atom-workspace',
      'dev:logVimMode':                   => @logVimMode()
      'dev:log':                          (event) => @log(event)
      'dev:set-var-in-dev-tools':         => @setVarInDevTools()
      'dev:toggle-track-cursor-moved':    => @toggleConfig('trackCursorMoved')
      'dev:toggle-track-did-open':        => @toggleConfig('trackDidOpen')
      'dev:toggle-track-active-paneItem': => @toggleConfig('trackActivePaneItem')
      'dev:dump':                         => @dump()
      'dev:proj-folder-issue':            => @projFolderIssue()
      'dev:flash-selection':              => @flashSelection()
      'dev:flash-screen':                 =>
        @flashScreen atom.workspace.getActiveTextEditor(), 200

      'dev:log-scope-names': =>
        console.log @getGrammarScopeNames()

      'dev:get-candidates': =>
        editor = atom.workspace.getActiveTextEditor()
        @tokenProvider ?= @getTokenProvider(editor, /\w+/g)
        console.log @tokenProvider.get()
        @tokenProvider.destroy()
        @tokenProvider = null

    @disposables.add atom.workspace.observeTextEditors (editor) =>
      @disposables.add editor.onDidChangeCursorPosition (event) =>
        if @isTracked('CursorMoved')
          @handleCursorMoved event

    @disposables.add atom.workspace.observeActivePaneItem (item) =>
      if @isTracked('ActivePaneItem')
        @handleActivePaneItem item

    @disposables.add atom.workspace.onDidOpen (event) =>
      if @isTracked('DidOpen')
        @handleDidOpen event

  setVarInDevTools: ->
    atom.openDevTools()
    console.clear()
    code = """
    e = atom.workspace.getActiveTextEditor()
    c = e.getLastCursor()
    s = e.getLastSelection()
    """
    vm.runInThisContext coffee.compile(code, bare: true)

  projFolderIssue: ->
    folder = '/Users/tmaeda/github/atom'
    atom.workspace.open(folder + '/README.md').done (editor) ->
      editor.destroy()
    atom.project.removePath folder
    atom.project.addPath folder
    atom.workspace.open(folder + '/README.md').done (editor) ->
      editor.destroy()

  flashSelection: ->
    @editor = atom.workspace.getActiveTextEditor()
    for selection in @editor.getSelections()
      selection.setBufferRange(selection.getBufferRange(), flash: true)

  log: (event) ->
    # _ = require 'underscore-plus'
    projectView = null
    for panel in atom.workspace.getModalPanels() when panel.getItem().constructor.name is 'ProjectView'
      projectView = panel.getItem()
    return unless projectView

    pathForCurrentFile = atom.workspace.getActivePaneItem().getPath()
    currentProjectDir = null
    for dir in atom.project.getPaths() when pathForCurrentFile.startsWith(dir)
      currentProjectDir = dir
    paths = projectView.paths.filter (_path) ->
      _path.startsWith currentProjectDir
    projectView.setItems(paths)
    # currentProjectDir
    # console.log currentProjectDir

  getTokenProvider: (editor, pattern) ->
    matches = null

    get: ->
      return matches if matches
      matches = []
      editor.scan pattern, ({matchText}) ->
        matches.push matchText
      matches

    destroy: ->
      matches = null

  getGrammarScopeNames: ->
    atom.grammars.getGrammars().map (grammar) ->
      grammar.scopeName

  flashScreen: (editor, duration=150) ->
    [startRow, endRow] = editor.getVisibleRowRange().map (row) ->
      editor.bufferRowForScreenRow row

    range = [[startRow, 0], [endRow, Infinity]]
    marker = editor.markBufferRange range,
      invalidate: 'never'
      persistent: false

    flashingDecoration = editor.decorateMarker marker,
      type: 'highlight'
      class: 'dev-sample-flash'

    setTimeout ->
      flashingDecoration.getMarker().destroy()
    , duration

  isTracked: (eventName) -> settings.get("track#{eventName}")

  serialize: ->

  deactivate: ->
    @disposables?.dispose()
    @settings.dispose()

  consumeVimMode: (@vimModeService) ->

  dump: ->
    console.log @clipboardHistory

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  toggleConfig: (param) ->
    settings.toggle(param, log: true)

  handleCursorMoved: ({oldBufferPosition, newBufferPosition, cursor}) ->
    console.log "CursorMoved: #{oldBufferPosition} > #{newBufferPosition} #{cursor.editor.getURI()}"

  handleDidOpen: (event) ->
    {uri, item, pane, index} = event
    # {$, ScrollView} = require 'atom-space-pen-views'
    #
    #
    # if uri is 'atom://find-and-replace/project-results'
    #   item.resultsView.off 'mousedown'
    #
    #   atom.commands.add item.element,
    #     'user:confirm-and-continue': =>
    #       view = item.resultsView.find('.selected').view()
    #       if view?
    #         options = split: 'left', activatePane: false
    #         atom.workspace.open(view.filePath, options).then (editor) ->
    #           range = new Range(view.match.range...)
    #           marker = editor.markBufferRange(range)
    #           decoration = editor.decorateMarker(marker, type: 'highlight' , class: 'yank-highlight')
    #           decoration.flash('cursor-history-info', 100)
    #           editor.setSelectedBufferRange(range, autoscroll: true, flash: true)
    #       false


  handleActivePaneItem: (item) ->
    console.log "ActivePaneItem: #{item?.getURI()}"

  logVimMode: ->
    vimState = @getVimEditorState()
    console.log [ vimState.mode, vimState.submode ]

  getVimEditorState: ->
    editor = @getActiveTextEditor()
    @vimModeService.getEditorState(editor)

  go: ->
    console.log 'go!'
