# -*- coding: binary -*-

require 'msf/core/payload/uuid/options'

##
# This module contains helper functions for creating the transport
# configuration stubs that are used for Meterpreter payloads.
##
module Msf::Payload::TransportConfig

  include Msf::Payload::UUID::Options

  def transport_config_reverse_tcp(opts={})
    ds = opts[:datastore] || datastore
    config = transport_config_bind_tcp(opts)
    config[:lhost] = ds['LHOST']
    config
  end

  def transport_config_reverse_ipv6_tcp(opts={})
    ds = opts[:datastore] || datastore
    config = transport_config_reverse_tcp(opts)
    config[:scheme] = 'tcp6'
    config[:scope_id] = ds['SCOPEID']
    config
  end

  def transport_config_bind_tcp(opts={})
    ds = opts[:datastore] || datastore
    {
      scheme: 'tcp',
      lhost:  ds['LHOST'],
      lport:  ds['LPORT'].to_i
    }.merge(timeout_config(opts))
  end

  def transport_config_reverse_https(opts={})
    ds = opts[:datastore] || datastore
    config = transport_config_reverse_http(opts)
    config[:scheme] = ds['OverrideScheme'] || 'https'
    config[:ssl_cert_hash] = get_ssl_cert_hash(ds['StagerVerifySSLCert'],
                                               ds['HandlerSSLCert'])
    config
  end

  def transport_config_reverse_http(opts={})
    # most cases we'll have a URI already, but in case we don't
    # we should ask for a connect to happen given that this is
    # going up as part of the stage.
    uri = opts[:uri]
    unless uri
      type = opts[:stageless] == true ? :init_connect : :connect
      sum = uri_checksum_lookup(type)
      uri = luri + generate_uri_uuid(sum, opts[:uuid])
    end

    ds = opts[:datastore] || datastore
    {
      scheme:      ds['OverrideScheme'] || 'http',
      lhost:       opts[:lhost] || ds['LHOST'],
      lport:       (opts[:lport] || ds['LPORT']).to_i,
      uri:         uri,
      ua:          ds['MeterpreterUserAgent'],
      proxy_host:  ds['PayloadProxyHost'],
      proxy_port:  ds['PayloadProxyPort'],
      proxy_type:  ds['PayloadProxyType'],
      proxy_user:  ds['PayloadProxyUser'],
      proxy_pass:  ds['PayloadProxyPass']
    }.merge(timeout_config(opts))
  end

  def transport_config_reverse_named_pipe(opts={})
    ds = opts[:datastore] || datastore
    {
      scheme: 'pipe',
      lhost:  ds[:pipe_host] || ds['PIPEHOST'],
      uri:    "/#{ds[:pipe_host] || ds['PIPENAME']}"
    }.merge(timeout_config(opts))
  end

private

  def timeout_config(opts={})
    ds = opts[:datastore] || datastore
    {
      comm_timeout: (ds[:comm_timeout] || ds['SessionCommunicationTimeout']).to_i,
      retry_total:  (ds[:retry_total] || ds['SessionRetryTotal']).to_i,
      retry_wait:   (ds[:retry_wait] || ds['SessionRetryWait']).to_i
    }
  end

end
