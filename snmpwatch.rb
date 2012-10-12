#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'snmp'
require 'pg'

def die msg
    puts 'FATAL ERROR: ' << msg
    exit 1
end

class Msg
    def initialize quiet
	@quiet = quiet
    end

    def say what
	puts "[status] " << what if not @quiet
    end

    def err wtf
	puts "[error] " << wtf if not @quiet
    end
end

def getOID manager, item
    if item =~ /^.+::.+\[.+\]$/
	args = item.split( /[\[|\]|\,]+/ ).each { |e| e.gsub! "\"", "" }
	ifTable_columns = [ args[ 2 ], "if" << args[ 1 ].capitalize! ]
	oid = nil
	manager.walk ifTable_columns do |row|
	    oid = args[ 0 ] << "." << row[ 1 ].value.to_s if row[ 0 ].value == args[ 3 ]
	end
	oid
    else
	item
    end
end

def getValue manager, oid
    begin
	manager.get_value oid
    rescue
	nil
    end
end

def main
    options = {}

    optparse = OptionParser.new do |opts|
	opts.banner = "Usage: #{$0} [options]"

	options[ :host ] = nil
	opts.on( '-H', '--host HOST', 'Database host' ) do |host|
	    options[ :host ] = host
	end

	options[ :user ] = nil
	opts.on( '-U', '--user USER', 'Database username' ) do |user|
	    options[ :user ] = user
	end

	options[ :dbname ] = nil
	opts.on( '-D', '--database NAME', 'Database name' ) do |dbname|
	    options[ :dbname ] = dbname
	end

	options[ :password ] = nil
	opts.on( '-P', '--password PASS', 'Database user password' ) do |password|
	    options[ :password ] = password
	end

#	options[ :overflow ] = 18446744073709551613
#	options[ :overflow ] = 500 * 2**30#536870912000
	options[ :overflow ] = 112500000000
	opts.on( '-O', '--overflow VALUE', 'Value considered as overflow' ) do |ovr|
	    options[ :overflow ] = ovr
	end

	options[ :quiet ] = false
	opts.on( '-q', '--quiet', 'Do not print any processing infomation' ) do
	    options[ :quiet ] = true
	end

	opts.on( '-h', '--help', 'Display this screen' ) do
	    puts opts
	    exit
	end
    end

    optparse.parse!

    msg = Msg.new options[ :quiet ]

    msg.say "connecting to database..."
    begin
	conn = PGconn.open :user => options[ :user ], :dbname => options[ :dbname ], :password => options[ :password ], :host => options[ :host ]
    rescue PGError => e
	die "could not connect to database - #{e.to_s.gsub!( 'FATAL:', '' ).strip }"
    end
    msg.say "success"

    msg.say "receiving list of watched items..."
    begin
	res = conn.exec "select id, useip, dns, ip, snmp_community, snmp_oid from sandbox.watched_items w join hosts h on w.hostid = h.hostid join items i on w.itemid = i.itemid;"
    rescue
	die "database query failed"
    end
    msg.say "success"

    msg.say "iterating thought the list of watched items..."
    pairs = {}
    res.each do |row|
	begin
	    msg.say "retrieving info from #{row[ 'ip' ]}, #{row[ 'dns' ]}, #{row[ 'snmp_community' ]}"
	    SNMP::Manager.open :Host => row[ 'useip' ] == 1 ? row[ 'ip' ] : row[ 'dns' ], :Community => row[ 'snmp_community' ] do |manager|
		if oid = getOID( manager, row[ 'snmp_oid' ] )
#		puts oid
		    if val = getValue( manager, oid )
#		puts val
			pairs[ row[ 'id' ] ] = val
		    end
		end
	    end
	rescue
	    msg.err "error during polling item"
	end
    end
    msg.say "iterating done"

    msg.say "items received, storing them to database..."
    pairs.each do |id, value|
	begin
	    msg.say "trying to store as a new day record"
	    res = conn.exec "select current from sandbox.history where dt = current_date - 1 and watchedid = #{id};"
	    value = value.to_i

	    accum = 0

	    if res.num_tuples == 1
		last = res[ 0 ][ 'current' ].to_i
		tmp = value - last
		if tmp < 0
		    tmp = 2**64 - tmp.abs
		end
		accum = tmp if tmp < options[ :overflow ].to_i
	    end

	    conn.exec "insert into sandbox.history( watchedid, current, accumulate ) values( #{id}, #{value}, #{accum} );"
	rescue
	    value = value.to_i
	    msg.say "failed. such record is already exists. trying to update existing record..."
	    begin
		res = conn.exec "select accumulate, current from sandbox.history where watchedid = #{id} and dt = current_date;"

		if res.num_tuples == 1
		    current = res[ 0 ][ 'current' ].to_i
		    accumulate = res[ 0 ][ 'accumulate' ].to_i
		    tmp = value - current.to_i
		    if tmp < 0
			tmp = 2**64 - tmp.abs
		    end
		    if tmp < options[ :overflow ].to_i
			accumulate += tmp
		    end
		    conn.exec "update sandbox.history set accumulate = #{accumulate}, current = #{value} where watchedid = #{id} and dt = current_date;"
		    msg.say "success"
		end
	    rescue
		msg.err "failed to update record. something going wrong."
	    end
	end
    end
    msg.say "all items processed. have a nice day."
    conn.close
end

#ifTable_columns = ["ifIndex", "ifDescr", "ifInOctets", "ifOutOctets"]
#ifTable_columns = [ "ifIndex", "ifDescr", "ifHCInOctets" ]

#    item = "IF-MIB::ifHCInOctets[\"index\",\"ifDescr\",\"ae0.2\"]"

#    res.each do |hash|
#	item = hash[ 'snmp_oid' ]
#	if oid = getOID( manager, item )
#	    puts oid
#	    if val = getValue( manager, oid )
#		puts val
#	    end
#	end
#    end

#    args = item.split( /[\[|\]|\,]+/ ).each { |e| e.gsub! "\"", "" }
#    ifTable_columns = [ args[ 2 ], "if" << args[ 1 ].capitalize! ]

#    manager.walk ifTable_columns do |row|
#	args[ 0 ] << "." << row[ 1 ].value.to_s if row[ 0 ].value == args[ 3 ]
#    end

#    puts args[ 0 ]
#	puts getOID manager, item
#    end
#end

if __FILE__ == $0
    main
end
