module  KafkaIntake::SingleControllerConcern
    extend ActiveSupport::Concern
    
    included do
        after_action :add_identifier unless :bulk_controller

        def add_identifier
            body = ActionDispatch::Response.body
            body = JSON.parse(body) if body.is_a?(String)
            body = body.merge(kafka_intake_identifier: params[:kafka_intake_identifier])
            ActionDispatch::Response.body = body.to_json
        end
    end
end