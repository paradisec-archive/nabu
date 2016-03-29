ActiveAdmin.register AdminMessage do
  menu :parent => "Other Entities"
  config.sort_order = "message_asc"
  actions :all

  # Don't show timestamps of the ActiveRecord object (created_at or updated_at)
  index do
    selectable_column
    column :id, sortable: :id do |admin_message|
      link_to admin_message.id, admin_admin_message_path(admin_message)
    end
    column :message
    column :start_at
    column :finish_at
    actions
  end

  # Don't filter by timestamps of the ActiveRecord object (created_at or updated_at)
  # Filtering by the start_at and finish_at probably doesn't make much sense either
  filter :message

  # FIXME: When using `form`, I couldn't get the min_date and max_date options to do anything, and the interface starts off unintuitive.
  # The interface without using `form` has a large series of pulldown menus, without any sensible defaults.
  # form do |f|
  #   f.inputs do
  #     f.input :message
  #     f.input :start_at,  as: :datepicker, datepicker_options: { min_date: 3.days.ago.to_date, max_date: "+2W" }
  #     f.input :finish_at, as: :datepicker, datepicker_options: { min_date: 3.days.ago.to_date, max_date: "+1W +5D" }
  #   end
  #   f.actions
  # end
end
