# disables annoying ubuntu advertising

from twisted.internet.defer import succeed

class LandscapeLink(object):

    def register(self, sysinfo):
        self._sysinfo = sysinfo

    def run(self):
        return succeed(None)
