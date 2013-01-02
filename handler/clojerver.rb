require "clojerver"

module Rack
  module Handler
    class Clojerver
      def self.run(app, options={})
        server = ::Clojerver::Server.new(app)
        yield server if block_given?
        server.run
      end

    end
  end
end
