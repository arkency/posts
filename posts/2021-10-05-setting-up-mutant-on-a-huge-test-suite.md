---
title: Setting up Mutant on a huge test suite
created_at: 2021-10-05T11:27:06.776Z
author: Tomasz Wróbel
tags: []
publish: false
---



require tracing


bumpnąć gemiki capybara i reek żeby odblokować dependency na parser i regexp dla mutanta

usunąć obsolete database_cleaner i jego copypaste truncation które psuje współbieżność, standard railsowy jest szybszy i lepszy

dodać mutanta z require na config/environment oraz na pliku robiącym Rails.configuration.eager_load = true

na CI używać bundle exec mutant subscription test && env RAILS_ENV=test bundle exec mutant run --since master aby odsiać tych co nie mają licencji (i będzie wisiało 40s) oraz mutować dodany kodzik

env RAILS_ENV=test bundle exec mutant run --since master

j1

Rails.configuration.eager_load = true

require 'mutant/integration/rspec'

Mutant::Integration::Rspec.send(:remove_const,:CLI_OPTIONS)
Mutant::Integration::Rspec::CLI_OPTIONS = %w[spec/modules/booking_financials --fail-fast].freeze

before(:suite) do
  # czy find_or_create jest tutaj w transakcji czy nie, przy wspólżbieżności jest kupa
end



https://github.com/mbj/mutant/blob/main/docs/mutant-rspec.md#test-selection
https://github.com/mbj/mutant/blob/main/docs/configuration.md

https://github.com/RailsEventStore/ecommerce/blob/master/rails_application/.mutant.yml — example
