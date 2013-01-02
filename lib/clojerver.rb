require 'rack'
require 'rubygems'
require 'java'
require 'jruby/synchronized'

#pull in the jars for clojure and the http server
require 'clojure-http/clojure-1.3.0.jar'
require 'clojure-http/clojure-http-1.0.0-SNAPSHOT.jar'

#pull in the gem to bridge ruby and clojure
require 'jrclj'

module Clojerver
    class Server
        attr_reader :app, :clj

        PORT = 3000

        HTTP_PREFIX = "HTTP_"

        def initialize(app)
            @app = app
            @clj = JRClj.new
            @clj._import "clojure-http.server"
            @clj._import "clojure-http.connect"
        end

        # trying to address a mysterious "mutex relocking on same thread" error
        def run
            dup._run
        end

        def _run
            server_socket = clj.create_socket(PORT)

            while false == clj.socket_closed?(server_socket)
                connection = clj.accept_connection(server_socket)

                reader = clj.create_reader(connection)
                client_header = clj.extract_input(reader)

                env = convert_input(client_header)
                env.extend(JRuby::Synchronized)

                status, headers, body = app.call(env)

                writer = clj.create_writer(connection)
                send_output(clj, writer, status, headers, body)
                clj.close_output(writer)
            end
        end

        #this creates an env hash that gets sent to Rack
        def convert_input(lines)
            return_value = {}

            it = lines.iterator()

            current = it.next()

            split_current = current.split
            return_value["REQUEST_METHOD"] = split_current[0]
            
            split_uri = split_current.second.split("?")

            return_value["SCRIPT_NAME"]  = ""
            return_value["PATH_INFO"]    = split_uri[0] 
            return_value["QUERY_STRING"] = ""
            return_value["QUERY_STRING"] += split_uri[1] if split_uri[1]

            while (it.hasNext())
                current = it.next()
                split_current = current.split(": ")
                key = HTTP_PREFIX + split_current[0].upcase.gsub(/-/, "_")
                return_value[key] = split_current[1]
            end

            name_and_port = return_value["HTTP_HOST"].split(":")
            return_value["SERVER_NAME"] = name_and_port[0]
            return_value["SERVER_PORT"] = name_and_port[1]

            return_value["rack.version"]    = [1,4,1]
            return_value["rack.url_scheme"] = "http"

            return_value["rack.input"]  = MockInput.new
            return_value["rack.errors"] = MockErrorBuffer.new

            return_value["rack.multithread"]  = true
            return_value["rack.multiprocess"] = true
            return_value["rack.run_once"]     = false

            return_value
        end

        def send_output(clj, writer, status, headers, body)
                
                client_output = convert_output(status, headers)
                clj.write_output(writer, client_output)

                write_body(clj, writer, body)

        end

        def write_body(clj, writer, body)

            if ( Array == body.class )
                body.each do |x|
                    clj.write_output(writer, x.to_s.to_java_bytes)
                end

            else
                body.each do |part|
                    clj.write_output(writer, part.to_java_bytes)
                end
            end

        end

        def translate_status(code)
            case code
            when 100..199 then "Continue"
            when 200..299 then "Success"
            when 300..399 then "Redirected"
            when 400..599 then "Error"
            else                "Who Knows"
            end
        end
        
        def convert_output(status, headers)

            return_value = "HTTP/1.1 " + status.to_s + " " + translate_status(status) + "\n"

            headers.each do | key, value |
                return_value += key + ": " + value + "\r\n"
            end

            return_value += "\r\n"

            return_value.to_java_bytes
        end
    end

    class MockInput
        def gets
            nil
        end

        def read(count=nil, buffer=nil)

            (count && count > 0) ? nil : ""

            #Hardcoded data used for investigating POST problem
            #"user_email=wwarner@8thlight.com"
        end

        def rewind
        end

        def each
        end

        def close
        end
    end

    #This will hold error messages from the Rails app
    class MockErrorBuffer

        def puts
            nil
        end

        def write(string)
            string.size if string
        end

        def flush
            self
        end
    end
end
