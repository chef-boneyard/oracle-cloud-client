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
module OracleCloud
  class ImageLists
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def all
      public_imagelists + private_imagelists
    end

    def public_imagelists
      client.http_get(:single, '/imagelist/oracle/public/')['result'].each_with_object([]) do |imagelist, memo|
        memo << OracleCloud::ImageList.new(imagelist)
      end
    end

    def private_imagelists
      # TODO: tracked in PE-47
      []
    end

    def exist?(imagelist_name)
      !all.find { |x| x.name == imagelist_name }.nil?
    end
  end
end
