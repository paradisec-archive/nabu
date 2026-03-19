# choices_ajax helper to make capybara work with ajax-enabled Choices.js elements
# assumes 'placeholder' option is used (if it is using ajax, it should be)
#
# usage:
#
#    it 'should have a choices field for searching by team name' do
#        @team = Factory :team
#        choices_ajax @team.name, from: 'Select a Team', minlength: 4
#        click_button 'Join'
#        expect(page).to have_content "You are now on '#{@team.name}'."
#    end

module CapybaraExt
  def choices_ajax(value, options = {})
    raise "Must pass a hash containing 'from'" if !options.is_a?(Hash) || !options.has_key?(:from)

    placeholder = options[:from]
    minlength = options[:minlength] || 2

    # Find the Choices container by label or placeholder
    container = begin
      find(:xpath, "//label[contains(text(),'#{placeholder}')]/ancestor::tr//div[contains(@class,'choices')]", wait: 5)
    rescue Capybara::ElementNotFound
      find("[data-placeholder='#{placeholder}']", wait: 5).ancestor('.choices')
    end

    # Click to open the dropdown
    container.find('.choices__inner').click

    # Type the search term
    input = container.find('.choices__input--cloned')
    input.send_keys(value[0, minlength])

    # Wait for results and click the matching item
    container.find('.choices__item', text: value, wait: 5).click
  end
end

RSpec.configure do |c|
  c.include CapybaraExt
end
