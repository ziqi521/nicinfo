# Copyright (C) 2011,2012,2013,2014 American Registry for Internet Numbers
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

require 'nicinfo/appctx'
require 'nicinfo/nicinfo_logger'
require 'nicinfo/utils'
require 'nicinfo/common_json'
require 'nicinfo/data_tree'

module NicInfo

  def NicInfo.display_ds_data json_data, appctx, data_node
    ds_data = DsData.new( appctx ).process( json_data ).display
  end

  # deals with RDAP ds_data structures
  class DsData

    attr_accessor :objectclass, :asEventActors

    def initialize appctx
      @appctx = appctx
      @common = CommonJson.new appctx
      @asEventActors = Array.new
    end

    def process json_data
      @objectclass = json_data
      return self
    end

    def display
      @appctx.logger.start_data_item
      @appctx.logger.data_title "[ DELEGATION SIGNER ]"
      @appctx.logger.terse "Algorithm", NicInfo::get_algorithm( @objectclass )
      @appctx.logger.terse "Digest", @objectclass[ "digest" ]
      @appctx.logger.terse "Digest Type", @objectclass[ "digestType" ]
      @appctx.logger.terse "Key Tag", @objectclass[ "keyTag" ]
      @common.display_events @objectclass
      @common.display_as_events_actors @asEventActors
      @appctx.logger.end_data_item
    end

    def get_cn
      algorithm = NicInfo::DNSSEC_ALGORITHMS[ NicInfo::get_algorithm( @objectclass ) ]
      algorithm = algorithm + " DS Data" if algorithm
      algorithm = "(unidentifiable DS data #{object_id})" if !algorithm
      return algorithm
    end

    def to_node
      node = DataNode.new( get_cn, nil, NicInfo::get_self_link( NicInfo::get_links( @objectclass, @appctx ) ) )
      node.data_type=self.class.name
      return node
    end

  end

end
