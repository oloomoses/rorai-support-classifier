require "json"
require "logger"

class SupportClassificationError < StandardError; end
class SupportTransientError < SupportClassificationError; end
class SupportPermanentError < SupportClassificationError; end

class SupportClassifier
    LOGGER = Logger.new($stdout)
    LOGGER.level = Logger::INFO

    CATEGORIES = %w[
        billing
        technical
        account
        bug
        feature_request
        other
    ].freeze

    PRIORITIES = %w[
        low
        medium
        high
    ].freeze

    def initialize(client: OPENAI_CLIENT)
        @client = client
    end

    def call(ticket)
        raise ArgumentError, "ticket must not be an empty string" unless
            ticket.is_a?(String) && !ticket.strip.empty?

        begin
            response = @client.chat.completions.create(
                model: "gpt-4o-mini",
                messages: [
                    { role: "system", content: system_prompt },
                    { role: "user", content: ticket }
                ],
                response_format: { type: "json_object" }
            )

        rescue OpenAI::Errors::RateLimitError,
            OpenAI::Errors::InternalServerError,
            OpenAI::Errors::APITimeoutError,
            OpenAI::Errors::APIConnectionError => e
            log_event(
                :warn,
                "openai_transient_failure",
                error: e.class.name
            )
            raise SupportTransientError, "Support Classifier temporarily unavailable"
        rescue OpenAI::Errors::AuthenticationError,
            OpenAI::Errors::PermissionDeniedError,
            OpenAI::Errors::BadRequestError,
            OpenAI::Errors::NotFoundError,
            OpenAI::Errors::UnprocessableEntityError => e
            log_event(
                :error,
                "openai_permanent_failure",
                error: e.class.name,
                status: e.respond_to?(:status) ? e.status : nil
            )
            raise SupportPermanentError, "Support processing rejected"
        end

        # JSON.parse(response.choices.first.message.content)
        parse_response(response)
    end

    private

    def system_prompt
        <<~PROMPT
            You classify customer support tickets.

            Classify each ticket into exactly one category:
            #{CATEGORIES.join(", ")}

            Assign exactly one priority
            #{PRIORITIES.join(", ")}

            return a json with these fields:
            - category
            - priority
            - reason

            The reason should be a short explanation of the classification.
        PROMPT
    end

    def parse_response(response)
        choice = response.choices&.first
        message = choice&.message

        raise SupportPermanentError, "No choices returned by OpenAI" unless message

        content = message.content
        raise SupportPermanentError, "OpenAI returned empty content" if content.nil? || content.strip.empty?

        result = JSON.parse(content)
        validate_result!(result)
        result
    rescue JSON::ParserError => e
        raise SupportPermanentError, "Invalid JSON object returned: #{e.class.name}"
    end

    def validate_result!(result)
        unless result.is_a?(Hash) &&
                CATEGORIES.include?(result["category"]) &&
                PRIORITIES.include?(result["priority"]) &&
                result["reason"].is_a?(String) && !result["reason"].strip.empty?
            raise SupportPermanentError, "OpenAI returned an invalid ticket result"
        end
    end

    def log_event(level, event, **fields)
        payload = {
            timestamp: Time.now.utc.iso8601,
            event: event,
            **fields
        }
        LOGGER.public_send(level, JSON.generate(payload))
    end
end