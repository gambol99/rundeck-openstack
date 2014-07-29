#
#
#   Author: Rohith
#   Date: 2014-07-29 21:05:44 +0100 (Tue, 29 Jul 2014)
#
#  vim:ts=4:sw=4:et
#
module RunDeckOpenstack
  module Cache
    def cached key, &block
      if cache.has_key? key
        cache[key]
      else
        cache[key] = yield
      end
    end

    def cache
      @cache ||= {}
    end
  end
end
