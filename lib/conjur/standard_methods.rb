#
# Copyright (C) 2013-2015 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'active_support/dependencies/autoload'
require 'active_support/core_ext'

module Conjur
  module StandardMethods
    
    protected
    
    def standard_create(host, type, id = nil, options = nil)
      log do |logger|
        logger << "Creating #{type}"
        logger << " #{id}" if id
        unless options.blank?
          logger << " with options #{options.inspect}"
        end
      end
      options ||= {}
      options[:id] = id if id
      resp = Conjur::REST.new(host, credentials)[type.to_s.pluralize].post(options)
      "Conjur::#{type.to_s.classify}".constantize.build_from_response(resp, credentials)
    end
    
    def standard_list(host, type, options)
      JSON.parse(Conjur::REST.new(host, credentials)[type.to_s.pluralize]\
                  .get(options)
                ).map do |item|
        # Note that we don't want to fully_escape the ids below -- methods like #layer, #host, etc don't expect
        # ids to be escaped, and will escape them again!.
        if item.is_a? String  # lists w/o details are just list of ids 
          send(type,item)
        else                  # list w/ details consists of hashes
          send(type, item['id']).tap { |obj| obj.attributes=item }
        end
      end
    end
    
    def standard_show(host, type, id)
      "Conjur::#{type.to_s.classify}".constantize.new(host, credentials)[ [type.to_s.pluralize, fully_escape(id)].join('/') ]
    end
  end
end
