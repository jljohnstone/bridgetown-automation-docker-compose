# frozen_string_literal: true

module CapybaraAutomation
  module Utils
    def gem_exist?(gem_name)
      # Redirect stdout to /dev/null because we dont need the gem info
      return true if system("bundle info #{gem_name} 1> /dev/null")

      false
    end

    private
  end
end
