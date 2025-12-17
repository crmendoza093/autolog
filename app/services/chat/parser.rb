# frozen_string_literal: true

module Chat
  # Parser extracts service data from natural language messages
  # Uses regex patterns for MVP, can be enhanced with LLM later
  class Parser
    PRICE_PATTERNS = [
      /\$\s*([\d.,]+)/,                      # $35.000 or $35,000 (REQUIRE $ symbol)
      /\$\s*([\d.,]+)\s*(?:mil|k)/i         # $35mil or $35k
    ].freeze

    PLATE_PATTERN = /\b([A-Z]{3}[-\s]?\d{3})\b/i

    def initialize(message, shop)
      @message = message.downcase
      @original = message
      @shop = shop
    end

    def parse
      # Check if message uses structured format (Cliente: X | Servicio: Y | ...)
      if structured_format?
        parse_structured
      else
        parse_natural
      end
    end

    private

    def structured_format?
      @message.include?("|") && (@message.include?("cliente:") || @message.include?("servicio:"))
    end

    def parse_structured
      parts = @original.split("|").map(&:strip)
      result = {
        service_name: nil,
        price: nil,
        plate: nil,
        client_name: nil,
        notes: nil,
        complete: false
      }

      parts.each do |part|
        case part.downcase
        when /cliente:\s*(.+)/i
          result[:client_name] = $1.strip.split.map(&:capitalize).join(" ")
        when /servicio:\s*(.+)/i
          result[:service_name] = $1.strip
        when /precio:\s*(.+)/i
          price_str = $1.strip.gsub(/[$.,'']/, "")
          result[:price] = price_str.to_i
        when /placa:\s*(.+)/i
          result[:plate] = $1.strip.upcase.gsub(/[-\s]/, "")
        end
      end

      result[:complete] = result[:service_name].present? && result[:price].present?
      result
    end

    def parse_natural
      {
        service_name: extract_service_name,
        price: extract_price,
        plate: extract_plate,
        client_name: extract_client_name,
        notes: extract_notes,
        complete: complete?
      }
    end

    def extract_service_name
      # First check for exact matches from services catalog
      service = @shop.services.active.find do |s|
        @message.include?(s.name.downcase)
      end
      return service.name if service

      # Fallback: try to extract first capitalized words
      match = @original.match(/^([A-ZÁÉÍÓÚa-záéíóú]+(?:\s+[a-záéíóú]+)?)/i)
      match[1].capitalize if match && !match[1].match?(/^\d/)
    end

    def extract_price
      PRICE_PATTERNS.each do |pattern|
        match = @original.match(pattern)
        next unless match

        price_str = match[1].gsub(/[.,]/, "")
        price = price_str.to_i

        # Handle "35k" or "35mil" notation
        if @original.match?(/#{match[1]}\s*(?:mil|k)/i) && price < 1000
          price *= 1000
        end

        return price if price > 0
      end
      nil
    end

    def extract_plate
      match = @original.match(PLATE_PATTERN)
      match[1].upcase.gsub(/[-\s]/, "") if match
    end

    def extract_client_name
      # Names now come at the END of the message
      # Pattern: Service Price Plate Client

      remaining = @original.dup

      # Remove known parts from the beginning/middle
      remaining.gsub!(PLATE_PATTERN, "")
      remaining.gsub!(/\$?\s*[\d.,]+(?:\s*(?:mil|k))?/i, "")

      # Remove known service names
      @shop.services.active.pluck(:name).each do |name|
        remaining.gsub!(/#{name}/i, "")
      end

      # Extract words that could be names
      stopwords = %w[de la el los las un una del al para con por valor vino trajo llego pidio]
      names = remaining.scan(/\b[a-záéíóúñ]{2,}\b/i)
      names.reject! { |n| stopwords.include?(n.downcase) }
      names.reject! { |n| n.length < 3 }

      # Take LAST words as name (since they're at the end now)
      if names.any?
        names.last(2).map(&:capitalize).join(" ")
      end
    end

    def extract_notes
      # Any remaining text could be notes
      nil
    end

    def complete?
      extract_service_name.present? && extract_price.present?
    end
  end
end
