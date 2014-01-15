#
# Copyright (C) 2013 Conjur Inc
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
require 'rest-client'
require 'json'
require 'base64'

require 'conjur/exists'
require 'conjur/has_attributes'
require 'conjur/has_owner'
require 'conjur/path_based'
require 'conjur/escape'
require 'conjur/log'
require 'conjur/log_source'
require 'conjur/standard_methods'

module Conjur
  class API
    include Escape
    include LogSource
    include StandardMethods
    
    class << self
      # Parse a role id into [ account, 'roles', kind, id ]
      def parse_role_id(id)
        id = id.role if id.respond_to?(:role)
        if id.is_a?(Role)
          [ id.account, 'roles', id.kind, id.identifier ]
        elsif id.respond_to?(:role_kind)
          [ Conjur::Core::API.conjur_account, 'roles', id.role_kind, id.identifier ]
        else
          parse_id id, 'roles'
        end
      end

      # Parse a resource id into [ account, 'resources', kind, id ]
      def parse_resource_id(id)
        id = id.resource if id.respond_to?(:resource)
        if id.is_a?(Resource)
          [ id.account, 'resources', id.kind, id.identifier ]
        elsif id.respond_to?(:resource_kind)
          [ Conjur::Core::API.conjur_account, 'resources', id.resource_kind, id.resource_id ]
        else
          parse_id id, 'resources'
        end
      end
    
      # Converts flat id into path components, with mixed-in "super-kind" 
      #                                     (not that kind which is part of id)
      # NOTE: name is a bit confusing, as result of 'parse' is just recombined
      #       representation of parts, not an object of higher abstraction level
      def parse_id(id, kind)
        # Structured IDs (hashes) are no more supported
        raise "Unexpected class #{id.class} for #{id}" unless id.is_a?(String)
        paths = path_escape(id).split(':')
        if paths.size < 2
          raise "Expecting at least two tokens in #{id}"
        elsif paths.size == 2
          paths.unshift Conjur::Core::API.conjur_account
        end
        # I would strongly recommend to encapsulate this into object 
        [ paths[0], kind, paths[1], paths[2..-1].join(':') ]
      end

      def new_from_key(username, api_key)
        self.new username, api_key, nil
      end

      def new_from_token(token)
        self.new nil, nil, token
      end
    end
    
    def initialize username, api_key, token
      @username = username
      @api_key = api_key
      @token = token

      raise "Expecting ( username and api_key ) or token" unless ( username && api_key ) || token
    end
    
    attr_reader :api_key, :username
    
    def username
      @username || @token['data']
    end
    
    def host
      self.class.host
    end
    
    def token
      if @token.nil? or refresh_token?(@token)
        Conjur.log << "refreshing aging token" if @token && Conjur.log
        @token = Conjur::API.authenticate @username, @api_key
      end
      @token
    end
    
    def token_time_field token, field
      case t = token[field]
        when nil then nil
        when Time then t
        else Time.parse t
      end
    end
    private :token_time_field
    
    def refresh_token? token
      return true if token.nil?
      
      if token.kind_of?(String)
        token = JSON.parse token
      end
      
      timestamp, expiration = %w(timestamp expiration).map{|k| token_time_field(token, k)}
      expiration ||= timestamp + 8 * 60
      
      expiration - Time.now.utc < 60
    end
    private :refresh_token?
    
    
    # Authenticate the username and api_key to obtain a request token.
    # Tokens are cached by username for a short period of time.
    def credentials
      { headers: { authorization: "Token token=\"#{Base64.strict_encode64 token.to_json}\"" }, username: username }
    end
  end
end