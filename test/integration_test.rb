# frozen_string_literal: true

require 'test_helper'
require 'open3'

GITHUB_REPO_NAME = 'bridgetown-automation-docker-compose'
BRANCH = `git branch --show-current`.chomp.freeze || 'master'

module CapybaraAutomation
  class IntegrationTest < Minitest::Test
    def setup
      Rake.rm_rf(TEST_APP)
      Rake.mkdir_p(TEST_APP)
    end

    def read_test_file(filename)
      File.read(File.join(TEST_APP, filename))
    end

    def read_template_file(filename)
      File.read(File.join(TEMPLATES_DIR, filename))
    end

    def run_command(cmd, *inputs)
      Open3.popen3(cmd) do |stdin, stdout, _stderr, wait_thr|
        pid = wait_thr.pid

        inputs.flatten.each { |input| stdin.puts(input) }

        stdout.each_line do |line|
          puts line
        end
        exit_status = wait_thr.value
      end
    end

    def run_assertions(framework:, naming_convention:)
      helper_file = read_template_file("#{framework}_helper.rb.tt")
      capybara_helper_file = read_test_file(File.join(naming_convention.to_s, 'capybara_helper.rb'))

      assert_match(/#{helper_file}/, capybara_helper_file)
    end

    def test_it_works_with_local_automation
      Rake.cd TEST_APP

      run_pre_bundle_commands
      Rake.sh('bundle exec bridgetown new . --force ')

      rspec = '1' # => :rspec
      spec = '2' # => :spec

      run_command('bridgetown apply ../bridgetown.automation.rb', rspec, spec)

      run_assertions(framework: :rspec, naming_convention: :spec)
    end

    # Have to push to github first, and wait for github to update
    # def test_it_works_with_remote_automation
    #   Rake.cd TEST_APP

    #   github_url = 'https://github.com'
    #   user_and_reponame = "ParamagicDev/#{GITHUB_REPO_NAME}/tree/#{BRANCH}"

    #   file = 'bridgetown.automation.rb'

    #   url = "#{github_url}/#{user_and_reponame}/#{file}"

    #   minitest = '2' # => :minitest
    #   test = '1' # => :test

    #   run_pre_bundle_commands
    #   run_command("bundle exec bridgetown new . --force --apply='#{url}'", minitest, test)

    #   run_assertions(framework: :minitest, naming_convention: :test)
    # end
  end
end
