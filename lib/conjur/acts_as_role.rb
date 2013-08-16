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
  end
end
