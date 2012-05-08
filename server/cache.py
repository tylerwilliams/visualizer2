import time
import socket
import logging
import hashlib
import functools

import pymemc

logger = logging.getLogger(__name__)

_cAcHe = None

class Cache(object):
    def __init__(self, connection_string="localhost:11211"):
        try:
            prev_to = socket.getdefaulttimeout()
            socket.setdefaulttimeout(1)
            self.client = pymemc.Client(connection_string)
            socket.setdefaulttimeout(prev_to)
        except (socket.timeout, socket.error):
            self.client = None

    def get_hash(self, *args, **kwargs):
        """
            get a unique hash for the provided args
            and kwargs
        """
        hashval = hashlib.md5()
        for arg in sorted(args):
            hashval.update(str(arg))
        for key in sorted(kwargs.iterkeys()):
            hashval.update(str(kwargs[key]))
        return hashval.hexdigest()+"_"

    def set_values(self, some_dict, *args, **kwargs):
        """
            store the key/value pairs from some_dict
            in memcache. prefix the keys with a hash
            of *args + **kwargs if they are provided
        """
        
        prefix = self.get_hash(args, kwargs)
        if not self.client:
            return some_dict.keys()

        send_d = {}
        key_map = {}
        for key in some_dict.iterkeys():
            newkey = prefix + key
            key_map[newkey] = key
            send_d[newkey] = some_dict[key]
        rval = self.client.set_multi(send_d)
        return [key_map[unset_key] for unset_key in rval]

    def get_values(self, keylist, *args, **kwargs):
        """
            get the key/value pairs from some_dict
            in memcache. prefix the keys with a hash
            of *args + **kwargs if they are provided
        """
        if not self.client:
            return []

        prefix = self.get_hash(args, kwargs)
        key_map = {}
        for key in keylist:
            newkey = prefix + key
            key_map[newkey] = key

        rval = self.client.get_multi(key_map.iterkeys())
        for prefixed_key in rval.keys()[:]:
            key = key_map[prefixed_key]
            rval[key] = rval.pop(prefixed_key)
        return rval

    def delete_values(self, keylist, *args, **kwargs):
        """
            delete the key/value pairs from some_dict
            in memcache. prefix the keys with a hash
            of *args + **kwargs if they are provided
        """
        if not self.client:
            return []

        prefix = self.get_hash(args, kwargs)
        key_map = {}
        for key in keylist:
            newkey = prefix + key
            key_map[newkey] = key

        rval = self.client.delete_multi(key_map.iterkeys())

        for prefixed_key in rval.iterkeys():
            key = key_map[prefixed_key]
            rval[key] = rval.pop(prefixed_key)
        return rval

def mc(connection_string="localhost:11211"):
    global _cAcHe
    if _cAcHe is None:
        _cAcHe = Cache(connection_string)
    return _cAcHe

def instance_memoize(timeout):
    """
        instance method decorator
    """
    def decorator(fn):
        @functools.wraps(fn)
        def wrapper(self, *args, **kwargs):
            argnames = fn.func_code.co_varnames[:fn.func_code.co_argcount]
            fname = fn.func_name
            fstr = "%s(%s)" % (fname, ', '.join( '%s=%r' % entry for entry in zip(argnames,args) + kwargs.items()))
            rval = mc().get_values([fname], id(self), *args, **kwargs)
            if rval:
                logger.debug("took %2.2f to %s (CACHE HIT)", 0, fstr)
                return rval
            sval = fn(self, *args, **kwargs)
            mc().set_values({fname:sval}, id(self), *args, **kwargs)
            logger.debug("took %2.2f to %s (CACHE MISS)", 0, fstr)
            return sval
        return wrapper
    return decorator

def memoize(timeout):
    """
        function decorator
    """
    def decorator(fn):
        @functools.wraps(fn)
        def wrapper(*args, **kwargs):
            start_tic = time.time()
            argnames = fn.func_code.co_varnames[:fn.func_code.co_argcount]
            fname = fn.func_name
            fstr = "%s(%s)" % (fname, ', '.join( '%s=%r' % entry for entry in zip(argnames,args) + kwargs.items()))
            rval = mc().get_values([fname], *args, **kwargs)
            if rval:
                logger.debug("took %2.2fms to %s (CACHE HIT)", (time.time()-start_tic)*1000, fstr)
                return rval
            sval = fn(*args, **kwargs)
            mc().set_values({fname:sval}, *args, **kwargs)
            logger.debug("took %2.2fms to %s (CACHE MISS)", (time.time()-start_tic)*1000, fstr)
            return sval
        return wrapper
    return decorator

