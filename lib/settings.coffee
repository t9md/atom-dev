ConfigPlus = require 'atom-config-plus'

config =
  # _group1: {
  #   title: 'Group 1',
  #   type: 'object',
  #   order: 1,
  #   properties: {
  #     prop1: {
  #       type: 'integer',
  #       title: 'Prop1',
  #       default: 1
  #     },
  #     prop2: {
  #       title: 'Prop2'
  #       default: 1
  #     },
  #   },
  # },
  # _group2: {
  #   title: 'Group 2',
  #   type: 'object',
  #   order: 2,
  #   properties: {
  #     prop1: {
  #       type: 'integer',
  #       # title: 'Prop1',
  #       default: 1
  #     },
  #     prop2: {
  #       # title: 'Prop2'
  #       default: 1
  #     },
  #   },
  # }
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
  trackSelectionChanged:
    order: 15
    type: 'boolean'
    default: false

module.exports = new ConfigPlus 'dev', config
