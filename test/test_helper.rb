# frozen_string_literal: true

require 'minitest'
require 'minitest/autorun'
require 'minitest/reporters'
require 'rake'

LIB_NAME = 'bridgetown-automation-docker-compose'
require LIB_NAME

ROOT_DIR = File.expand_path('..', __dir__)

TEMPLATES_DIR = File.join(ROOT_DIR, 'templates')
TEST_DIR = File.expand_path(__dir__)
TEST_APP = File.expand_path('test_app')
TEST_GEMFILE = File.join(TEST_APP, 'Gemfile')

reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]

    def read_test_file(filename)
      File.read(File.join(TEST_APP, filename))
    end

    def read_template_file(filename)
      File.read(File.join(TEMPLATES_DIR, "#{filename}.tt"))
    end

