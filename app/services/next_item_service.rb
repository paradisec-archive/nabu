class NextItemService
  def self.find_next_item(current_item, session)
    return nil unless current_item.present?

    if session[:result_ids].present? && session[:result_ids].any?
      id = session[:result_ids].find{|id| id > current_item.full_identifier}
      item_for_id(id)
    else
      current_item.next_item
    end
  end
  def self.find_prev_item(current_item, session)
    return nil unless current_item.present?

    if session[:result_ids].present? && session[:result_ids].any?
      id = session[:result_ids].reverse.find{|id| id < current_item.full_identifier}
      item_for_id(id)
    else
      current_item.prev_item
    end
  end

  def self.item_for_id(id)
    return nil if id.nil?

    collection,identifier = id.split('-')
    Collection.find_by_identifier(collection).items.find_by_identifier(identifier)
  end
end