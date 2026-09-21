class SupportClassifier

    CATEGORIES = %w[
        billing
        technical
        account
        bug
        feature_request
        other
    ].freeze

    def initializer(client: OPENAI_CLIENT)
        @client = client
    end

    def call(ticket)
    end
end