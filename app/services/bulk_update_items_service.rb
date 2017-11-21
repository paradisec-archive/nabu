class BulkUpdateItemsService
  def initialize(item_ids:, updates:, current_user_email:)
    @item_ids = item_ids
    @current_user_email = current_user_email
    @start_time = Time.now
    process_updates(updates)
  end

  def update_items
    Rails.logger.info {"#{DateTime.now} BEFORE Bulk update with #{items.size} items"}
    @failed_items = []
    items.each do |item|
      begin
        appending = {}
        @appendable.each_pair do |k, v|
          existing = item.public_send(k)
          appending[k] = existing.present? ? existing + v : v
        end

        @deletable.each_pair do |k, v|
          item.send("#{k}=", item.send(k) - v)
        end

        if item.update_attributes(@updates.merge(appending))
          ItemCatalogService.new(item).save_file
        else
          @failed_items << item
        end
      rescue => e
        Rails.logger.error {"#{DateTime.now} DURING Bulk update - Failed to process #{item.full_identifier}. #{e}"}
        @failed_items << item unless @failed_items.include?(item)
      end
    end

    if @current_user_email.present?
      BulkEditReportMailer.bulk_edit_report_email(
        @current_user_email,
        @failed_items,
        items.size,
        @start_time.in_time_zone('Australia/Sydney')
      ).deliver
    end
  end

  def items
    @items ||= Item.includes(
      :data_categories, :data_types, :countries, :content_languages,
      :subject_languages, :university, :collector, :essences, :operator,
      :discourse_type, :admins, :access_condition, :comments,
      item_agents: [:agent_role, :user],
      collection: [
        :countries, :languages, :collector, :university, :admins,
        :access_condition, :field_of_research, :grants, :operator,
        items: [:admins]
    ]
    ).where(id: @item_ids)
  end

  def process_updates(updates)
    @updates = updates.delete_if {|_k, v| v.blank?}
    @appendable = {}
    @updates.each_pair do |k, v|
      if k =~ /^bulk_edit_append_(.*)/
        @appendable[$1] = @updates[$1] if v == '1' && @updates[$1].present?
        @updates.delete(k)
      end
    end

    @deletable = {}
    @updates.each_pair do |k, v|
      if k =~ /^bulk_delete_(.*)/
        @deletable[$1] = v.map(&:to_i)
        @updates.delete(k)
      end
    end
  end
end
