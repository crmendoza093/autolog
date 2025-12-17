
class ChatController < ApplicationController
  def index
    @conversation = current_shop.active_conversation
    @recent_services = current_shop.service_records.recent.limit(5)
    @services = current_shop.services.active.popular.limit(5).order(usage_count: :desc)

    # Load today's messages
    @messages = @conversation.messages_today
  end

  def message
    @conversation = current_shop.active_conversation
    message_text = params[:message].to_s.strip

    return head :unprocessable_entity if message_text.blank?

    # Save user message
    @conversation.add_message(
      role: "user",
      content: message_text
    )

    # Process message through the service layer
    result = Chat::MessageProcessor.new(
      shop: current_shop,
      conversation: @conversation,
      message: message_text
    ).process

    # Save assistant response
    @conversation.add_message(
      role: "assistant",
      content: result.response,
      action: result.action
    )

    render json: {
      user_message: message_text,
      assistant_message: result.response,
      action: result.action
    }
  end

  def search_clients
    query = params[:q].to_s.strip

    return render json: { clients: [] } if query.blank? || query.length < 2

    # Search clients by name using ILIKE for case-insensitive partial matching
    clients = current_shop.clients
                         .where("LOWER(name) LIKE ?", "%#{query.downcase}%")
                         .order(:name)
                         .limit(10)
                         .pluck(:id, :name)
                         .map { |id, name| { id: id, name: name } }

    render json: { clients: clients }
  end

  def search_services
    query = params[:q].to_s.strip

    return render json: { services: [] } if query.blank? || query.length < 2

    # Get services from catalog (not from service_records)
    services = current_shop.services
                          .where("LOWER(name) LIKE ?", "%#{query.downcase}%")
                          .order(:name)
                          .limit(10)
                          .pluck(:name)
                          .map { |name| { name: name } }

    render json: { services: services }
  end

  def quick_register_service
    service = current_shop.services.find_by(id: params[:service_id])

    return render json: { error: "Servicio no encontrado" }, status: :not_found unless service

    # Create service record without client/vehicle
    service_record = current_shop.service_records.create!(
      service_name: service.name,
      price: service.price,
      service_date: Time.current
    )

    # Increment usage count
    service.increment_usage!

    message_text = "✅ #{service.name} registrado exitosamente por $#{service.price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"

    # Save assistant message
    current_shop.active_conversation.add_message(
      role: "assistant",
      content: message_text,
      action: "quick_registered"
    )

    render json: {
      success: true,
      message: message_text,
      service_record: {
        id: service_record.id,
        service_name: service_record.service_name,
        price: service_record.price,
        service_date: service_record.service_date.strftime("%H:%M")
      }
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
