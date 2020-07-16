# frozen_string_literal: true

require 'test_helper'
require 'tempfile'

GITHUB_REPO_NAME = 'bridgetown-automation-docker-compose'
BRANCH = `git branch --show-current`.chomp.freeze || 'master'

module DockerComposeAutomation
  class IntegrationTest < Minitest::Test
    def setup
      Rake.rm_rf(TEST_APP)
      ENV['DESTINATION'] = TEST_APP
      Rake.mkdir_p(TEST_APP)
    end

    def run_assertions(ruby_version:, distro:)
      FILES.each do |file|
        next if file == 'Dockerfile'

        test_file = read_test_file(file)
        template_file = read_template_file(file)
        assert_match test_file, template_file
      end

      # Check if ruby version loaded properly
      dockerfile = read_test_file('Dockerfile')
      ruby_regex = /FROM ruby:(?<ruby_version>\d+\.\d+)/
      dockerfile_ruby_version = dockerfile.match(ruby_regex)[:ruby_version]
      assert_equal dockerfile_ruby_version, ruby_version

      # Check if distro loaded properly
      distro_regex = /#{ruby_regex}[- ](?<distro>\w+)\s+/
      distro_match = dockerfile.match(distro_regex)
      assert distro_match

      # Use the match group, if it doesnt exist, it means its debian based.
      docker_distro = dockerfile.match(distro_regex)[:distro].to_sym
      docker_distro = :debian if docker_distro == 'as'
      assert_equal(distro, docker_distro)
    end

    def create_inputs(ruby_version:, distro:)
      distros = Configuration::DISTROS.invert
      ruby_versions = Configuration::DOCKER_RUBY_VERSIONS.invert

      distro_input = distros[distro].to_s
      ruby_version_input = ruby_versions[:"#{ruby_version}"].to_s

      { ruby_version: ruby_version_input, distro: distro_input }
    end

    def full_url
      github_url = 'https://raw.githubusercontent.com/'
      repo_path = "ParamagicDev/#{GITHUB_REPO_NAME}/"
      installer_path = "#{BRANCH}/installer.sh"
      github_url + repo_path + installer_path
    end

    def path_to_installer
      File.join(ROOT_DIR, 'installer.sh')
    end

    def local_install
      %(/bin/bash -c "#{path_to_installer} #{BRANCH}")
    end

    def remote_install(full_url)
      %(/bin/bash -c "$(curl -fsSl #{full_url}) #{BRANCH}")
    end

    def test_it_works_with_local_automation
      Rake.cd TEST_APP

      distro = :alpine
      ruby_version = '2.6'

      inputs = create_inputs(distro: distro, ruby_version: ruby_version)

      ruby_version_input = inputs[:ruby_version]
      distro_input = inputs[:distro]

      ENV["PROJECT_TYPE"] = "new"
      ENV["DOCKER_RUBY_VERSION"] = ruby_version_input
      ENV["DOCKER_DISTRO"] = distro_input
      Rake.sh("DOCKER_DISTRO=#{distro_input} DOCKER_RUBY_VERSION=#{ruby_version_input} #{local_install}")

      run_assertions(ruby_version: ruby_version, distro: distro)
    end

    # Have to push to github first, and wait for github to update
    # def test_it_works_with_remote_automation
    #   Rake.cd TEST_APP

    #   distro = :alpine
    #   ruby_version = '2.6'

    #   inputs = create_inputs(distro: distro, ruby_version: ruby_version)

    #   ruby_version_input = inputs[:ruby_version]
    #   distro_input = inputs[:distro]

    #   ENV['PROJECT_TYPE'] = 'new'
    #   run_command(ruby_version_input, distro_input) do
    #     remote_install(full_url)
    #   end

    #   run_assertions(ruby_version: ruby_version, distro: distro)
    # end
  end
end
