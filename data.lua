local item = {
  type = 'selection-tool',
  name = 'artillery-bombardment-remote',
  subgroup = 'capsule',
  order = 'zzz[artillery-bombardment-remote]',
  icons = {
    {
      icon = '__artillery-bombardment-remote-2__/graphics/icons/artillery-bombardment-remote.png',
      icon_size = 32
    }
  },
  select = {
    border_color = {r = 1, g = 0.28, b = 0, a = 1},
    cursor_box_type = 'entity',
    mode = {'enemy'}
  },
  alt_select = {
    border_color = {r = 0, g = 0, b = 1, a = 1},
    cursor_box_type = 'entity',
    mode = {'enemy'}
  },
  stack_size = 1,
  flags = { "mod-openable", "spawnable" },
  hidden = false
}

local item_shortcut = {
  type = 'shortcut',
  name = 'artillery-bombardment-remote-shortcut',
  action = 'spawn-item',
  item_to_spawn = 'artillery-bombardment-remote'
}

local smart_item = {
  type = 'selection-tool',
  name = 'smart-artillery-bombardment-remote',
  subgroup = 'capsule',
  order = 'zzz[smart-artillery-bombardment-remote]',
  icons = {
    {
      icon = '__artillery-bombardment-remote-2__/graphics/icons/smart-artillery-bombardment-remote.png',
      icon_size = 32
    }
  },
  select = {
    border_color = {r = 1, g = 0.28, b = 0, a = 1},
    cursor_box_type = 'entity',
    mode = {'enemy'}
  },
  alt_select = {
    border_color = {r = 0, g = 0, b = 1, a = 1},
    cursor_box_type = 'entity',
    mode = {'enemy'}
  },
  flags = {'mod-openable', 'spawnable'},
  stack_size = 1
}

local smart_item_shortcut = {
  type = 'shortcut',
  name = 'smart-artillery-bombardment-remote-shortcut',
  action = 'spawn-item',
  item_to_spawn = 'smart-artillery-bombardment-remote'
}

local exploration_item = {
  type = 'selection-tool',
  name = 'smart-artillery-exploration-remote',
  subgroup = 'capsule',
  order = 'zzz[smart-artillery-exploration-remote]',
  icons = {
    {
      icon = '__artillery-bombardment-remote-2__/graphics/icons/smart-artillery-exploration-remote.png',
      icon_size = 32
    }
  },
  select = {
    border_color = {r = 1, g = 0.28, b = 0, a = 1},
    cursor_box_type = 'entity',
    mode = {'enemy'}
  },
  alt_select = {
    border_color = {r = 0, g = 0, b = 1, a = 1},
    cursor_box_type = 'entity',
    mode = {'enemy'}
  },
  flags = {'mod-openable', 'spawnable'},
  stack_size = 1,
  entity_filters = {'artillery-turret', 'artillery-wagon'}
}

local exploration_item_shortcut = {
  type = 'shortcut',
  name = 'smart-artillery-exploration-remote-shortcut',
  action = 'spawn-item',
  item_to_spawn = 'smart-artillery-exploration-remote'
}

local recipe = {
  type = 'recipe',
  category = 'crafting',
  name = 'artillery-bombardment-remote',
  enabled = false,
  ingredients = {
    {type='item', name='radar', amount=5},
    {type='item', name='processing-unit', amount=100},
    {type='item', name='advanced-circuit', amount=200},
    {type='item', name='electronic-circuit', amount=200}
  },
  results = {
    {type='item', name='artillery-bombardment-remote', amount=1}
  }
}

local smart_recipe = {
  type = 'recipe',
  category = 'crafting',
  name = 'smart-artillery-bombardment-remote',
  enabled = false,
  ingredients = {
    {type='item', name='artillery-bombardment-remote', amount=5}
  },
  results = {
    {type='item', name='smart-artillery-bombardment-remote', amount=1}
  }
}

local exploration_recipe = {
  type = 'recipe',
  category = 'crafting',
  name = 'smart-artillery-exploration-remote',
  enabled = false,
  ingredients = {
    {type='item', name='smart-artillery-bombardment-remote', amount=5}
  },
  results = {
    {type='item', name='smart-artillery-exploration-remote', amount=1}
  }
}

local original_tech = table.deepcopy(data.raw.technology['artillery'])
original_tech.unit.ingredients = {
  {'automation-science-pack', 1},
  {'logistic-science-pack', 1},
  {'chemical-science-pack', 1},
  {'military-science-pack', 1},
  {'utility-science-pack', 1},
  {'space-science-pack', 1}
}
original_tech.icons = {
  {
    icon = table.deepcopy(original_tech.icon),
    icon_size = table.deepcopy(original_tech.icon_size)
  }
}

local technology = table.deepcopy(original_tech)
technology.name = 'artillery-bombardment-remote'
technology.effects = {
  {
    type = 'unlock-recipe',
    recipe = 'artillery-bombardment-remote'
  }
}
technology.prerequisites = {'artillery'}
technology.unit.count = 2500
technology.order = 'd-e-f-y'
table.insert(
  technology.icons,
  {
    icon = '__artillery-bombardment-remote-2__/graphics/icons/artillery-bombardment-remote.png',
    icon_size = 32,
    scale = 2,
    shift = {98, 98}
  }
)

local smart_technology = table.deepcopy(original_tech)
smart_technology.name = 'smart-artillery-bombardment-remote'
smart_technology.effects = {
  {
    type = 'unlock-recipe',
    recipe = 'smart-artillery-bombardment-remote'
  }
}
smart_technology.prerequisites = {'artillery-bombardment-remote'}
smart_technology.unit.count = 25000
smart_technology.order = 'd-e-f-z'
table.insert(
  smart_technology.icons,
  {
    icon = '__artillery-bombardment-remote-2__/graphics/icons/smart-artillery-bombardment-remote.png',
    icon_size = 32,
    scale = 2,
    shift = {98, 98}
  }
)

local exploration_technology = table.deepcopy(original_tech)
exploration_technology.name = 'smart-artillery-exploration-remote'
exploration_technology.effects = {
  {
    type = 'unlock-recipe',
    recipe = 'smart-artillery-exploration-remote'
  }
}
exploration_technology.prerequisites = {'artillery'}
exploration_technology.unit.count = 50000
exploration_technology.order = 'd-e-f-z'
table.insert(
  exploration_technology.icons,
  {
    icon = '__artillery-bombardment-remote-2__/graphics/icons/smart-artillery-exploration-remote.png',
    icon_size = 32,
    scale = 2,
    shift = {98, 98}
  }
)

data:extend {item, smart_item, exploration_item, recipe, smart_recipe, exploration_recipe, technology, smart_technology, exploration_technology}
