# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
ActiveSupport::Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
  inflect.irregular 'field_of_research', 'fields_of_research'
  inflect.irregular 'FieldOfResearch', 'FieldsOfResearch'
  inflect.irregular 'Field Of Research', 'Fields Of Research'
end
