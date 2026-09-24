require "dotenv/load"
require_relative "config/initializers/openai"
require_relative "app/services/support_classifier"

text = <<~TEXT
    Gi manang'ieo ok a yudo, Okelna mopogore. Adwaro mondo udwokna pesana: Language is dholuo
TEXT

classifier = SupportClassifier.new

puts classifier.call(text)