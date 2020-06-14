# frozen_string_literal: true

require 'thor'

module CapybaraAutomation
  class Configuration < Thor::Group
    include Thor::Actions

    # Invert so we can call TEST_FRAMEWORK_OPTIONS[1] #=> :rspec
    FRAMEWORKS = {
      rspec: 1,
      minitest: 2,
      test_unit: 3
    }.invert

    NAMING_CONVENTION = {
      test: 1,
      spec: 2
    }.invert

    attr_accessor :framework, :naming_convention

    def initialize
      @framework = nil
      @naming_convention = nil
    end

    def frameworks
      FRAMEWORKS
    end

    def naming_conventions
      NAMING_CONVENTION
    end

    def ask_questions
      ask_for_testing_framework if @framework.nil?
      ask_for_naming_convention if @naming_convention.nil?
    end

    private

    def ask_for_input(question, answers)
      answer = nil

      provide_input = "Please provide a number (1-#{answers.length})"

      allowable_answers = answers.keys
      loop do
        say "\n#{question}"
        answers.each { |num, string| say "#{num}.) #{string}", :cyan }
        answer = ask("\n#{provide_input}:\n ", :magenta).strip.to_i

        return answer if allowable_answers.include?(answer)

        say "\nInvalid input given", :red
      end
    end

    def ask_for_testing_framework
      question = 'What testing framework would you like to use?'

      answers = frameworks

      input = ask_for_input(question, answers)

      @framework = answers[input]
    end

    def ask_for_naming_convention
      question = 'What naming convention would you like use?'

      answers = naming_conventions

      input = ask_for_input(question, answers)

      @naming_convention = answers[input]
    end
  end
end
