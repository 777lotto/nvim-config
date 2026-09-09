-- zemRip manual-review lanes (:Review). The plugin lives inside the zemRip
-- monorepo and is loaded by directory from a local checkout; which checkout,
-- and whether one exists at all, is decided by config.review.
return {
  require("config.review").spec(),
}
