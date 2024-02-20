include "json"

module KafkaIntake

    
    config = {
        :"bootstrap.servers" => ENV["KAFKA_HOSTS_PORTS"],
        :"group.id" => ENV["KAFKA_GROUP"]
    }
    CONSUMER = Rdkafka::Config.new(config).consumer
    PRODUCER = Rdkafka::Config
        .new({:"bootstrap.servers" => ENV["KAFKA_HOSTS_PORTS"]}).producer

    def setup_consume(paths)
        # paths may include wildcards for path-parameters
        paths.each do |path|
            CONSUMER.subscribe(path)
        end
    end

    def process_consume
        # reference: https://www.rubydoc.info/github/appsignal/rdkafka-ruby/Rdkafka/Consumer
        # reference: https://github.com/karafka/rdkafka-ruby/tree/main

        CONSUMER.each_batch(
            max_items: ENV['POLLING_MAX'] || 2000,
            timeout_ms: ENV['MAX_POLLING_TIME'] || 200
        ) do |messages|
            grouped = messages.group_by{ |m| [m.topic, JSON.parse(message.payload)['Method']] }
            # run through ActiveJob for parallelization, Transaction and ActiveSupport::Current support
            grouped.each do |topic, messages|
                BatchDirectionJob.perform_later(key, messages)
            end
        end


            produce(id, response)
    end


    module_function :setup_consume

end