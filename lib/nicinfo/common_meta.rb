# Copyright (C) 2018 American Registry for Internet Numbers
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

module NicInfo

  class CommonMeta

    META_DATA_NAME = "nicinfo_metadata"

    SERVICE_OPERATOR = "service_operator"
    REGISTRANT_NAME = "registrant_name"
    REGISTRANT_COUNTRY = "registrant_country"
    ABUSE_EMAIL = "abuse_email"
    REGISTRATION_DATE = "registration_date"
    EXPIRATION_DATE = "expiration_date"
    LAST_CHANGED_DATE = "last_changed_date"

    attr_accessor :meta_data

    def initialize( object_class, entities, appctx )

      @appctx = appctx
      @object_class = object_class
      @meta_data = Hash.new

      self_link = NicInfo.get_self_link( NicInfo.get_links( object_class, appctx ) )
      if self_link
        @meta_data[ SERVICE_OPERATOR ] = /(http|https):\/\/.*\.([^.]+\.[^\/]+)\/[^\/]*\/.*/.match( self_link )[2].downcase
      end

      # TODO if registrant not found, go after adminstrative and technical
      registrant = find_entity_by_role( entities, "registrant" )
      if registrant
        @meta_data[ REGISTRANT_NAME ] = registrant.get_cn
        if registrant.jcard.adrs.length > 0
          c = registrant.jcard.adrs[0].country
          if c
            @meta_data[ REGISTRANT_COUNTRY ] = c
          elsif registrant.jcard.adrs[0].label.length > 0 && !(registrant.jcard.adrs[0].label[-1] =~ /\d/)
            @meta_data[ REGISTRANT_COUNTRY ] = registrant.jcard.adrs[0].label[-1]
          end
        end
      end

      abuse = find_entity_by_role( entities, "abuse" )
      if abuse && abuse.jcard.emails.length > 0
        @meta_data[ ABUSE_EMAIL ] = abuse.jcard.emails[0].addr
      end

      registration_date = find_event_date_by_action( object_class, "registration" )
      @meta_data[ REGISTRATION_DATE ] = registration_date if registration_date

      expiration_date = find_event_date_by_action( object_class, "expiration" )
      @meta_data[ EXPIRATION_DATE ] = expiration_date if expiration_date

      last_changed_date = find_event_date_by_action( object_class, "last changed" )
      @meta_data[ LAST_CHANGED_DATE ] = last_changed_date if last_changed_date

    end

    def inject
      @object_class[ META_DATA_NAME ] = @meta_data
    end

    def find_entity_by_role( entities, role )
      retval = nil
      if entities
        entities.each do |e|
          roles = e.objectclass[ "roles" ]
          if roles && roles.include?( role )
            retval = e
            break
          else
            retval = find_entity_by_role( e.entities, role )
            break if retval
          end
        end
      end
      return retval
    end

    def find_event_date_by_action( object_class, event_action )
      retval = nil
      events = object_class[ "events" ]
      events.each do |event|
        if event[ "eventAction" ] == event_action
          # TODO check spec to see if eventDate is optional for meaning "never expires"
          retval = Time.parse( event[ "eventDate" ] ).rfc2822
        end
      end if events
      return retval
    end

  end

end