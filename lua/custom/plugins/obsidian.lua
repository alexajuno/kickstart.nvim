return {
  'obsidian-nvim/obsidian.nvim',
  enabled = true,
  ft = 'markdown',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    workspaces = {
      { name = 'wiki', path = '~/wiki' },
      { name = 'life', path = '~/life' },
      { name = 'notes', path = '~/notes' },
    },
    legacy_commands = false,
    completion = { blink = true, min_chars = 2 },
    ui = { enable = false }, -- render-markdown.nvim handles rendering
    picker = { name = 'telescope.nvim' },
    -- Link navigation: follows both [[wiki-links]] and [text](path.md) links.
    link = {
      -- New links created from a word/selection use [[wiki-link]] style.
      style = 'wiki',
      -- Make link paths relative to the current note so they resolve across
      -- the ~/wiki, ~/life and ~/notes workspaces.
      format = 'relative',
    },
    -- Default keymaps (buffer-local to markdown, no clashes with existing config):
    --   <CR>   smart_action  -> follow link / toggle checkbox / cycle heading fold
    --   [o ]o  nav_link      -> previous / next link in the buffer
    -- See the report / wiki doc for the full command list.
  },
}
