require "json"

class SupportClassifier
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
        response = @client.chat.completions.create(
            model: "gpt-4o-mini",
            messages: [
                { role: "system", content: system_prompt },
                { role: "user", content: ticket }
            ],
            response_format: { type: "json_object" }
        )

        JSON.parse(response.choices.first.message.content)
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
end