# frozen_string_literal: true

module Chat
  # QueryService handles all read-only queries for the chat
  class QueryService
    def initialize(shop)
      @shop = shop
    end

    # Get all services from today
    def services_today
      @shop.service_records
           .where("service_date >= ?", Time.current.beginning_of_day)
           .includes(:client, :vehicle)
           .order(service_date: :desc)
    end

    # Get services on a specific date
    def services_on_date(date)
      start_of_day = date.beginning_of_day
      end_of_day = date.end_of_day

      @shop.service_records
           .where(service_date: start_of_day..end_of_day)
           .includes(:client, :vehicle)
           .order(service_date: :desc)
    end

    # Get services in a date range
    def services_in_date_range(start_date, end_date)
      start_time = start_date.beginning_of_day
      end_time = end_date.end_of_day

      @shop.service_records
           .where(service_date: start_time..end_time)
           .includes(:client, :vehicle)
           .order(service_date: :desc)
    end

    # Search services by plate
    def search_by_plate(plate)
      normalized_plate = plate.upcase.gsub(/[-\s]/, "")
      vehicle = Vehicle.find_by(plate: normalized_plate)

      return [] unless vehicle

      vehicle.service_records
             .includes(:client)
             .order(service_date: :desc)
             .limit(10)
    end

    # Search services by client name
    def search_by_client(name)
      clients = @shop.clients.where("LOWER(name) LIKE ?", "%#{name.downcase}%")

      return [] if clients.empty?

      @shop.service_records
           .where(client: clients)
           .includes(:client, :vehicle)
           .order(service_date: :desc)
           .limit(10)
    end

    # Get statistics for today
    def statistics_today
      services = services_today

      {
        count: services.count,
        total_revenue: services.sum(:price),
        highest_price: services.maximum(:price) || 0,
        most_popular_service: most_popular_service_today,
        clients_served: services.select(:client_id).distinct.count
      }
    end

    private

    def most_popular_service_today
      services_today
        .select(:service_name)
        .group(:service_name)
        .reorder(Arel.sql("COUNT(*) DESC"))
        .limit(1)
        .pick(:service_name)
    end
  end
end
