# frozen_string_literal: true

require 'fileutils'
require 'shellwords'

# Dynamically determined due to having to load from the tempdir
@current_dir = File.expand_path(__dir__)

# If its a remote file, the branch is appended to the end, so go up a level
# IE: https://blah-blah-blah/bridgetown-plugin-tailwindcss/master
ROOT_PATH = if __FILE__ =~ %r{\Ahttps?://}
              File.expand_path('../', __dir__)
            else
              File.expand_path(__dir__)
            end

DIR_NAME = File.basename(ROOT_PATH)

GITHUB_PATH = "https://github.com/ParamagicDev/#{DIR_NAME}.git"

def determine_template_dir(current_dir = @current_dir)
  File.join(current_dir, 'templates')
end

def require_libs
  source_paths.each do |path|
    Dir["#{path}/lib/*.rb"].sort.each { |file| require file }
  end
end

# Copied from: https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'

    source_paths.unshift(tempdir = Dir.mktmpdir(DIR_NAME + '-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    run("git clone --quiet #{GITHUB_PATH.shellescape} #{tempdir.shellescape}")

    if (branch = __FILE__[%r{#{DIR_NAME}/(.+)/bridgetown.automation.rb}, 1])
      Dir.chdir(tempdir) { system("git checkout #{branch}") }
      @current_dir = File.expand_path(tempdir)
    end
  else
    source_paths.unshift(ROOT_PATH)
  end
end

def read_template_file(filename)
  File.read(File.join(determine_template_dir, filename))
end

def copy_capybara_file(config)
  FileUtils.mkdir_p(config.naming_convention.to_s)
  dest = File.join(config.naming_convention.to_s, 'capybara_helper.rb')
  src = File.join(ROOT_PATH, 'templates', 'capybara_helper.rb.tt')

  template(src, dest)
end

add_template_repository_to_source_path
require_libs

@config = CapybaraAutomation::Configuration.new

@config.ask_questions

# Set these so we can use them in our templates
@distro = @config.distro
@ruby_version = @config.ruby_version
