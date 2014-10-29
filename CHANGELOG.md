# v.4.10.2
* Authn token is refetched before the expiration
* Support for configuration `sticky` option is discarded
* Resource#exists? refactored -- no overloading, code from exists.rb used
* Tests use Rspec v3 and reset configuration between test cases


# v.4.10.1 
* Resource#exists? returns true if access to resource is forbidden
* Thread-local configuration for working with different endpoints