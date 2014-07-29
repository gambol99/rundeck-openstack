#
#   Author: Rohith
#   Date: 2014-05-22 11:01:53 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
require 'logger'

module RunDeckOpenstack
  class Logger
    class << self
      attr_accessor :logger
      def init options = {}
        self.logger = ::Logger.new( options[:verbose] )
      end

      def method_missing(m,*args,&block)
        logger.send m, *args, &block if logger.respond_to? m
      end
    end
  end
end
