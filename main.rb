require "dotenv/load"
require_relative "config/initializers/openai"
require_relative "app/services/support_classifier"

text = <<~TEXT
    How do I tip the cashier, they were polite and versy supportive.
TEXT

classifier = SupportClassifier.new

puts classifier.call(text)