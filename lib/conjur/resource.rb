module Conjur
  class Resource < RestClient::Resource
    include Exists
    include HasAttributes
    include PathBased
    
    def identifier
      match_path(3..-1)
    end
    
    def create(options = {})
      log do |logger|
        logger << "Creating resource #{kind}:#{identifier}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self.put(options)
    end

    # Lists roles that have a specified permission on the resource.
    def permitted_roles(permission, options = {})
      JSON.parse RestClient::Resource.new(Conjur::Authz::API.host, self.options)["#{account}/roles/allowed_to/#{permission}/#{path_escape kind}/#{path_escape identifier}"].get(options)
    end
    
    # Changes the owner of a resource
    def give_to(owner, options = {})
      self.put(options.merge(owner: owner))
    end

    def delete(options = {})
      log do |logger|
        logger << "Deleting resource #{kind}:#{identifier}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      super options
    end

    def permit(privilege, role, options = {})
      eachable(privilege).each do |p|
        log do |logger|
          logger << "Permitting #{p} on resource #{kind}:#{identifier} by #{role}"
          unless options.empty?
            logger << " with options #{options.to_json}"
          end
        end
        
        self["?permit&privilege=#{query_escape p}&role=#{query_escape role}"].post(options)
      end
    end
    
    def deny(privilege, role, options = {})
      eachable(privilege).each do |p|
        log do |logger|
          logger << "Denying #{p} on resource #{kind}:#{identifier} by #{role}"
          unless options.empty?
            logger << " with options #{options.to_json}"
          end
        end
        self["?deny&privilege=#{query_escape p}&role=#{query_escape role}"].post(options)
      end
    end

    # True if the logged-in role, or a role specified using the acting-as option, has the
    # specified +privilege+ on this resource.
    def permitted?(privilege, options = {})
      self["?check&privilege=#{query_escape privilege}"].get(options)
      true
    rescue RestClient::ResourceNotFound
      false
    end
    
    protected
    
    def eachable(item)
      item.respond_to?(:each) ? item : [ item ]
    end
  end
end