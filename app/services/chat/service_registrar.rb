# frozen_string_literal: true

module Chat
  # ServiceRegistrar creates the service record and associated entities
  class ServiceRegistrar
    Result = Struct.new(:success?, :service, :errors, keyword_init: true)

    def initialize(shop:, data:)
      @shop = shop
      @data = data
    end

    def register
      ActiveRecord::Base.transaction do
        # Validate service exists in catalog
        unless service_exists_in_catalog?
          return Result.new(
            success?: false,
            service: nil,
            errors: [ "El servicio '#{@data[:service_name]}' no existe en el catálogo. Por favor, créalo primero en /services" ]
          )
        end

        client = find_or_create_client
        vehicle = find_or_create_vehicle(client) if @data[:plate].present?

        service = @shop.service_records.create!(
          client: client,
          vehicle: vehicle,
          service_name: @data[:service_name],
          price: @data[:price],
          notes: @data[:notes],
          service_date: Time.current
        )

        # Update suggestion usage if applicable
        update_service_usage

        Result.new(success?: true, service: service, errors: [])
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, service: nil, errors: [ e.message ])
    rescue StandardError => e
      Rails.logger.error("[ServiceRegistrar] Error: #{e.message}")
      Result.new(success?: false, service: nil, errors: [ "Error interno" ])
    end

    private

    def find_or_create_client
      name = @data[:client_name].presence || "Cliente anónimo"

      # Exact match (case-insensitive)
      existing = @shop.clients.find_by("LOWER(name) = ?", name.downcase)
      return existing if existing

      # No match found, create new client
      @shop.clients.create!(name: name)
    end

    def find_or_create_vehicle(client)
      return nil unless @data[:plate].present?

      plate = @data[:plate].upcase

      # First, try to find the vehicle globally by plate
      vehicle = Vehicle.find_by(plate: plate)

      if vehicle
        # Vehicle exists, update the client association if different
        vehicle.update(client: client) if vehicle.client_id != client.id
        vehicle
      else
        # Create new vehicle for this client
        client.vehicles.create!(
          plate: plate,
          brand: @data[:brand],
          color: @data[:color]
        )
      end
    end

    def service_exists_in_catalog?
      @shop.services.exists?([ "LOWER(name) = ?", @data[:service_name].downcase ])
    end

    def update_service_usage
      service = @shop.services.find_by(
        "LOWER(name) = ?",
        @data[:service_name].downcase
      )
      service&.increment_usage!
    end
  end
end
