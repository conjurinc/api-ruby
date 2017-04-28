#
# Copyright (C) 2017 Conjur Inc
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
require 'conjur/cast'

module Conjur
  class BaseObject
    include Cast
    include QueryString
    include LogSource
    include BuildObject
    
    attr_reader :id, :credentials
    
    def initialize id, credentials
      @id = cast_to_id(id)
      @credentials = credentials
    end

    def as_json options={}
      {
        id: id.to_s
      }
    end

    def account; id.account; end
    def kind; id.kind; end
    def identifier; id.identifier; end
    
    def username
      credentials[:username] or raise "No username found in credentials"
    end
    
    protected

    def core_resource
      RestClient::Resource.new(Conjur.configuration.core_url, credentials)
    end
  end
end
