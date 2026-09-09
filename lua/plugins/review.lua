-- zemRip manual-review lanes (:Review), served by the curate-review fleet
-- plugin. The plugin resolves the zemRip checkout its backend runs from:
-- $NVIM_ZEMRIP_ROOT, then upward from the working directory, then ~/zemrip
-- and ~/works/zemrip. Without one, :Review reports where it looked.
return {
  {
    "777lotto/curate-review",
    branch = "bluff",
    main = "curate_review",
    cmd = { "Review", "ReviewSync", "ReviewDiff", "ReviewStop" },
    keys = {
      { "<leader>av", "<cmd>Review<cr>", desc = "Review dashboard" },
    },
    opts = {
      open = "buffer",
    },
  },
}
