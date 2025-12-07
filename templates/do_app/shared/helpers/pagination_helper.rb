module PaginationHelper
  DEFAULT_PER_PAGE = 10
  MAX_PER_PAGE = 100
  MIN_PER_PAGE = 1

  def self.extract_params(request, defaults: {})
    defaults = { page: 1, per_page: DEFAULT_PER_PAGE }.merge(defaults)
    query_string = request.env['QUERY_STRING'] || ''
    
    page = (query_string.match(/[?&]page=(\d+)/) ? $1.to_i : nil) || 
           request.params['page']&.to_i || defaults[:page]
    
    per_page = (query_string.match(/[?&]per_page=(\d+)/) ? $1.to_i : nil) || 
               request.params['per_page']&.to_i || defaults[:per_page]
    
    page = [page, 1].max
    per_page = [[per_page, MIN_PER_PAGE].max, MAX_PER_PAGE].min
    
    { page: page, per_page: per_page }
  end

  def self.paginate(collection, page:, per_page:)
    total_items = collection.size
    total_pages = [(total_items.to_f / per_page).ceil, 1].max
    page = [page, total_pages].min
    
    start_index = (page - 1) * per_page
    paginated_items = collection[start_index, per_page] || []
    
    {
      items: paginated_items,
      pagination: {
        current_page: page,
        per_page: per_page,
        total_items: total_items,
        total_pages: total_pages,
        has_previous: page > 1,
        has_next: page < total_pages,
        previous_page: page > 1 ? page - 1 : nil,
        next_page: page < total_pages ? page + 1 : nil
      }
    }
  end
end