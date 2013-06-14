require 'spec_helper'
require 'standard_methods_helper'

describe Conjur::API, api: :dummy do
  describe '::enroll_host' do
    it "uses Net::HTTP to get something" do
      response = double "response",
          code: '200', body: 'foobar'
      response.stub(:[]).with('Content-Type').and_return 'text/whatever'

      url = URI.parse "http://example.com"
      Net::HTTP.stub(:get_response).with(url).and_return response

      Conjur::API.enroll_host("http://example.com").should == ['text/whatever', 'foobar']
    end
  end

  describe '#create_host' do
    it_should_behave_like "standard_create with", :host, nil, :options do
      let(:invoke) { subject.create_host :options }
    end
  end

  describe '#host' do
    it_should_behave_like "standard_show with", :host, :id do
      let(:invoke) { subject.host :id }
    end
  end
end
