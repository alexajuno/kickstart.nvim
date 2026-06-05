return {
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'nvim-telescope/telescope.nvim',
    },
    keys = {
      { '<leader>gg', '<cmd>Neogit<cr>', desc = '[G]it status (Neo[g]it)' },
      { '<leader>gc', '<cmd>Neogit commit<cr>', desc = '[G]it [c]ommit' },
      { '<leader>gp', '<cmd>Neogit pull<cr>', desc = '[G]it [p]ull' },
      { '<leader>gP', '<cmd>Neogit push<cr>', desc = '[G]it [P]ush' },
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = '[G]it [d]iff view' },
      { '<leader>gD', '<cmd>DiffviewClose<cr>', desc = '[G]it [D]iff close' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = '[G]it [h]istory (file)' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<cr>', desc = '[G]it [H]istory (branch)' },
    },
    opts = {
      integrations = { diffview = true, telescope = true },
      graph_style = 'unicode',
    },
  },
}
