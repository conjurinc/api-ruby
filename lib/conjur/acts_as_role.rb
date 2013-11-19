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
module Conjur
  module ActsAsRole
    def roleid
      [ core_conjur_account, role_kind, id ].join(':')
    end
    
    def role_kind
      self.class.name.split('::')[-1].underscore
    end
   
    # NOTE: parse_role_id returns tuple of path components 
    # (basically, same components as in 'roleid' plus some prefixes)
    def role
      require 'conjur/role'
      Conjur::Role.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_role_id(self.roleid).join('/')]
    end
    
    # Permit this role to perform a privileged action.
    def can(privilege, resource, options = {})
      require 'conjur/resource'
      Conjur::Resource.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_resource_id(resource).join('/')].permit privilege, self.roleid, options
    end

    # Deny this role from performing perform a privileged action.
    def cannot(privilege, resource, options = {})
      require 'conjur/resource'
      Conjur::Resource.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_resource_id(resource).join('/')].deny privilege, self.roleid
    end
  end
end