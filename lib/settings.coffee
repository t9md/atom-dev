{Disposable} = require 'atom'

inferType = (value) ->
  switch
    when Number.isInteger(value) then 'integer'
    when typeof(value) is 'boolean' then 'boolean'
    when typeof(value) is 'string' then 'string'
    when Array.isArray(value) then 'array'

class Settings
  deprecatedParams: [
  ]
  notifyDeprecatedParams: ->
    deprecatedParams = @deprecatedParams.filter((param) => @has(param))
    return if deprecatedParams.length is 0

    content = [
      "#{@scope}: Config options deprecated.  ",
      "Remove from your `connfig.cson` now?  "
    ]
    content.push "- `#{param}`" for param in deprecatedParams

    notification = atom.notifications.addWarning content.join("\n"),
      dismissable: true
      buttons: [
        {
          text: 'Remove All'
          onDidClick: =>
            @delete(param) for param in deprecatedParams
            notification.dismiss()
        }
      ]

  constructor: (@scope, @config) ->
    # Automatically infer and inject `type` of each config parameter.
    # skip if value which aleady have `type` field.
    # Also translate bare `boolean` value to {default: `boolean`} object
    for key in Object.keys(@config)
      if typeof(@config[key]) is 'boolean'
        @config[key] = {default: @config[key]}
      unless (value = @config[key]).type?
        value.type = inferType(value.default)

    # [CAUTION] injecting order propety to set order shown at setting-view MUST-COME-LAST.
    for name, i in Object.keys(@config)
      @config[name].order = i

  has: (param) ->
    param of atom.config.get(@scope)

  delete: (param) ->
    @set(param, undefined)

  get: (param) ->
    atom.config.get("#{@scope}.#{param}")

  set: (param, value) ->
    atom.config.set("#{@scope}.#{param}", value)

  toggle: (param) ->
    @set(param, not @get(param))

  observe: (param, fn) ->
    atom.config.observe("#{@scope}.#{param}", fn)

module.exports = new Settings 'dev',
  trackCursorMoved: false
  trackDidOpen: false
  trackDidAddPane: false
  trackActivePaneItem: false
  trackSelectionChanged: false
