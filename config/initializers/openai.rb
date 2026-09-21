require "openai"
require "dotenv/load"

OPENAI_CLIENT = OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"))