{Range, CompositeDisposable} = require 'atom'
vm = require 'vm'
coffee = require 'coffee-script'
{inspect} = require 'util'
settings = require './settings'
# _ = require 'underscore-plus'

{paneLayoutFor} = require './utils'

module.exports =
  disposables: null
  config: settings.config
  clipboardHistory: []
  lastPasted: {}

  activate: (state) ->
    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add 'atom-workspace',
      'dev:logVimMode': => @logVimMode()
      'dev:log': (event) => @log(event)
      'dev:set-var-in-dev-tools': => @setVarInDevTools()
      'dev:toggle-track-cursor-moved': => @toggleConfig('trackCursorMoved')
      'dev:toggle-track-selection-change': => @toggleConfig('trackSelectionChanged')
      'dev:toggle-track-did-open': => @toggleConfig('trackDidOpen')
      'dev:toggle-track-active-paneItem': => @toggleConfig('trackActivePaneItem')
      'dev:dump': => @dump()
      'dev:throw-error': => @throwError()
      'dev:flash-selection': => @flashSelection()
      'dev:log-pane-layout': => @logPaneLayout()
      'dev:flash-screen': =>
        @flashScreen atom.workspace.getActiveTextEditor(), 200
      'dev:get-resut-marker-layer': =>
        @getResultsMarkerLayerForTextEditor()

      'dev:log-scope-names': =>
        console.log @getGrammarScopeNames()

      'dev:get-candidates': =>
        editor = atom.workspace.getActiveTextEditor()
        @tokenProvider ?= @getTokenProvider(editor, /\w+/g)
        console.log @tokenProvider.get()
        @tokenProvider.destroy()
        @tokenProvider = null

      'dev:hello': ->
        console.log "dev:hello"

      # 'dev:mark': ->
      #   console.log "dev:mark"
      #   editorElement = document.createElement "atom-text-editor"
      #   editorElement.classList.add('editor')
      #   editorElement.getModel().setMini(true)
      #   editorElement.setAttribute('mini', '')
      #   atom.workspace.addBottomPanel(item: editorElement, priority: 100)
      #   editorElement.focus()

      # 'dev:flash-screen': =>

    @disposables.add atom.workspace.observeTextEditors (editor) =>
      # console.log "HELLO!!"
      # editorElement = atom.views.getView(editor)
      # editorElement.onDidAttach =>
      #   console.log 'attached!'
      # editorElement.component.updateSync()
      # console.log 'visible row range', editor.getVisibleRowRange()
      @disposables.add editor.onDidChangeCursorPosition (event) =>
        if @isTracked('CursorMoved')
          @handleCursorMoved event
      @disposables.add editor.onDidChangeSelectionRange ({oldBufferRange, newBufferRange}) =>
        if @isTracked('SelectionChanged')
          console.log "selection Changed! from #{oldBufferRange.toString()} to #{newBufferRange.toString()}"

    @disposables.add atom.workspace.observeActivePaneItem (item) =>
      if @isTracked('ActivePaneItem')
        @handleActivePaneItem item

    @disposables.add atom.workspace.onDidOpen (event) =>
      if @isTracked('DidOpen')
        @handleDidOpen event

  logPaneLayout: ->
    root = atom.workspace.getActivePane().getContainer().getRoot()
    # console.log inspect(getPaneLayout(root), depth: 10)
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
    container = p.getContainer()
    root = container.getRoot()
    """
    vm.runInThisContext coffee.compile(code, bare: true)

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
    settings.dispose()

  consumeVimMode: (@vimModeService) ->


  # "find-and-replace": {
  #   "versions": {
  #     "0.0.1": "consumeFindAndReplace"
  #   }
  # }
  consumeFindAndReplace: (service) ->
    console.log service
    {@resultsMarkerLayerForTextEditor} = service

  getResultsMarkerLayerForTextEditor: ->
    editor = @getActiveTextEditor()
    console.log @resultsMarkerLayerForTextEditor(editor)

  dump: ->
    console.log @clipboardHistory

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  toggleConfig: (param) ->
    settings.toggle(param, log: true)

  handleCursorMoved: ({oldBufferPosition, newBufferPosition, cursor}) ->
    console.log "CursorMoved: #{oldBufferPosition} > #{newBufferPosition}"

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
