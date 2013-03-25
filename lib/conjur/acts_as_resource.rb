module Conjur
  module ActsAsResource
    def resource
      require 'conjur/resource'
      Conjur::Resource.new(Conjur::Authz::API.host, self.options)[[ Conjur.account, 'resources', path_escape(resource_kind), path_escape(resource_id) ].join('/')]
    end
    
    def resource_kind
      self.class.name.split("::")[1..-1].join('-').downcase
    end

    def resource_id
      id
    end

    def delete
      resource.delete
      super
    end
  end
end