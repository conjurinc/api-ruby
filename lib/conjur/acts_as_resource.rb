module Conjur
  module ActsAsResource
    def resource
      require 'conjur/resource'
      # NOTE: should we use specific class to build sub-url below?
      Conjur::Resource.new(Conjur::Authz::API.host, self.options)[[ core_conjur_account, 'resources', path_escape(resource_kind), path_escape(resource_id) ].join('/')]
    end
    
    def resource_kind
      require 'active_support/core_ext'
      self.class.name.split("::")[-1].underscore.split('/').join('-')
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
