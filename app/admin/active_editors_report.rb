# rubocop:disable Metrics/BlockLength
ActiveAdmin.register_page 'Active Editors' do
  menu priority: 5, label: 'Active Editors'

  content do
    # Default to last 12 months
    months = (params.dig(:filter, :months) || 12).to_i
    start_date = months.months.ago.beginning_of_day
    end_date = Time.current

    # Query versions, group by whodunnit to get stats per user
    user_stats = PaperTrail::Version
      .where(created_at: start_date..end_date)
      .where.not(whodunnit: [nil, ''])
      .group(:whodunnit)
      .select(
        'whodunnit',
        'COUNT(*) as edit_count',
        'MAX(created_at) as last_edit',
        'MIN(created_at) as first_edit',
        'GROUP_CONCAT(DISTINCT item_type ORDER BY item_type SEPARATOR ", ") as item_types'
      )
      .order('edit_count DESC')

    # Preload users to avoid N+1
    user_ids = user_stats.map(&:whodunnit)
    users_by_id = User.where(id: user_ids).index_by { |u| u.id.to_s }

    # Filter form
    select_classes = 'w-64 appearance-none rounded-md bg-white dark:bg-gray-950/75 py-1.5 pr-8 pl-3 text-base ' \
                     'text-gray-900 dark:text-white outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 ' \
                     'focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6'

    panel 'Filter' do
      form action: admin_active_editors_path, method: :get do
        div class: 'flex flex-row gap-4 items-center' do
          label 'Show editors from the last', for: 'filter_months'
          select_options = options_for_select(
            [3, 6, 12, 24, 36].map { |m| ["#{m} months", m] },
            months
          )
          text_node select_tag('filter[months]', select_options, id: 'filter_months', class: select_classes)
          text_node submit_tag('Filter', class: 'action-item-button')
        end
      end
    end

    # Summary
    panel "#{user_stats.length} Active Editors (last #{months} months)" do
      table_for user_stats do
        column 'User' do |stat|
          user = users_by_id[stat.whodunnit]
          if user
            link_to user.name, admin_user_path(user)
          else
            "Unknown (ID: #{stat.whodunnit})"
          end
        end
        column 'Email' do |stat|
          users_by_id[stat.whodunnit]&.email
        end
        column 'Total Edits', :edit_count
        column 'Record Types', :item_types
        column 'First Edit', :first_edit
        column 'Last Edit', :last_edit
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
