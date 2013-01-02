Gem::Specification.new do |s|
      s.name        = 'clojerver'
      s.version     = '0.0.0'
      s.date        = '2012-12-27'
      s.summary     = "Links Rails to a Clojure http server"
      s.description = "Implements rack interface"
      s.authors     = ["Will Warner"]
      s.email       = 'wwarner@8thlight.com'
      s.files       = ["lib/clojerver.rb", 
                       "lib/clojure-http/clojure-1.3.0.jar",
                       "lib/clojure-http/clojure-http-1.0.0-SNAPSHOT.jar"]
      s.homepage    = 'http://rubygems.org/gems/clojerver'
end
