# select2_ajax helper to make capybara work with ajax-enabled Select2 elements
# assumes 'placeholder' option is used in Select2 (if it is using ajax, it should be)
#
# usage:
#
#    it "should have a select2 field for searching by team name" do
#        @team = Factory :team
#        select2_ajax @team.name, :from => "Select a Team", :minlength => 4
#        click_button "Join"
#        expect(page).to have_content "You are now on '#{@team.name}'."
#    end

module CapybaraExt

  def select2_ajax value, options={}
    raise "Must pass a hash containing 'from'" if not options.is_a?(Hash) or not options.has_key?(:from)

    placeholder = options[:from]
    minlength = options[:minlength] || 4

    #click_link placeholder

    js = %Q|
      var label = $('label:contains("#{placeholder}")');
      var input = null;
      if (label && label.prop("for")) {
        input = $('#' + label.prop("for"));
      } else {
        input = $('[data-placeholder*="#{placeholder}"]');
      }

      if (input) {
        input.val('#{value}');
      } else {
        console.error("Failed to find label or input with placeholder");
      }
    |
    page.execute_script(js)
  end

end

RSpec.configure do |c|
  c.include CapybaraExt
end
