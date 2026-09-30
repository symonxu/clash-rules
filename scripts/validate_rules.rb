#!/usr/bin/env ruby
load File.expand_path('validate_shadowrocket.rb', __dir__)
load File.expand_path('validate_clashverge.rb', __dir__)
require 'rbconfig'
abort 'Clash sync offline tests failed' unless system(RbConfig.ruby, File.expand_path('../tools/clash-sync/test_sync.rb', __dir__))
