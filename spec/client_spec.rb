#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'spec_helper'

shared_examples_for 'an http caller' do |method, *args|
  let(:response) { '{"foo": "bar"}' }
  before do
    allow(client).to receive(:authenticate!)
    allow(RestClient::Request).to receive(:execute).and_return(response)
  end

  it 'authenticates the client when it is not yet authenticated' do
    allow(client).to receive(:authenticated?).and_return(false)
    expect(client).to receive(:authenticate!)
    expect(1).to eq(2)

    client.send(method, *args)
  end

  it 'does not authenticate the client when it is already authenticated' do
    allow(client).to receive(:authenticated?).and_return(true)
    expect(client).not_to receive(:authenticate!)

    client.send(method, *args)
  end

  it 'calls raise_http_exception if rest-client raises an exception' do
    allow(RestClient::Request).to receive(:execute).and_raise(RestClient::Exception)
    expect(client).to receive(:raise_http_exception)
    client.send(method, *args)
  end

  it 'parses the returned JSON and returns it to the caller' do
    expect(FFI_Yajl::Parser).to receive(:parse).with(response).and_return('foo' => 'bar')
    expect(client.send(method, *args)['foo']).to eq('bar')
  end
end

describe OracleCloud::Client do
  let(:client_opts) do
    {
      api_url: 'https://testcloud.oracle.com',
      identity_domain: 'testdomain',
      username: 'myuser',
      password: 'mypassword'
    }
  end
  let(:client) { described_class.new(client_opts) }

  describe '#initialize' do
    let(:client) { OracleCloud::Client.allocate }
    it 'validates the client options for public cloud' do
      expect(client).to receive(:validate_client_options!)
      client.send(:initialize, client_opts)
    end
  end

  describe '#validate_client_options!' do
    it 'raises an exception when username is missing' do
      opts = client_opts.dup
      opts[:username] = nil
      expect { described_class.new(opts) }.to raise_error(ArgumentError)
    end

    it 'raises an exception when password is missing' do
      opts = client_opts.dup
      opts[:password] = nil
      expect { described_class.new(opts) }.to raise_error(ArgumentError)
    end

    it 'raises an exception when identity domain is missing' do
      opts = client_opts.dup
      opts[:identity_domain] = nil
      expect { described_class.new(opts) }.to raise_error(ArgumentError)
    end

    it 'raises an exception when API URL is missing' do
      opts = client_opts.dup
      opts[:api_url] = nil
      expect { described_class.new(opts) }.to raise_error(ArgumentError)
    end

    it 'raises an error when the API URL is not a URI' do
      allow(client).to receive(:valid_uri?).and_return(false)
      expect { client.validate_client_options! }.to raise_error(ArgumentError)
    end
  end

  describe '#valid_uri' do
    let(:uri) { double('uri') }
    before do
      allow(client).to receive(:validate_client_options!)
      allow(URI).to receive(:parse).and_return(uri)
    end

    it 'returns true if the uri is a URI::HTTP' do
      allow(uri).to receive(:is_a?).with(URI::HTTP).and_return(true)
      expect(client.valid_uri?('test')).to eq(true)
    end

    it 'returns false if the uri is not a URI::HTTP' do
      allow(uri).to receive(:is_a?).with(URI::HTTP).and_return(false)
      expect(client.valid_uri?('test')).to eq(false)
    end

    it 'returns false if a URI::InvalidURIError exception is raised' do
      allow(uri).to receive(:is_a?).with(URI::HTTP).and_raise(URI::InvalidURIError)
      expect(client.valid_uri?('test')).to eq(false)
    end
  end

  describe '#username_with_domain' do
    it 'returns the correct concatenation of identity domain and user' do
      allow(client).to receive(:full_identity_domain).and_return('test')
      expect(client.username_with_domain).to eq('test/myuser')
    end
  end

  describe '#full_identity_domain' do
    it 'returns the correct concatenation of compute and identity domain for public compute' do
      expect(client.full_identity_domain).to eq('Compute-testdomain')
    end
    it 'returns the raw identity_domain for private compute' do
      allow(client).to receive(:private_cloud?).and_return(true)
      expect(client.full_identity_domain).to eq('testdomain')
    end
  end

  describe '#authenticate!' do
    let(:headers)  { { set_cookie: 'unprocessed_auth_cookie' } }
    let(:response) { double('response', headers: headers) }
    before do
      allow(RestClient::Request).to receive(:execute).and_return(response)
      allow(client).to receive(:process_auth_cookies).and_return('auth_cookie')
    end

    it 'posts to the authenticate endpoint' do
      allow(client).to receive(:full_url).with('/authenticate/').and_return('full_url')
      allow(client).to receive(:request_headers).and_return('request_headers')
      allow(client).to receive(:authenticate_payload).and_return(foo: 'bar')

      expect(RestClient::Request).to receive(:execute).with(method: :post,
                                                            url: 'full_url',
                                                            headers: 'request_headers',
                                                            payload: '{"foo":"bar"}',
                                                            verify_ssl: true)
      client.authenticate!
    end

    it 'processes the auth cookie and sets it in the instance variable' do
      expect(client).to receive(:process_auth_cookies).with('unprocessed_auth_cookie').and_return('auth_cookie')
      client.authenticate!
      expect(client.instance_variable_get(:@cookie)).to eq('auth_cookie')
    end

    it 'calls raise_http_exception if a RestClient exception is raised' do
      allow(RestClient::Request).to receive(:execute).and_raise(RestClient::Exception)
      expect(client).to receive(:raise_http_exception)

      client.authenticate!
    end
  end

  describe '#authenticated?' do
    it 'returns true if the cookie is set' do
      client.instance_variable_set(:@cookie, 'some value')
      expect(client.authenticated?).to eq(true)
    end

    it 'returns false if the cookie is not set' do
      expect(client.authenticated?).to eq(false)
    end
  end

  describe '#request_headers' do
    context 'when using default parameters' do
      it 'sets a default Accept header' do
        expect(client.request_headers['Accept']).to eq('application/oracle-compute-v3+json')
      end
    end

    context 'when the request type is a directory request' do
      it 'sets a directory Accept header' do
        expect(client.request_headers(type: :directory)['Accept']).to eq('application/oracle-compute-v3+directory+json')
      end
    end

    context 'when a cookie does not exist' do
      it 'does not include a cookie header' do
        expect(client.request_headers.key?('Cookie')).to eq(false)
      end
    end

    context 'when a cookie exists' do
      it 'includes a cookie header with the correct value' do
        client.instance_variable_set(:@cookie, 'some value')
        expect(client.request_headers['Cookie']).to eq('some value')
      end
    end
  end

  describe '#authenticate_payload' do
    it 'contains a user and password key with correct values' do
      allow(client).to receive(:username_with_domain).and_return('domain/user')
      expect(client.authenticate_payload['user']).to eq('domain/user')
      expect(client.authenticate_payload['password']).to eq('mypassword')
    end
  end

  describe '#full_url' do
    it 'returns the correctly concatenated API URL and path' do
      expect(client.full_url('/testpath')).to eq('https://testcloud.oracle.com/testpath')
    end
  end

  describe '#process_auth_cookies' do
    context 'when a valid cookie exists' do
      let(:cookies) { [ 'nimbula=some_value; Path=/ Max-Age=1800 ', 'anothercookie=anothervalue' ] }
      it 'returns the cookie stripped of the path and max-age' do
        expect(client.process_auth_cookies(cookies)).to eq('nimbula=some_value;')
      end
    end

    context 'when no valid cookie exists' do
      let(:cookies) { [ 'cookie=value', 'anothercookie=anothervalue' ] }
      it 'raises an exception' do
        expect { client.process_auth_cookies(cookies) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#asset_get' do
    it 'formats the url and calls http_get' do
      expect(client).to receive(:url_with_identity_domain).with('asset_type', '/testpath').and_return('url')
      expect(client).to receive(:http_get).with('req_type', 'url')

      client.asset_get('req_type', 'asset_type', '/testpath')
    end
  end

  describe '#asset_put' do
    it 'formats the url and calls http_post' do
      expect(client).to receive(:url_with_identity_domain).with('asset_type', '/testpath').and_return('url')
      expect(client).to receive(:http_put).with('url', 'test payload')

      client.asset_put('asset_type', '/testpath', 'test payload')
    end
  end

  describe '#asset_delete' do
    it 'formats the url and calls http_delete' do
      expect(client).to receive(:url_with_identity_domain).with('asset_type', '/testpath').and_return('url')
      expect(client).to receive(:http_delete).with('url')

      client.asset_delete('asset_type', '/testpath')
    end
  end

  describe '#single_item' do
    it 'calls asset_get with a request type of single' do
      expect(client).to receive(:asset_get).with(:single, 'asset_type', '/testpath')
      client.single_item('asset_type', '/testpath')
    end
  end

  describe '#directory' do
    it 'calls asset_get with a request type of directory' do
      expect(client).to receive(:asset_get).with(:directory, 'asset_type', '/testpath')
      client.directory('asset_type', '/testpath')
    end
  end

  describe '#url_with_identity_domain' do
    it 'returns a properly concatenated string' do
      allow(client).to receive(:full_identity_domain).and_return('foo')
      expect(client.url_with_identity_domain('test_type', 'test_path')).to eq('/test_type/foo/test_path')
    end
  end

  describe '#http_get' do
    it_behaves_like 'an http caller', :http_get, 'request_type', 'url'

    it 'calls rest-client' do
      allow(client).to receive(:authenticate!)
      allow(client).to receive(:full_url).with('/testpath').and_return('url')
      allow(client).to receive(:request_headers).with(type: :single).and_return('headers')
      expect(RestClient::Request).to receive(:execute).with(method: :get,
                                                            url: 'url',
                                                            headers: 'headers',
                                                            verify_ssl: true)
        .and_return('{}')
      client.http_get(:single, '/testpath')
    end
  end

  describe '#http_post' do
    it_behaves_like 'an http caller', :http_post, 'url', 'test payload'

    it 'calls rest-client' do
      allow(client).to receive(:authenticate!)
      allow(client).to receive(:full_url).with('/testpath').and_return('url')
      allow(client).to receive(:request_headers).and_return('headers')
      expect(RestClient::Request).to receive(:execute).with(method: :post,
                                                            url: 'url',
                                                            headers: 'headers',
                                                            payload: 'test payload',
                                                            verify_ssl: true)
        .and_return('{}')
      client.http_post('/testpath', 'test payload')
    end
  end

  describe '#http_put' do
    it_behaves_like 'an http caller', :http_put, 'url', 'test payload'

    it 'calls rest-client' do
      allow(client).to receive(:authenticate!)
      allow(client).to receive(:full_url).with('/testpath').and_return('url')
      allow(client).to receive(:request_headers).and_return('headers')
      expect(RestClient::Request).to receive(:execute).with(method: :put,
                                                            url: 'url',
                                                            headers: 'headers',
                                                            payload: 'test payload',
                                                            verify_ssl: true)
        .and_return('{}')
      client.http_put('/testpath', 'test payload')
    end
  end

  describe '#http_delete' do
    it_behaves_like 'an http caller', :http_delete, 'url'

    it 'calls rest-client' do
      allow(client).to receive(:authenticate!)
      allow(client).to receive(:full_url).with('/testpath').and_return('url')
      allow(client).to receive(:request_headers).and_return('headers')
      expect(RestClient::Request).to receive(:execute).with(method: :delete,
                                                            url: 'url',
                                                            headers: 'headers',
                                                            verify_ssl: true)
        .and_return('{}')
      client.http_delete('/testpath')
    end
  end

  describe '#raise_http_exception' do
    let(:path) { '/testpath' }

    context 'when a non-HTTP exception is raised' do
      let(:exception) { RuntimeError.new }
      it 're-raises the exception' do
        expect { client.raise_http_exception(exception, path) }.to raise_error(RuntimeError)
      end
    end

    context 'when an HTTP exception is raised' do
      let(:response) { '{"message": "a bad thing happened"}' }

      let(:exception) do
        double('HTTPException',
               http_code: 400,
               response: response
              )
      end

      it 'raises an OracleCloud HTTPError exception' do
        expect { client.raise_http_exception(exception, path) }.to raise_error(OracleCloud::Exception::HTTPError)
      end

      it 'contains methods with correct info' do
        begin
          client.raise_http_exception(exception, path)
        rescue => e # rubocop:disable Lint/HandleExceptions
        end

        expect(e.code).to eq(400)
        expect(e.body).to eq('{"message": "a bad thing happened"}')
        expect(e.error).to eq('a bad thing happened')
        expect(e.path).to eq(path)
      end
    end

    context 'when a non-JSON response is received' do
      let(:response) { 123 }

      let(:exception) do
        double('HTTPException',
               http_code: 400,
               response: response
              )
      end

      it 'sets the error to the exact response body as a string' do
        begin
          client.raise_http_exception(exception, path)
        rescue => e
          expect(e.error).to eq('123')
        end
      end
    end

    context 'when a 404 is received' do
      let(:response) { '{"message": "a bad thing happened"}' }

      let(:exception) do
        double('HTTPException',
               http_code: 404,
               response: response
              )
      end

      it 'raises a HTTPNotFound exception' do
        expect { client.raise_http_exception(exception, path) }.to raise_error(OracleCloud::Exception::HTTPNotFound)
      end
    end
  end
end
