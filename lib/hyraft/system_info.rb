# lib/hyraft/system_info.rb
require 'rbconfig'

module Hyraft
  module SystemInfo
    def self.os_name
      host = RbConfig::CONFIG['host_os']
      if host =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        begin
          require 'win32/registry'
          Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Microsoft\Windows NT\CurrentVersion') do |reg|
            reg['ProductName'] # => "Ex. Windows 11 Pro?"
          end
        rescue LoadError
          "Windows (version unknown)"
        end
      elsif host =~ /darwin|mac os/
        "macOS"
      elsif host =~ /linux/
        "Linux"
      else
        host
      end
    end
  end
end
