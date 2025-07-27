module Api
  module V1
    module ApiHelper
      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          next_page: collection.next_page,
          prev_page: collection.prev_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end

      def render_paginated_collection(collection, key)
        {
          json: {
            key => collection,
            meta: pagination_meta(collection)
          }
        }
      end

      def render_success(message, status = :ok)
        {
          json: { message: message },
          status: status
        }
      end

      def render_error(error, status = :unprocessable_entity)
        {
          json: { error: error },
          status: status
        }
      end
    end
  end
end 