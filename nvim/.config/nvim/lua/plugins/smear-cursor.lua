return {
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      -- Adjust responsiveness and trail decay
      stiffness = 0.8,
      trailing_stiffness = 0.5,
      distance_stop_animating = 0.5,
      hide_target_hack = false,
    },
  },
}
