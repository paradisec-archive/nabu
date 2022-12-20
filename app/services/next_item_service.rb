class NextItemService
  def self.decode(data)
    compressed = Base64.decode64(data)
    text = ActiveSupport::Gzip.decompress(compressed)
    keys = text.split(',').map(&:to_i)

    keys
  end

  def self.find_next_item(current_item, session)
    return nil unless current_item.present?

    return current_item.prev_item unless session[:result_ids].present?

    keys = decode(session[:result_ids])
    if keys.any?
      id = keys.find{|id| id > current_item.id}
      return nil unless id.present?

      Item.find(id)
    end
  end

  def self.find_prev_item(current_item, session)
    return nil unless current_item.present?

    return current_item.prev_item unless session[:result_ids].present?

    keys = decode(session[:result_ids])
    if keys.any?
      id = keys.find{|id| id < current_item.id}
      return nil unless id.present?

      Item.find(id)
    end
  end
end
