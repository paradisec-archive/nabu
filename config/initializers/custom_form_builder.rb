require Rails.root.join('app/helpers/custom_form_builder')

ActionView::Base.default_form_builder = CustomFormBuilder
