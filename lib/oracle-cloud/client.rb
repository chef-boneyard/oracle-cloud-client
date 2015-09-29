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

require 'ffi_yajl'
require 'rest-client'

module OracleCloud
  class Client
    attr_reader :identity_domain, :password, :username

    def initialize(opts)
      @api_url         = opts[:api_url]
      @identity_domain = opts[:identity_domain]
      @username        = opts[:username]
      @password        = opts[:password]
      @verify_ssl      = opts.fetch(:verify_ssl, true)
      @cookie          = nil

      validate_client_options!
    end

    #################################
    #
    # methods to other API objects
    #

    def imagelists
      OracleCloud::ImageLists.new(self)
    end

    def instance_request(*args)
      OracleCloud::InstanceRequest.new(self, *args)
    end

    def instances
      OracleCloud::Instances.new(self)
    end

    def ip_associations
      OracleCloud::IPAssociations.new(self)
    end

    def orchestrations
      OracleCloud::Orchestrations.new(self)
    end

    def shapes
      OracleCloud::Shapes.new(self)
    end

    def sshkeys
      OracleCloud::SSHKeys.new(self)
    end

    #################################
    #
    # client methods
    #

    def validate_client_options!
      raise ArgumentError, 'Username, password and identity_domain are required' if
        @username.nil? || @password.nil? || @identity_domain.nil?
      raise ArgumentError, 'An API URL is required' if @api_url.nil?
      raise ArgumentError, "API URL #{@api_url} is not a valid URI." unless valid_uri?(@api_url)
    end

    def valid_uri?(uri)
      uri = URI.parse(uri)
      uri.is_a?(URI::HTTP)
    rescue URI::InvalidURIError
      false
    end

    def username_with_domain
      compute_identity_domain + '/' + @username
    end

    def compute_identity_domain
      'Compute-' + @identity_domain
    end

    def authenticate!
      path = '/authenticate/'
      response = RestClient::Request.execute(method: :post,
                                             url: full_url(path),
                                             headers: request_headers,
                                             payload: authenticate_payload.to_json,
                                             verify_ssl: @verify_ssl)

    rescue => e
      raise_http_exception(e, path)
    else
      @cookie = process_auth_cookies(response.headers[:set_cookie])
    end

    def authenticated?
      ! @cookie.nil?
    end

    def request_headers(opts={})
      headers = { 'Content-Type' => 'application/oracle-compute-v3+json' }

      if opts[:type] == :directory
        headers['Accept'] = 'application/oracle-compute-v3+directory+json'
      else
        headers['Accept'] = 'application/oracle-compute-v3+json'
      end

      headers['Cookie'] = @cookie if @cookie
      headers
    end

    def authenticate_payload
      {
        'user'     => username_with_domain,
        'password' => @password
      }
    end

    def full_url(path)
      @api_url + path
    end

    def process_auth_cookies(cookies)
      cookie = cookies.find { |c| c.start_with?('nimbula=') }
      raise 'No nimbula auth cookie received in authentication request' if cookie.nil?

      cookie.gsub!(/ Path=.* Max-Age=.*$/, '')
      cookie
    end

    def asset_get(request_type, asset_type, path)
      url = url_with_identity_domain(asset_type, path)
      http_get(request_type, url)
    end

    def asset_put(asset_type, path, payload=nil)
      url = url_with_identity_domain(asset_type, path)
      http_put(url, payload)
    end

    def asset_delete(asset_type, path)
      url = url_with_identity_domain(asset_type, path)
      http_delete(url)
    end

    def single_item(asset_type, path)
      asset_get(:single, asset_type, path)
    end

    def directory(asset_type, path)
      asset_get(:directory, asset_type, path)
    end

    def url_with_identity_domain(type, path='')
      '/' + type + '/' + compute_identity_domain + '/' + path
    end

    def http_get(request_type, url)
      authenticate! unless authenticated?

      response = RestClient::Request.execute(method: :get,
                                             url: full_url(url),
                                             headers: request_headers(type: request_type),
                                             verify_ssl: @verify_ssl)
    rescue => e
      raise_http_exception(e, url)
    else
      FFI_Yajl::Parser.parse(response)
    end

    def http_post(path, payload)
      authenticate! unless authenticated?
      response = RestClient::Request.execute(method: :post,
                                             url: full_url(path),
                                             headers: request_headers,
                                             payload: payload,
                                             verify_ssl: @verify_ssl)
    rescue => e
      raise_http_exception(e, path)
    else
      FFI_Yajl::Parser.parse(response)
    end

    def http_put(path, payload=nil)
      authenticate! unless authenticated?
      response = RestClient::Request.execute(method: :put,
                                             url: full_url(path),
                                             headers: request_headers,
                                             payload: payload,
                                             verify_ssl: @verify_ssl)
    rescue => e
      raise_http_exception(e, path)
    else
      FFI_Yajl::Parser.parse(response)
    end

    def http_delete(path)
      authenticate! unless authenticated?
      response = RestClient::Request.execute(method: :delete,
                                             url: full_url(path),
                                             headers: request_headers,
                                             verify_ssl: @verify_ssl)
    rescue => e
      raise_http_exception(e, path)
    else
      FFI_Yajl::Parser.parse(response)
    end

    def raise_http_exception(caught_exception, path)
      raise unless caught_exception.respond_to?(:http_code)

      if caught_exception.http_code == 404
        klass = OracleCloud::Exception::HTTPNotFound
      else
        klass = OracleCloud::Exception::HTTPError
      end

      begin
        error_body = FFI_Yajl::Parser.parse(caught_exception.response)
      rescue
        error_body = { 'message' => caught_exception.response }
      end

      exception = klass.new(code: caught_exception.http_code,
                            body: caught_exception.response,
                            klass: caught_exception.class,
                            error: error_body['message'].to_s,
                            path: path)

      message = exception.error.empty? ? caught_exception.message : exception.error
      raise exception, message
    end
  end
end
