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

require 'spec_helper'
require 'rspec'
require 'pp'
require_relative '../lib/nicinfo/bulkip_infile'

describe 'bulk_infile test' do

  # TODO test when the strategy can't find ip or date column

  it 'should guess ips' do
    b = NicInfo::BulkIPInFile.new( nil )

    strategy = b.guess_ip( "127.0.0.1" )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 0 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey

    s = "2018-02-03 00:00:00,336 DEBUG rws[0:0:0:0:0:0:0:1] => [http://localhost:8080/whoisrws/seam/resource/rest/nets;q=153.92.0.2?showDetails=true&showARIN=false&showNonArinTopLevelNet=false&ext=netref2]"
    strategy = b.guess_ip( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn]  ).to eq( 3 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_truthy

    s = "2018-02-03 00:00:00,529 DEBUG whois 101.127.230.241 => [n = + 66.249.95.255]"
    strategy = b.guess_ip( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 4 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey

    s = "2018-02-03 00:00:00,723 DEBUG whois 2a01:7e00:0:0:f03c:91ff:fec8:5dd9 => [n 83.233.57.115]"
    strategy = b.guess_ip( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 4 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey

    s = '108.45.120.114 - - [03/Feb/2018:05:31:26 -0500] "GET /registry/ip/172.217.8.3 HTTP/1.1" 200 5383 "-" "Python-urllib/3.5"'
    strategy = b.guess_ip( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 0 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey

    s = '2001:500:31::7 - - [03/Feb/2018:05:31:26 -0500] "GET /registry/entity/ARIN HTTP/1.1" 200 4261 "-" "-"'
    strategy = b.guess_ip( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 0 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey

    s = '67.109.163.226 - - [03/Feb/2018:05:31:26 -0500] "GET /registry/ip/fe80::988c:94ff:a381:2ba7 HTTP/1.1" 404 574 "-" "NicInfo v.1.1.1"'
    strategy = b.guess_ip( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 0 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey

    s = '2001:4898:80e8:a::342 - - [03/Feb/2018:05:31:57 -0500] "GET /rest/org/RIPE HTTP/1.1" 200 1418 "-" "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.16299.98"'
    strategy = b.guess_ip( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 0 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey

    s = '112.64.210.132 - - [03/Feb/2018:05:31:57 -0500] "GET /rest/nets;q=37.175.146.1?showDetails=true&showARIN=true HTTP/1.1" 200 2112 "-" "Python-urllib/2.7"'
    strategy = b.guess_ip( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 0 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey

  end

  it 'should guess time' do
    b = NicInfo::BulkIPInFile.new( nil )

    s = "2018-02-03 00:00:00,336 DEBUG rws[0:0:0:0:0:0:0:1] => [http://localhost:8080/whoisrws/seam/resource/rest/nets;q=153.92.0.2?showDetails=true&showARIN=false&showNonArinTopLevelNet=false&ext=netref2]"
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeRubyType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 0 )

    s = "2018-02-03-00:00:00,529 DEBUG whois 101.127.230.241 => [n = + 66.249.95.255]"
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeRubyType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 0 )

    s = "DEBUG whois 101.127.230.241 => [n = + 66.249.95.255] 2018-02-03-00:00:00,529"
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeRubyType )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 7 )

    s = "DEBUG whois 101.127.230.241 => [n = + 66.249.95.255] [2018-02-03-00:00:00,529]"
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeRubyType )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 7 )

    s = "[2018-02-03 00:00:00,336] DEBUG rws[0:0:0:0:0:0:0:1] => [http://localhost:8080/whoisrws/seam/resource/rest/nets;q=153.92.0.2?showDetails=true&showARIN=false&showNonArinTopLevelNet=false&ext=netref2]"
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeRubyType )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 0 )

    s = "[2018-02-03-00:00:00,529] DEBUG whois 101.127.230.241 => [n = + 66.249.95.255]"
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeRubyType )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 0 )

    s = '108.45.120.114 - - [03/Feb/2018:05:31:26 -0500] "GET /registry/ip/172.217.8.3 HTTP/1.1" 200 5383 "-" "Python-urllib/3.5"'
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_truthy
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = '2001:500:31::7 - - [03/Feb/2018:05:31:26 -0500] "GET /registry/entity/ARIN HTTP/1.1" 200 4261 "-" "-"'
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_truthy
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = '108.45.120.114 - - 03/Feb/2018:05:31:26 -0500 "GET /registry/ip/172.217.8.3 HTTP/1.1" 200 5383 "-" "Python-urllib/3.5"'
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = '2001:500:31::7 - - 03/Feb/2018:05:31:26 -0500 "GET /registry/entity/ARIN HTTP/1.1" 200 4261 "-" "-"'
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = '108.45.120.114 - - [03/Feb/2018:05:31:26] "GET /registry/ip/172.217.8.3 HTTP/1.1" 200 5383 "-" "Python-urllib/3.5"'
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheNoTZType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_truthy
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = '2001:500:31::7 - - [03/Feb/2018:05:31:26] "GET /registry/entity/ARIN HTTP/1.1" 200 4261 "-" "-"'
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheNoTZType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_truthy
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = '108.45.120.114 - - 03/Feb/2018:05:31:26 "GET /registry/ip/172.217.8.3 HTTP/1.1" 200 5383 "-" "Python-urllib/3.5"'
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheNoTZType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = '2001:500:31::7 - - 03/Feb/2018:05:31:26 "GET /registry/entity/ARIN HTTP/1.1" 200 4261 "-" "-"'
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheNoTZType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = "DEBUG rws[0:0:0:0:0:0:0:1] => [http://localhost:8080/whoisrws/seam/resource/rest/nets;q=153.92.0.2?showDetails=true&showARIN=false&showNonArinTopLevelNet=false&ext=netref2]"
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeNoneType )

    s = "DEBUG whois 101.127.230.241 => [n = + 66.249.95.255]"
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeNoneType )

    s = '108.45.120.114 - - "GET /registry/ip/172.217.8.3 HTTP/1.1" 200 5383 "-" "Python-urllib/3.5"'
    strategy = b.guess_time( s )
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeNoneType )
  end

  it 'should guess lines' do
    b = NicInfo::BulkIPInFile.new( nil )

    s = "2018-02-03 00:00:00,336 DEBUG rws[0:0:0:0:0:0:0:1] => [http://localhost:8080/whoisrws/seam/resource/rest/nets;q=153.92.0.2?showDetails=true&showARIN=false&showNonArinTopLevelNet=false&ext=netref2]"
    strategy = b.guess_line( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn]  ).to eq( 3 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_truthy
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeRubyType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 0 )

    s = "2018-02-03 00:00:00,529 DEBUG whois 101.127.230.241 => [n = + 66.249.95.255]"
    strategy = b.guess_line( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 4 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeRubyType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 0 )

    s = "2018-02-03 00:00:00,723 DEBUG whois 2a01:7e00:0:0:f03c:91ff:fec8:5dd9 => [n 83.233.57.115]"
    strategy = b.guess_line( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 4 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeRubyType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 0 )

    s = '108.45.120.114 - - [03/Feb/2018:05:31:26 -0500] "GET /registry/ip/172.217.8.3 HTTP/1.1" 200 5383 "-" "Python-urllib/3.5"'
    strategy = b.guess_line( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 0 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_truthy
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = '2001:500:31::7 - - [03/Feb/2018:05:31:26 -0500] "GET /registry/entity/ARIN HTTP/1.1" 200 4261 "-" "-"'
    strategy = b.guess_line( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 0 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_truthy
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = '67.109.163.226 - - [03/Feb/2018:05:31:26 -0500] "GET /registry/ip/fe80::988c:94ff:a381:2ba7 HTTP/1.1" 404 574 "-" "NicInfo v.1.1.1"'
    strategy = b.guess_line( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 0 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_truthy
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = '2001:4898:80e8:a::342 - - [03/Feb/2018:05:31:57 -0500] "GET /rest/org/RIPE HTTP/1.1" 200 1418 "-" "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.16299.98"'
    strategy = b.guess_line( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 0 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_truthy
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

    s = '112.64.210.132 - - [03/Feb/2018:05:31:57 -0500] "GET /rest/nets;q=37.175.146.1?showDetails=true&showARIN=true HTTP/1.1" 200 2112 "-" "Python-urllib/2.7"'
    strategy = b.guess_line( s )
    expect( strategy[NicInfo::BulkIPInFile::IpColumn] ).to eq( 0 )
    expect( strategy[NicInfo::BulkIPInFile::StripIp] ).to be_falsey
    expect( strategy[NicInfo::BulkIPInFile::DateTimeType]  ).to eq( NicInfo::BulkIPInFile::DateTimeApacheType )
    expect( strategy[NicInfo::BulkIPInFile::StripDateTime] ).to be_truthy
    expect( strategy[NicInfo::BulkIPInFile::DateTimeColumn] ).to eq( 3 )

  end

  it 'should have strategies' do

    b = NicInfo::BulkIPInFile.new( "spec/bulkip/ex1.log" )
    expect( b.has_strategy ).to be_truthy

    b = NicInfo::BulkIPInFile.new( "spec/bulkip/ex2.log" )
    expect( b.has_strategy ).to be_truthy

    b = NicInfo::BulkIPInFile.new( "spec/bulkip/ex3.log" )
    expect( b.has_strategy ).to be_truthy

    b = NicInfo::BulkIPInFile.new( "spec/bulkip/ex4.log" )
    expect( b.has_strategy ).to be_truthy
  end

  it 'should iterate ex1.log' do
    b = NicInfo::BulkIPInFile.new( "spec/bulkip/ex1.log" )
    i=0
    b.foreach do |ip,time|
      case i
        when 0
          expect( ip ).to eq( "139.226.146.173" )
          expect( time ).to eq( Time.parse( "2018-02-04 10:00:00,005") )
        when 1
          expect( ip ).to eq( "2a02:d8:0:0:250:56ff:fe95:ca7e" )
          expect( time ).to eq( Time.parse( "2018-02-04 00:00:00,112") )
        when 22
          expect( ip ).to eq( "112.65.5.56" )
          expect( time ).to eq( Time.parse( "2018-02-04 02:10:03,495") )
      end
      i=i+1
    end
  end

  it 'should iterate ex2.log' do
    b = NicInfo::BulkIPInFile.new( "spec/bulkip/ex2.log" )
    i=0
    b.foreach do |ip,time|
      case i
        when 0
          expect( ip ).to eq( "35.165.55.47" )
          expect( time ).to eq( Time.strptime( "04/Feb/2018:06:02:15 -0500", NicInfo::BulkIPInFile::ApacheTimeFormat ) )
        when 3
          expect( ip ).to eq( "2607:5300:60:6cd::1" )
          expect( time ).to eq( Time.strptime( "04/Feb/2018:06:01:51 -0500", NicInfo::BulkIPInFile::ApacheTimeFormat ) )
        when 24
          expect( ip ).to eq( "2001:500:13::7" )
          expect( time ).to eq( Time.strptime( "04/Feb/2018:06:02:06 -0500", NicInfo::BulkIPInFile::ApacheTimeFormat ) )
      end
      i=i+1
    end
  end

  it 'should iterate ex3.log' do
    b = NicInfo::BulkIPInFile.new( "spec/bulkip/ex3.log" )
    i=0
    b.foreach do |ip,time|
      case i
        when 0
          expect( ip ).to eq( "0:0:0:0:0:0:0:1" )
          expect( time ).to eq( Time.parse( "2018-02-04 00:00:00,006") )
        when 1
          expect( ip ).to eq( "0:0:0:0:0:0:0:1" )
          expect( time ).to eq( Time.parse( "2018-02-04 00:00:00,012") )
        when 25
          expect( ip ).to eq( "0:0:0:0:0:0:0:1" )
          expect( time ).to eq( Time.parse( "2018-02-04 00:00:00,431") )
      end
      i=i+1
    end
  end

  it 'should iterate ex4.log' do
    b = NicInfo::BulkIPInFile.new( "spec/bulkip/ex4.log" )
    i=0
    b.foreach do |ip,time|
      case i
        when 0
          expect( ip ).to eq( "58.244.2.230" )
          expect( time ).to eq( Time.strptime( "04/Feb/2018:06:01:49 -0500", NicInfo::BulkIPInFile::ApacheTimeFormat ) )
        when 1
          expect( ip ).to eq( "2001:500:13::7" )
          expect( time ).to eq( Time.strptime( "04/Feb/2018:06:01:56 -0500", NicInfo::BulkIPInFile::ApacheTimeFormat ) )
        when 23
          expect( ip ).to eq( "61.181.2.38" )
          expect( time ).to eq( Time.strptime( "04/Feb/2018:06:02:06 -0500", NicInfo::BulkIPInFile::ApacheTimeFormat ) )
      end
      i=i+1
    end
  end

end
