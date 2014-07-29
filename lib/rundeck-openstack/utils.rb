#
#   Author: Rohith
#   Date: 2014-05-22 11:01:49 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#
module RunDeckOpenstack
  module Utils
    Logger.init

    [:info,:error,:warn,:debug].each do |m|
      define_method m do |*args,&block|
        Logger.send m, *args, &block
      end
    end

    def validate_file filename, writeable = false
      raise ArgumentError, 'you have not specified a file to check'       unless filename
      raise ArgumentError, 'the file %s does not exist'   % [ filename ]  unless File.exists? filename
      raise ArgumentError, 'the file %s is not a file'    % [ filename ]  unless File.file? filename
      raise ArgumentError, 'the file %s is not readable'  % [ filename ]  unless File.readable? filename
      if writable
        raise ArgumentError, "the filename #{filename} is not writable"   unless File.writable? filename
      end
      filename
    end
  end
end
