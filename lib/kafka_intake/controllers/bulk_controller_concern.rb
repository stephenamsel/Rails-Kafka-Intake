module KafkaIntake::BulkControllerConcern
    extend ActiveSupport::Concern

    included do
        KAFKA_INTAKE_BULK_CONTROLLER = true
    end

    # Add controller-side logic here to manage atomicity and parallelization
end