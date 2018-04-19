class ItemSearchService
  def self.build_advanced_search(params, current_user)
    Item.solr_search(include: [:collection, :collector, :countries]) do
      # Full text search
      Sunspot::Setup.for(Item).all_text_fields.each do |field|
        next if params[field.name].blank?
        keywords params[field.name], :fields => [field.name]
      end

      # Exact search
      Sunspot::Setup.for(Item).fields.each do |field|
        next if params[field.name].blank?
        case field.type
          when Sunspot::Type::StringType
          when Sunspot::Type::IntegerType
            with field.name, params[field.name]
          when Sunspot::Type::BooleanType
            with field.name, params[field.name] =~ /^true|1$/ ? true : false
          when Sunspot::Type::TimeType
            with(field.name).between((Time.parse(params[field.name]).beginning_of_day)..(Time.parse(params[field.name]).end_of_day))
          else
            p "WARNING can't search: #{field.type} #{field.name}"
        end
      end

      # GEO Is special
      if params[:north_limit]
        all_of do
          with(:north_limit).less_than    params[:north_limit]
          with(:north_limit).greater_than params[:south_limit]

          with(:south_limit).less_than    params[:north_limit]
          with(:south_limit).greater_than params[:south_limit]

          if params[:west_limit] <= params[:east_limit]
            with(:west_limit).greater_than params[:west_limit]
            with(:west_limit).less_than    params[:east_limit]

            with(:east_limit).greater_than params[:west_limit]
            with(:east_limit).less_than    params[:east_limit]
          else
            any_of do
              all_of do
                with(:west_limit).greater_than params[:west_limit]
                with(:west_limit).less_than    180
              end
              all_of do
                with(:west_limit).less_than    params[:east_limit]
                with(:west_limit).greater_than(-180)
              end
            end
            any_of do
              all_of do
                with(:east_limit).greater_than params[:west_limit]
                with(:east_limit).less_than    180
              end
              all_of do
                with(:east_limit).less_than    params[:east_limit]
                with(:east_limit).greater_than(-180)
              end
            end
          end
        end
      end
      
      if params[:no_files]
        with(:essences_count).greater_than(0)
      end

      if params[:exclusions].present?
        exclusions = params[:exclusions].split(',')
        without(:id, exclusions)
      end

      unless current_user && current_user.admin?
        any_of do
          with(:private, false)
          with(:admin_ids, current_user.id) if current_user
          with(:user_ids, current_user.id) if current_user
        end
      end
      sort_column(Item, params).each do |c|
        order_by c, sort_direction(params)
      end

      paginate :page => params[:page], :per_page => params[:per_page]
    end
  end

  def self.sort_column(model, params)
    model.sortable_columns.include?(params[:sort]) ? [params[:sort]] : model.sortable_columns[0, 2]
  end

  def self.sort_direction(params)
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : "asc"
  end
end