---
created_at: 2020-04-24T11:09:54.260Z
author: Tomasz Wróbel
tags: []
publish: false
---

# Non-transactional tests

The option was once called `use_transactional_fixtures`. Since Rails 5 it's: `use_transactional_tests` - more adequately.

Rails still cleans up for you by reloading fixtures (?)

But you may need to still clean up yourself if you do something fancy, like `CREATE SCHEMA`. In such situations use `teardown` to make sure it's cleaned up even when the test fails.

TODO: When is this usually needed? 

The setting seems to work per test class. TODO can we make it work per test?

database cleaner gem



