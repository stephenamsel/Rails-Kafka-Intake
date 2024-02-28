module KafkaIntake
    class NoIdentifierError < StandardError; end
    class BatchDirectionJob < ActiveJob

        # reference: https://stackoverflow.com/questions/3457067/ruby-on-rails-get-the-controller-and-action-name-based-on-a-path
        # reference: https://stackoverflow.com/questions/5767222/rails-call-another-controller-action-from-a-controller#comment74479993_30143216

        
        def perform(key, messages)

            topic = key[0]
            verb = key[1]
            action_hash = Rails.application.routes.recognize_path(messages.first.topic, { method: key[1] })
            action = action_hash[:action].to_sym
            controller_class = action_hash[:controller].constantize

            if is_bulk_controller?(controller_class)
                # This gives the option towrite a Controller action that would handle all messages in bulk
                # This may allow more efficient contact with the database

                # The action must manage its own parallelization and atomicity
                # as it is assumed this will use bulk DB queries
                # Its response should be an array of responses to the original requests
                # with each response tagged with a "kafka_identifier" parameter to be used for publishing
                # It must also manage status-codes for each as required for the Kafka responses
                controller = controller_class.new
                controller.params = JSON.parse(messages)
                controller.process(topic.to_sym)

                responses = JSON.parse(controller.response.body)
                responses.each do |response|
                    Ractor.new(response) do |response|
                        produce(response[:kafka_intake_identifier], response.except(:kafka_intake_identifier).to_json)
                    end
                end
                responses.each(&:take) # ensure that the Ractors are completed before the Job is ended
            else
                # This is for processing Kafka messages as though they were each separate HTTP requests
                # reference: https://docs.ruby-lang.org/en/3.2/Ractor.html
                outputs = []
                messages.each_with_index do |message, index|
                    outputs[index] = Ractor.new(controller_class, message) do
                        Rails.application.executor.wrap do # unsure if this is necessary
                            begin
                                ActiveRecord::Base.transaction(requires_new: true) do
                                    controller = build_controller(message, controller_class) # may raise NoIdentifierError
                                    controller.process_action
                                    response = controller.response
                                end
                            rescue NoIdentifierError => e
                                    Rails.logger.log.error({ e.class => e.message }.to_json)
                            end
                            produce(
                                        controller.params[:kafka_intake_identifier],
                                        { status: response.status, body: response.body }.to_json
                                    )
                        end
                    end
                end
                messages.length.times do |i|
                    outputs[i].take # ensure the Ractors are competed before the Job ends
                end
            end
        end

        def produce(id, payload)
            KafkaIntake::PRODUCER.produce(
                topic: id,
                payload: payload
            )
        end

        def is_bulk_controller?(controller_class)
            is_defined?(controller_class::KAFKA_INTAKE_BULK_CONTROLLER) && 
            controller_class::KAFKA_INTAKE_BULK_CONTROLLER
        end

        def build_controller(message, controller_class)
            payload = JSON.parse(message.payload)
            id = payload['Id']
            raise NoIdentifierError("ID missing: #{message.payload}") if id.nil?
            
            body = payload['Body']
            headers = payload['Headers']

            query_params = Rack::Utils.parse_query URI(message.topic).query
            path_params = Rails.application.routes.recognize_path(message.topic)
            body_params = JSON.parse(body) if body.present?

            controller = controller_class.new
            req = ActionDispatch::Request.new(controller.middleware.middlewares.empty? ? {} : controller.middleware)
            req.full_url = message.topic
            req.set_header("rack.input", body)
            headers.each { |k, v| req.headers.merge(k => v) }
            req.request_method = verb
            controller.request = req
            controller.params = params.merge(kafka_intake_identifier: id)

            controller
        end
    end
end
