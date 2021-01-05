from collections.abc import Iterable
from collections import defaultdict
from collections import OrderedDict
from functools import lru_cache

memoizing = lru_cache(1000)

def to_tuple(a: dict):
    return tuple((k,v) for k,v in a.items())


def flatten(trav):
    if isinstance(trav, Iterable):
        return [a for i in trav for a in flatten(i)]
    else:
        return [trav]


def uniqueify(x: str, already_there=defaultdict(int)):
    out = x + f"#{already_there[x]}"
    already_there[x] += 1
    return out
