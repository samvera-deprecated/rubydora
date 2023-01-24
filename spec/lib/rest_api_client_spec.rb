require 'spec_helper'

describe Rubydora::RestApiClient do

  include Rubydora::FedoraUrlHelpers

  class FakeException < Exception

  end
  class MockRepository
    include Rubydora::RestApiClient

    attr_accessor :config
  end

  describe "exception handling" do

    shared_examples "RestClient error handling" do
      subject {
        mock_repository = MockRepository.new
        mock_repository.config = { :url => 'http://example.org' }

        mock_repository
      }

      it "should replace a RestClient exception with a Rubydora one" do
        Deprecation.stub(:warn)
        subject.stub_chain(:client, :[], :get).and_raise RestClient::InternalServerError.new
        subject.stub_chain(:client, :[], :put).and_raise RestClient::InternalServerError.new
        subject.stub_chain(:client, :[], :delete).and_raise RestClient::InternalServerError.new
        subject.stub_chain(:client, :[], :post).and_raise RestClient::InternalServerError.new
        expect { subject.send(method, :pid => 'fake:pid', :dsid => 'my_dsid') }.to raise_error Rubydora::FedoraInvalidRequest
      end
    end

    [:next_pid, :find_objects, :object, :ingest, :mint_pid_and_ingest, :export, :modify_object, :purge_object, :object_versions, :object_xml, :datastream, :datastreams, :set_datastream_options, :datastream_versions, :datastream_history, :datastream_dissemination, :add_datastream, :modify_datastream, :purge_datastream, :relationships, :add_relationship, :purge_relationship, :dissemination].each do |method|

      class_eval %Q{
    describe "##{method}" do
      it_behaves_like "RestClient error handling"
      let(:method) { '#{method}' }
    end
      }
    end

  end

  let :base_url do
    "http://example.org"
  end

  before(:each) do
    @fedora_user = 'fedoraAdmin'
    @fedora_password = 'fedoraAdmin'
    @mock_repository = MockRepository.new
    @mock_repository.config = { :url => base_url,:user => @fedora_user, :password => @fedora_password}
  end

  it "should create a REST client" do
    client = @mock_repository.client

    client.should be_a_kind_of(RestClient::Resource)
    client.options[:user].should == @fedora_user
  end

  it "should create a REST client with a client certificate" do
    client = @mock_repository.client :ssl_client_cert => OpenSSL::X509::Certificate.new, :ssl_client_key => OpenSSL::PKey::RSA.new

    client.options[:user].should == @fedora_user
    client.options[:ssl_client_cert].should be_a_kind_of(OpenSSL::X509::Certificate)
    client.options[:ssl_client_key].should be_a_kind_of(OpenSSL::PKey::PKey)
  end

  it "should raise an exception if client is called twice with different options" do
    client = @mock_repository.client
    lambda { client.should == @mock_repository.client }.should_not raise_error
    lambda { @mock_repository.client(:timeout => 120) }.should raise_error(ArgumentError)
  end

  it "should call nextPID" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + next_pid_url(:format => 'xml')))
    @mock_repository.next_pid
  end

  it "should find objects" do
    RestClient::Request.should_receive(:execute) do |params|
      params.should have_key(:url)
      params[:url].should =~ /^#{Regexp.escape(base_url + "/" + find_objects_url + "?")}.*query=a/
    end
    @mock_repository.find_objects :query => 'a'
  end

  it "should show object properties" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + object_url('z', :format => 'xml')))
    @mock_repository.object :pid => 'z'
  end

  it "should raise not found exception when retrieving object" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + object_url('z', :format => 'xml'))).and_raise( RestClient::ResourceNotFound)
    lambda {@mock_repository.object(:pid => 'z')}.should raise_error RestClient::ResourceNotFound
  end

  it "ingest" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + new_object_url))
    @mock_repository.ingest
  end

  it "mint_pid_and_ingest" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + new_object_url))
    @mock_repository.ingest
  end

  it "ingest with pid" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + object_url('mypid')))
    @mock_repository.ingest :pid => 'mypid'
  end

  describe "export" do
    it "should work on the happy path" do
      RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + export_object_url('mypid')))
      @mock_repository.export :pid => 'mypid'
    end
    it "should require a pid" do
      lambda { @mock_repository.export }.should raise_error ArgumentError, "Must have a pid"
    end
  end

  it "modify_object" do
    RestClient::Request.should_receive(:execute) do |params|
      params.should have_key(:url)
      params[:url].should =~ /^#{Regexp.escape(base_url + "/" + object_url('mypid'))}.*state=Z/
    end
    @mock_repository.modify_object :pid => 'mypid', :state => 'Z'
  end

  it "purge_object" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + object_url('mypid')))
    @mock_repository.purge_object :pid => 'mypid'
  end

  it "should raise not found exception when purging" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + object_url('mypid'))).and_raise( RestClient::ResourceNotFound)
    lambda {@mock_repository.purge_object(:pid => 'mypid')}.should raise_error RestClient::ResourceNotFound
  end

  it "object_versions" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + object_versions_url('mypid', :format => 'xml')))
    @mock_repository.object_versions :pid => 'mypid'
  end

  it "object_xml" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + object_xml_url('mypid', :format => 'xml')))
    @mock_repository.object_xml :pid => 'mypid'
  end

  context "Loading a list of datastreams" do
    let(:request_options) { { url: base_url + "/" + datastreams_url('mypid',  format: 'xml') } }
    let(:my_logger) { double }

    before do
      @initial_logger = Rubydora.logger
      Rubydora.logger = my_logger
    end

    after { Rubydora.logger = @initial_logger }

    it "calls Fedora with the correct url" do
      RestClient::Request.should_receive(:execute).with(hash_including(request_options))
      my_logger.should_receive(:debug) # squelch message "Loaded datastream list for mypid (time)"
      @mock_repository.datastreams :pid => 'mypid'
    end
  end

  context "Calling datastreams with a dsid" do
    it "warns of deprecated behavior" do
      @mock_repository.should_receive(:datastream).with({ pid: 'mypid', dsid: 'asdf' })
      Deprecation.should_receive(:warn)
      @mock_repository.datastreams :pid => 'mypid', :dsid => 'asdf'
    end
  end

  context "Calling datastream without a dsid" do
    it "warns of deprecated behavior" do
      @mock_repository.should_receive(:datastreams).with({ pid: 'mypid' })
      Deprecation.should_receive(:warn)
      @mock_repository.datastream :pid => 'mypid'
    end
  end

  context "Loading a datastream" do
    let(:request_options) { { url: base_url + "/" + datastream_url('mypid', 'aaa', format: 'xml') } }
    let(:my_logger) { double }

    before do
      @initial_logger = Rubydora.logger
      Rubydora.logger = my_logger
    end

    after { Rubydora.logger = @initial_logger }

    it "datastream" do
      RestClient::Request.should_receive(:execute).with(hash_including(request_options))
      my_logger.should_receive(:debug) # squelch message "Loaded datastream mypid/aaa (time)"
      @mock_repository.datastream :pid => 'mypid', :dsid => 'aaa'
    end

    it "should raise not found exception when getting a datastream" do
      RestClient::Request.should_receive(:execute).with(hash_including(request_options)).and_raise(RestClient::ResourceNotFound)
      lambda {@mock_repository.datastream :pid => 'mypid', :dsid => 'aaa'}.should raise_error RestClient::ResourceNotFound
    end

    it "should raise Unauthorized exception when getting a datastream" do
      RestClient::Request.should_receive(:execute).with(hash_including(request_options)).and_raise(RestClient::Unauthorized)
      my_logger.should_receive(:error).with("Unauthorized at #{base_url + "/" + datastream_url('mypid', 'aaa', :format => 'xml')}")
      lambda {@mock_repository.datastream :pid => 'mypid', :dsid => 'aaa'}.should raise_error RestClient::Unauthorized
    end
  end

  describe "datastream_dissemination" do
    it "works without request headers" do
      RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + datastream_content_url('mypid', 'aaa')))
      @mock_repository.datastream_dissemination :pid => 'mypid', :dsid => 'aaa'
    end
    it "works with request headers" do
      RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + datastream_content_url('mypid', 'aaa'), :headers => {'Bat-Man' => 'Forever'}))
      @mock_repository.datastream_dissemination :pid => 'mypid', :dsid => 'aaa', :headers => {'Bat-Man' => 'Forever'}
    end
  end
  it "should allow http methods besides GET on datastream_dissemination" do
    RestClient::Request.should_receive(:execute).with(hash_including(:method => :head))
    @mock_repository.datastream_dissemination :pid => 'mypid', :dsid => 'aaa', :method => :head
  end
  it "should pass a block to the rest client to process the response in datastream_dissemination" do
    _proc = lambda { |x| x }
    RestClient::Request.should_receive(:execute).with(hash_including(:block_response => _proc))
    @mock_repository.datastream_dissemination :pid => 'mypid', :dsid => 'aaa', &_proc
  end
  it "should raise not found exception when retrieving datastream_dissemination" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + datastream_content_url('mypid', 'aaa'))).and_raise( RestClient::ResourceNotFound)
    lambda {@mock_repository.datastream_dissemination :pid => 'mypid', :dsid => 'aaa'}.should raise_error RestClient::ResourceNotFound
  end

  describe "add_datastream" do
    it "should post to the correct url" do
      RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + datastream_url('mypid', 'aaa')))
      @mock_repository.add_datastream :pid => 'mypid', :dsid => 'aaa'
    end
    describe "when a file is passed" do
      let!(:file) { StringIO.new('test', 'r') } # StringIO is a good stand in for a real File (it has read, rewind and close)
      it "closes the file" do
        RestClient::Request.any_instance.should_receive(:transmit) #stub transmit so that Request.execute can close the file we pass
        @mock_repository.add_datastream :pid => 'mypid', :dsid => 'aaa', :content=>file
        file.should be_closed
      end
      describe "and mimeType is not provided" do
        describe "and file responds to :content_type" do
          it "should set the mimeType to file.content_type" do
            file.stub(:content_type).and_return('image/tiff')
            RestClient::Request.should_receive(:execute).with(hash_including(:headers=>{:multipart=>true, :content_type=>"image/tiff"}))
            @mock_repository.add_datastream :pid => 'mypid', :dsid => 'aaa', :content=>file
          end
        end
        describe "and file responds to :path" do
          it "should should try to discern the mime-type from file.path" do
            file.stub(:path).and_return('foo.tiff')
            RestClient::Request.should_receive(:execute).with(hash_including(:headers=>{:multipart=>true, :content_type=>"image/tiff"}))
            @mock_repository.add_datastream :pid => 'mypid', :dsid => 'aaa', :content=>file
          end
        end
        describe "otherwise" do
          it "should set the mimeType to 'application/octet-stream'" do
            RestClient::Request.should_receive(:execute).with(hash_including(:headers=>{:multipart=>true, :content_type=>"application/octet-stream"}))
            @mock_repository.add_datastream :pid => 'mypid', :dsid => 'aaa', :content=>file
          end
        end
      end
    end
  end

  describe "modify datastream" do
    it "should not set mime-type when it's not provided (and a file is not passed)" do
      RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + datastream_url('mypid', 'aaa')))
      @mock_repository.modify_datastream :pid => 'mypid', :dsid => 'aaa'
    end
    it "should pass the provided mimeType header" do
      RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + datastream_url('mypid', 'aaa', :mimeType => 'application/json')))
      @mock_repository.modify_datastream :pid => 'mypid', :dsid => 'aaa', :mimeType=>'application/json'
    end
    describe "when a file is passed" do
      let!(:file) { StringIO.new('test', 'r') } # StringIO is a good stand it for a real File (it has read, rewind and close)
      it "closes the file" do
        RestClient::Request.any_instance.should_receive(:transmit) #stub transmit so that Request.execute can close the file we pass
        @mock_repository.modify_datastream :pid => 'mypid', :dsid => 'aaa', :content=>file
        file.should be_closed
      end
      describe "and mimeType is not provided" do
        describe "and file responds to :content_type" do
          it "should set the mimeType to file.content_type" do
            file.stub(:content_type).and_return('image/tiff')
            RestClient::Request.should_receive(:execute).with(hash_including(:headers=>{:multipart=>true, :content_type=>"image/tiff"}))
            @mock_repository.modify_datastream :pid => 'mypid', :dsid => 'aaa', :content=>file
          end
        end
        describe "and file responds to :path" do
          it "should should try to discern the mime-type from file.path" do
            file.stub(:path).and_return('foo.tiff')
            RestClient::Request.should_receive(:execute).with(hash_including(:headers=>{:multipart=>true, :content_type=>"image/tiff"}))
            @mock_repository.modify_datastream :pid => 'mypid', :dsid => 'aaa', :content=>file
          end
        end
        describe "otherwise" do
          it "should set the mimeType to 'application/octet-stream'" do
            RestClient::Request.should_receive(:execute).with(hash_including(:headers=>{:multipart=>true, :content_type=>"application/octet-stream"}))
            @mock_repository.modify_datastream :pid => 'mypid', :dsid => 'aaa', :content=>file
          end
        end
      end
    end
  end

  it "purge_datastream" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + datastream_url('mypid', 'aaa')))
    @mock_repository.purge_datastream :pid => 'mypid', :dsid => 'aaa'
  end

  it "set_datastream_options" do
    RestClient::Request.should_receive(:execute) do |params|
      params.should have_key(:url)
      params[:url].should =~ /^#{Regexp.escape(base_url + "/" + datastream_url('mypid', 'aaa') + "?")}.*aparam=true/
    end
    @mock_repository.set_datastream_options :pid => 'mypid', :dsid => 'aaa', :aparam => true
  end

  describe "datastream_versions" do
    it "should be successful" do
      RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + datastream_history_url('mypid', 'aaa', :format=>'xml'))).and_return("expected result")
      @mock_repository.datastream_versions(:pid => 'mypid', :dsid => 'aaa').should == 'expected result'
    end
    it "should not break when fedora doesn't have datastream history" do
      RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + datastream_history_url('mypid', 'aaa', :format=>'xml'))).and_raise(RestClient::ResourceNotFound)
      @mock_repository.datastream_versions(:pid => 'mypid', :dsid => 'aaa').should be_nil
    end
  end

  it "datastream_history" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + datastream_history_url('mypid', 'aaa', :format=>'xml')))
    @mock_repository.datastream_history :pid => 'mypid', :dsid => 'aaa'
  end

  it "relationships" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + object_relationship_url('mypid', :format => 'xml')))
    @mock_repository.relationships :pid => 'mypid'
  end

  it "add_relationship" do
    RestClient::Request.should_receive(:execute) do |params|
      params.should have_key(:url)
      params[:url].should =~ /^#{Regexp.escape(base_url + "/" + new_object_relationship_url('mypid') + "?")}.*subject=z/
    end
    @mock_repository.add_relationship :pid => 'mypid', :subject => 'z'
  end

  it "purge_relationships" do
    RestClient::Request.should_receive(:execute) do |params|
      params.should have_key(:url)
      params[:url].should =~ /^#{Regexp.escape(base_url + "/" + object_relationship_url('mypid') + "?")}.*subject=z/
    end
    @mock_repository.purge_relationship :pid => 'mypid', :subject => 'z'
  end

  it "dissemination" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + dissemination_url('mypid', nil, nil, :format => 'xml')))
    @mock_repository.dissemination :pid => 'mypid'
  end

  it "dissemination" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + dissemination_url('mypid', 'sdef', nil, :format => 'xml')))
    @mock_repository.dissemination :pid => 'mypid', :sdef => 'sdef'
  end

  it "dissemination" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => base_url + "/" + dissemination_url('mypid', 'sdef', 'method')))
    @mock_repository.dissemination :pid => 'mypid', :sdef => 'sdef', :method => 'method'
  end

  it "should pass a block to the rest client to process the response in datastream_dissemination" do
    _proc = lambda { |x| x }
    RestClient::Request.should_receive(:execute).with(hash_including(:block_response => _proc))
    @mock_repository.dissemination :pid => 'mypid', :sdef => 'sdef', :method => 'method', &_proc
  end

end
