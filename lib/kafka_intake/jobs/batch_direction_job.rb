module KafkaIntake
    class BatchDirectionJob < ActiveJob

        # reference: https://stackoverflow.com/questions/3457067/ruby-on-rails-get-the-controller-and-action-name-based-on-a-path
        # reference: https://stackoverflow.com/questions/5767222/rails-call-another-controller-action-from-a-controller#comment74479993_30143216

        def NoIdentifierError < 
        def perform(key, messages)

            topic = key[0]
            verb = key[1]
            action_hash = Rails.application.routes.recognize_path(messages.first.topic, { method: key[1] })
            action = action_hash[:action].to_sym
            controller_class = action_hash[:controller].constantize

            batch_info = []
            messages.each do |message|
                payload = JSON.parse(message.payload)
                id = payload['Id']
                body = payload['Body']
                headers = payload['Headers']

                query_params = Rack::Utils.parse_query URI(message.topic).query
                path_params = Rails.application.routes.recognize_path(message.topic)
                body_params = params.merge(body) if body.present?

                params = query_params.merge(body_params).merge(path_params) # path parameters take precedence
                batch_info.push(params.merge(kafka_intake_identifier: id))
            end

            if defined?(controller_class::KAFKA_INTAKE_BULK_CONTROLLER) && controller_class::KAFKA_INTAKE_BULK_CONTROLLER
                # this is a Bulk action designed to handle an array of parameters
                # The action must manage its own parallelization and atomicity as it is assumed this will use bulk DB queries
                # Its response should be an array of responses to the original requests
                # with each response tagged with a "kafka_identifier" parameter to be used for publishing
                # It must also manage status-codes for each

                responses = JSON.parse(run_action(controller_class, action, { parameters: batch_info }).body)
                responses.each do |response|
                    Ractor.new(response) do |response|
                        produce(response[:kafka_intake_identifier], response.except(:kafka_intake_identifier).to_json)
                    end
                end
            else
                # this is a normal action
                # reference: https://docs.ruby-lang.org/en/3.2/Ractor.html

                outputs = []
                
                batch_info.each do |message|
                    ractor_data = [controller_class, action, message] # collecting data for Ractor

                    outputs.push Ractor.new(ractor_data) do |ractor_data| # manage parallelization here
                        klass = ractor_data[0]
                        ractor_action = ractor_data[1]
                        input = ractor_data[2].except(:kafka_intake_identifier)
                        ActiveRecord::Base.transaction(requires_new: true) do
                            # creates savepoint to retain fine-grained atomic transactions
                            response = run_action(klass, ractor_action, input)
                            produce(
                                message[:kafka_intake_identifier], 
                                {status: response.status, body: response.body}.to_json
                            )
                        end
                        response
                    end
                end
                outputs.each(&:take) # ensure that the data is published before ending the Job
            end
        end

        def run_action(controller, path, dataset)
            controller = controller_class.new
            controller.params = ActionController::Parameters.new(dataset)
            controller.process(path.to_sym)
            controller.response
        end


        def produce(id, payload)
            KafkaIntake::PRODUCER.produce(
                topic: id,
                payload: payload
            )
        end
    end
end