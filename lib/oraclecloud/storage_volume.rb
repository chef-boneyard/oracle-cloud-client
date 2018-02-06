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
  class StorageVolume 

attr_reader :results

def initialize(results)
  @results = results
end

def full_name
  results['name']
end

 def name
  results['name'].rpartition('/').last
end

def size
  results['size']
end

    def properties
  results['properties'][0]
end

def status
  results['status']
end

  def imagelist
  results['imagelist']
end

def description
  results['description']
end

  end
end
