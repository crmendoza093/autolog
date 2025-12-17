# frozen_string_literal: true

module Chat
  # MessageProcessor is the main orchestrator for processing chat messages
  # It coordinates between parsing, conversation state, and service registration
  class MessageProcessor
    Result = Struct.new(:success?, :response, :action, :data, keyword_init: true)

    INTENTS = %w[register_service confirm cancel ask_question greeting unknown].freeze

    # Regex patterns
    DATE_RANGE_PATTERN = /(?:desde|entre)\s+(.+?)\s+(?:hasta|y)\s+(.+)/i


    def initialize(shop:, conversation:, message:)
      @shop = shop
      @conversation = conversation
      @message = message.to_s.strip
    end

    def process
      return greeting_response if greeting?
      return help_response if help?
      return cancel_response if cancel?
      return confirm_response if confirming?

      # Check for query intents
      return query_today_response if query_today?
      return query_date_range_response if query_date_range?
      return query_date_response if query_date?
      return search_plate_response if search_plate?
      return search_client_response if search_client?
      return statistics_response if statistics?

      # Parse the message to extract service data
      parsed = parse_message

      if parsed[:complete]
        # We have all the data we need, request confirmation
        request_confirmation(parsed)
      else
        # Ask for missing information
        ask_for_missing(parsed)
      end
    rescue StandardError => e
      Rails.logger.error("[MessageProcessor] Error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      error_response(e)
    end

    private

    def greeting?
      greetings = %w[hola hello hi buenos buenas hey]
      greetings.any? { |g| @message.downcase.start_with?(g) }
    end

    def help?
      help_keywords = [ "ayuda", "help", "comandos", "qué puedes hacer", "que puedes hacer" ]
      help_keywords.any? { |k| @message.downcase.include?(k) }
    end

    def cancel?
      cancels = %w[cancelar cancel no nope salir exit]
      cancels.any? { |c| @message.downcase == c }
    end

    def confirming?
      confirms = %w[sí si yes ok confirmar confirmo correcto listo dale]
      @conversation.state == "awaiting_confirmation" &&
        confirms.any? { |c| @message.downcase.include?(c) }
    end

    def query_today?
      patterns = [ "servicios de hoy", "servicios hoy", "cuántos servicios", "cuantos servicios", "resumen del día", "resumen" ]
      patterns.any? { |p| @message.downcase.include?(p) }
    end

    def query_date?
      patterns = [ "ventas de", "ventas del", "servicios de", "servicios del", "lo de", "ayer", "antier" ]
      # Must detect a date pattern or specific keywords
      has_keyword = patterns.any? { |p| @message.downcase.include?(p) }
      has_date_format = @message.match?(/(\d{1,2})[\/\-\.](\d{1,2})/)

      (has_keyword && (has_date_format || @message.downcase.include?("ayer") || @message.downcase.include?("antier"))) ||
      (has_date_format && @message.length < 20) # Just a date string
    end

    def query_date_range?
      @message.match?(DATE_RANGE_PATTERN)
    end

    def search_plate?
      @message.match?(/buscar\s+[A-Z]{3}[-\s]?\d{3}/i) ||
        @message.match?(/historial\s+[A-Z]{3}[-\s]?\d{3}/i) ||
        @message.match?(/cuándo vino\s+[A-Z]{3}[-\s]?\d{3}/i) ||
        @message.match?(/cuando vino\s+[A-Z]{3}[-\s]?\d{3}/i)
    end

    def search_client?
      (@message.downcase.include?("servicios de") ||
       @message.downcase.include?("historial de")) &&
       !@message.match?(/[A-Z]{3}[-\s]?\d{3}/i) # No es una placa
    end

    def statistics?
      stats_keywords = [ "total vendido", "cuánto llevo", "cuanto llevo", "estadísticas", "estadisticas", "servicio más popular", "servicio mas popular" ]
      stats_keywords.any? { |k| @message.downcase.include?(k) }
    end

    def parse_message
      # Use simple regex parsing for MVP
      # Later this can be replaced with LLM-based parsing
      Parser.new(@message, @shop).parse
    end

    def greeting_response
      @conversation.reset!

      Result.new(
        success?: true,
        response: "¡Hola! 👋 Estoy listo para registrar tus servicios.\n\nEscribe algo como:\n*\"Lavado completo $35.000 ABC123 Juan\"*",
        action: :greeting,
        data: {}
      )
    end

    def cancel_response
      @conversation.reset!

      Result.new(
        success?: true,
        response: "❌ Operación cancelada. ¿En qué más te puedo ayudar?",
        action: :cancel,
        data: {}
      )
    end

    def confirm_response
      data = @conversation.pending_data
      register_service(data)
    end

    def register_service(parsed)
      result = ServiceRegistrar.new(shop: @shop, data: parsed).register

      @conversation.reset! # Reset conversation regardless of success/failure for confirmation

      Result.new(
        success?: result.success?,
        response: build_success_response(result),
        action: result.success? ? :registered : :error,
        data: result.success? ? { service_id: result.service.id } : {}
      )
    end

    def build_success_response(result)
      # Check if there were validation errors
      if result.errors.any?
        return build_error_card(result.errors.first)
      end

      service = result.service

      card = <<~HTML
        <div class="success-card">
          <div class="success-header">
            <span class="success-icon">✅</span>
            <h3>¡Servicio registrado!</h3>
          </div>
          <div class="success-details">
            <div class="detail-row">
              <span class="detail-label">Servicio:</span>
              <span class="detail-value">#{service.service_name}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Cliente:</span>
              <span class="detail-value">#{service.client.name}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Precio:</span>
              <span class="detail-value">$#{number_with_delimiter(service.price.to_i)}</span>
            </div>
            #{service.vehicle ? "<div class=\"detail-row\"><span class=\"detail-label\">Placa:</span><span class=\"detail-value\">#{service.vehicle.plate}</span></div>" : ""}
          </div>
        </div>
      HTML

      card.html_safe
    end

    def build_error_card(error_message)
      card = <<~HTML
        <div class="error-card">
          <div class="error-header">
            <span class="error-icon">❌</span>
            <h3>Error al registrar servicio</h3>
          </div>
          <div class="error-message">
            #{error_message}
          </div>
          <div class="error-hint">
            💡 Puedes crear nuevos servicios en <a href="/services">Gestión de Servicios</a>
          </div>
        </div>
      HTML

      card.html_safe
    end

    def request_confirmation(parsed)
      @conversation.update_state!("awaiting_confirmation", parsed)

      price_display = parsed[:price] ? "$#{number_with_delimiter(parsed[:price].to_i)}" : "precio?"

      Result.new(
        success?: true,
        response: build_confirmation_card(parsed, price_display),
        action: :confirmation,
        data: parsed
      )
    end

    def build_confirmation_card(parsed, price_display)
      <<~HTML
        <div class="confirmation-card">
          <div class="confirmation-header">
            <div class="confirmation-icon">📝</div>
            <div class="confirmation-title">Confirmar servicio</div>
          </div>
          <div class="confirmation-body">
            <div class="confirmation-item">
              <span class="item-label">Servicio</span>
              <span class="item-value">#{parsed[:service_name] || 'No especificado'}</span>
            </div>
            <div class="confirmation-item">
              <span class="item-label">Precio</span>
              <span class="item-value price">#{price_display}</span>
            </div>
            <div class="confirmation-item">
              <span class="item-label">Cliente</span>
              <span class="item-value">#{parsed[:client_name] || 'No especificado'}</span>
            </div>
            <div class="confirmation-item">
              <span class="item-label">Placa</span>
              <span class="item-value">#{parsed[:plate] || 'No especificada'}</span>
            </div>
          </div>
          <div class="confirmation-footer">
            ¿Es correcto? Responde *sí* o *no*
          </div>
        </div>
      HTML
    end

    def ask_for_missing(parsed)
      missing = []
      missing << "tipo de servicio" unless parsed[:service_name]
      missing << "precio" unless parsed[:price]

      @conversation.update_state!("awaiting_correction", parsed)

      Result.new(
        success?: true,
        response: "🤔 Me falta información:\n\n" \
                  "• #{missing.join("\n• ")}\n\n" \
                  "Por favor completa los datos.",
        action: :incomplete,
        data: parsed
      )
    end

    def error_response(error)
      Result.new(
        success?: false,
        response: "❌ Ocurrió un error. Por favor intenta de nuevo.",
        action: :error,
        data: { error: error.message }
      )
    end

    def number_with_delimiter(number)
      number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
    end

    # Query response methods
    def help_response
      Result.new(
        success?: true,
        response: build_help_card,
        action: :help,
        data: {}
      )
    end

    def query_today_response
      query_service = QueryService.new(@shop)
      services = query_service.services_today

      Result.new(
        success?: true,
        response: build_services_list_card(services, "Servicios de hoy"),
        action: :query,
        data: { count: services.count }
      )
    end

    def query_date_response
      date = parse_date(@message)

      unless date
        return Result.new(
          success?: false,
          response: "No pude entender la fecha. Intenta con formatos como 'ayer', '15/12' o '15 de diciembre'.",
          action: :error,
          data: {}
        )
      end

      query_service = QueryService.new(@shop)
      services = query_service.services_on_date(date)

      title = if date == Date.yesterday
                "Servicios de ayer"
      elsif date == Date.today
                "Servicios de hoy"
      else
                "Servicios del #{date.strftime('%d/%m/%Y')}"
      end

      Result.new(
        success?: true,
        response: build_services_list_card(services, title),
        action: :query,
        data: { count: services.count, date: date }
      )
    end

    def query_date_range_response
      match = @message.match(DATE_RANGE_PATTERN)
      start_text, end_text = match.captures

      start_date = parse_date(start_text)
      end_date = parse_date(end_text)

      if start_date && end_date
        query_service = QueryService.new(@shop)
        services = query_service.services_in_date_range(start_date, end_date)

        title = "Servicios del #{start_date.strftime('%d/%m')} al #{end_date.strftime('%d/%m')}"

        Result.new(
          success?: true,
          response: build_services_list_card(services, title),
          action: :query,
          data: { count: services.count, start_date: start_date, end_date: end_date }
        )
      else
        Result.new(
          success?: false,
          response: "No pude entender las fechas del rango. Intenta 'desde 15/12 hasta 16/12'.",
          action: :error,
          data: {}
        )
      end
    end

    def search_plate_response
      # Extract plate from message
      plate_match = @message.match(/[A-Z]{3}[-\s]?\d{3}/i)
      return error_response(StandardError.new("No se encontró placa")) unless plate_match

      plate = plate_match[0]
      query_service = QueryService.new(@shop)
      services = query_service.search_by_plate(plate)

      Result.new(
        success?: true,
        response: build_services_list_card(services, "Historial de #{plate.upcase}"),
        action: :query,
        data: { plate: plate, count: services.count }
      )
    end

    def search_client_response
      # Extract client name from message
      name = @message.gsub(/servicios de|historial de/i, "").strip
      return error_response(StandardError.new("No se especificó cliente")) if name.blank?

      query_service = QueryService.new(@shop)
      services = query_service.search_by_client(name)

      Result.new(
        success?: true,
        response: build_services_list_card(services, "Servicios de #{name.capitalize}"),
        action: :query,
        data: { client: name, count: services.count }
      )
    end

    def statistics_response
      query_service = QueryService.new(@shop)
      stats = query_service.statistics_today

      Result.new(
        success?: true,
        response: build_statistics_card(stats),
        action: :statistics,
        data: stats
      )
    end

    # Card builders for queries
    def build_help_card
      <<~HTML
        <div class="help-card">
          <div class="help-header">
            <div class="help-icon">💡</div>
            <div class="help-title">Comandos disponibles</div>
          </div>
          <div class="help-body">
            <div class="help-section">
              <div class="help-section-title">📝 Registrar servicios</div>
              <div class="help-example">Ej: Lavado motor $50000 ABC123 Juan</div>
            </div>
            <div class="help-section">
              <div class="help-section-title">📊 Consultas</div>
              <div class="help-example">• "Servicios de hoy"</div>
              <div class="help-example">• "Ventas de ayer"</div>
              <div class="help-example">• "Desde 10/12 hasta 15/12"</div>
              <div class="help-example">• "Servicios del (dd/mm)"</div>
              <div class="help-example">• "Buscar ABC123"</div>
              <div class="help-example">• "Servicios de Juan"</div>
              <div class="help-example">• "Total vendido hoy"</div>
            </div>
          </div>
        </div>
      HTML
    end

    def build_services_list_card(services, title)
      if services.empty?
        return <<~HTML
          <div class="info-card">
            <div class="info-header">
              <div class="info-icon">📋</div>
              <div class="info-title">#{title}</div>
            </div>
            <div class="info-body">
              <p style="color: #94A3B8; text-align: center; padding: 20px;">No se encontraron servicios</p>
            </div>
          </div>
        HTML
      end

      services_html = services.map do |service|
        price = "$#{number_with_delimiter(service.price.to_i)}"
        client = service.client&.name || "Cliente"
        plate = service.vehicle&.plate || "-"
        time = service.service_date.strftime("%H:%M")

        <<~HTML
          <div class="service-list-item">
            <div class="service-list-main">
              <span class="service-list-name">#{service.service_name}</span>
              <span class="service-list-price">#{price}</span>
            </div>
            <div class="service-list-meta">
              <span>👤 #{client}</span>
              <span>🚗 #{plate}</span>
              <span>🕐 #{time}</span>
            </div>
          </div>
        HTML
      end.join

      <<~HTML
        <div class="info-card">
          <div class="info-header">
            <div class="info-icon">📋</div>
            <div class="info-title">#{title}</div>
            <div class="info-badge">#{services.count}</div>
          </div>
          <div class="info-body">
            #{services_html}
          </div>
        </div>
      HTML
    end

    def build_statistics_card(stats)
      total = "$#{number_with_delimiter(stats[:total_revenue].to_i)}"
      highest = "$#{number_with_delimiter(stats[:highest_price].to_i)}"
      popular = stats[:most_popular_service] || "N/A"

      <<~HTML
        <div class="stats-card">
          <div class="stats-header">
            <div class="stats-icon">📊</div>
            <div class="stats-title">Estadísticas de hoy</div>
          </div>
          <div class="stats-body">
            <div class="stat-item">
              <div class="stat-value">#{stats[:count]}</div>
              <div class="stat-label">Servicios</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">#{total}</div>
              <div class="stat-label">Total vendido</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">#{highest}</div>
              <div class="stat-label">Servicio más caro</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">#{stats[:clients_served]}</div>
              <div class="stat-label">Clientes</div>
            </div>
          </div>
          <div class="stats-footer">
            <strong>Servicio más popular:</strong> #{popular}
          </div>
        </div>
      HTML
    end

    def parse_date(text)
      text = text.downcase
      return Date.yesterday if text.include?("ayer")
      return Date.yesterday - 1.day if text.include?("antier") || text.include?("antes de ayer")
      return Date.today if text.include?("hoy")

      # Extract date-like pattern DD/MM or DD-MM or DD.MM
      # Optional Year
      date_match = text.match(/(\d{1,2})[\/\-\.](\d{1,2})(?:[\/\-\.](\d{2,4}))?/)

      if date_match
        day, month, year = date_match.captures

        # Default to current year if not provided
        year = year ? (year.length == 2 ? "20#{year}" : year) : Time.current.year

        begin
          Date.new(year.to_i, month.to_i, day.to_i)
        rescue ArgumentError
          nil
        end
      else
        nil
      end
    end
  end
end
