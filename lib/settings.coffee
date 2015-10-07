ConfigPlus = require 'atom-config-plus'

config =
  trackCursorMoved:
    order: 11
    type: 'boolean'
    default: false
  trackDidOpen:
    order: 12
    type: 'boolean'
    default: true
  trackDidAddPane:
    order: 13
    type: 'boolean'
    default: true
  trackActivePaneItem:
    order: 14
    type: 'boolean'
    default: true

module.exports = new ConfigPlus 'dev', config
