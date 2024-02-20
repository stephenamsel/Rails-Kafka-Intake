# frozen_string_literal: true

require_relative "kafka_intake/version"
require_relative "kafka_intake/consumer"
require_relative "kafka_intake/jobs/batch_direction_job"

module KafkaIntake
  class Error < StandardError; end
  # Your code goes here...
end
