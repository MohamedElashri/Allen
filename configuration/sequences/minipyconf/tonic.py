###############################################################################
# (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
"""Wrappers for defining functions that can be configured higher up the call stack.

Tonic provides the `@configurable <configurable>` decorator, which allows the
default values of keyword arguments to be overridden from higher up the
callstack with `bind`.

    >>> from PyConf import configurable
    >>> @configurable
    ... def f(a=1):
    ...     return a
    ...
    >>> with f.bind(a=2):
    ...     f()
    ...
    2
    >>> f()
    1

This allows for high-level configuration of behaviour deep within an
application; all that's needed is a reference to the `configurable` function
that one wishes to modify the behaviour of.

The idiomatic way of using tonic is define small, self-contained functions
which construct some object of interest. These functions should call other,
similarly self-contained functions to retrieve any components which are
dependencies. Like this, callers can override the behaviour of any function in
the call stack with `bind <_bind>`. Each function should expose configurable parameters
as keyword arguments.

To help debugging, bindings can be inspected using the `debug` context manager.

    >>> from PyConf import tonic
    >>> with tonic.debug():
    ...     f()
    ...     f(a=3)
    ...     with f.bind(a=2):
    ...         f()
    ...
    Calling @configurable `f` from <module>:2 with non-default parameters: NONE
    1
    Calling @configurable `f` from <module>:3 with non-default parameters:
        a = 3 (given)
    3
    Calling @configurable `f` from <module>:5 with non-default parameters:
        a = 2 (bound)
    2

Functions marked `configurable` can also be substituted entirely with
`substitute`.

    >>> @configurable
    ... def echo(arg=123):
    ...     return arg
    ...
    >>> def echo_constant():
    ...     return 456
    ...
    >>> with echo.substitute(echo_constant):
    ...     echo()
    ...
    456
    >>> echo()
    123

tonic is named for Google's gin configuration framework [1]_ which served as
inspiration.

.. [1] https://github.com/google/gin-config
"""
from __future__ import absolute_import, division, print_function
import os
import inspect
import wrapt
import warnings
from collections import namedtuple
from functools import partial
from traceback import extract_stack
try:
    from itertools import izip
except ImportError:
    # In Python 3, zip already returns an iterator
    izip = zip
from contextlib import contextmanager

__debug = False


def _full_name(x):
    return (x.__module__ or "main") + '.' + x.__name__


def _is_configurable(func):
    """Return True if `func` has been marked `@configurable`."""
    return hasattr(func, "_bound_args_stack")


def _has_bound_args(func):
    """Return True if `func` has bound arguments."""
    return _is_configurable(func) and len(func._bound_args_stack) > 0


def _has_substitution(func):
    """Return True if `func` has been substituted."""
    return _is_configurable(func) and func._substitute is not None


def _bound_bind(configurable, scoped=True):
    """Return a `bind` method that is bound to a configurable.

    If scoped (default), the returned bind method returns a context
    manager. If not scoped, the return value of the method is None.

    Args:
        configurable: `@configurable` function to bind to.
        scoped (bool): If the bind is scoped or global.

    """
    # Record when this configurable was called within a `bind` scope
    configurable._called = False

    try:
        spec = inspect.getfullargspec(configurable)
        spec_kwargs = spec.kwonlyargs
    except AttributeError:
        # Python 2 doesn't have getfullargspec
        spec = inspect.getargspec(configurable)
        spec_kwargs = spec.keywords

    def bind(**kwargs):
        """Bind a value to the parameters of a configurable.

        The changes made to the default argument values implied by
        `.bind(...)` are only valid within the scope that the
        `.bind(...)` call is made. The changes made by `bind` then go
        'out of scope' when leaving the scope.

        Scoping is implemented as a context manager. A warning is raised
        if the `bind` target function is not called within the context.

        Args:
            **kwargs: Parameters and values.

        """
        if _has_substitution(configurable):
            warnings.warn(
                "bind call on {} will have no effect; substituted by {}".
                format(configurable, configurable._substitute))

        bound_args_stack = configurable._bound_args_stack

        if not scoped and bound_args_stack:
            last_scoped = any(a.scoped for a in bound_args_stack[-1].values())
            if last_scoped:
                raise RuntimeError(
                    'Cannot call global_bind after bind ({})'.format(
                        bound_args_stack[-1].values()[0]))

        if scoped:
            # Reset the called flag; will check it later and warn if the
            # function was not called within the `bind` scope
            configurable._called = False
        # Record the stack frame of the `bind` call so we can report it later.
        # Frame 0 is here, 1 is the bind partial, 2 is the bind call itself
        stack_frame = inspect.stack()[2]

        for param_name, param_value in kwargs.items():
            if not spec_kwargs and param_name not in spec.args:
                raise ValueError("{} does not have a parameter '{}'".format(
                    configurable, param_name))
                # TODO how can we do type checking here on `value`?

        # record stack trace to be shown in errors and warnings
        bound_args = {
            k: BoundArgument(v, scoped, [extract_stack()[:-3]])
            for k, v in kwargs.items()
        }

        # TODO can we detect some overriding selectors already here?
        configurable._bound_args_stack.append(bound_args)
        try:
            yield
        finally:
            if scoped:
                configurable._bound_args_stack.pop()
                if not configurable._called:
                    tb = '  File "{}", line {}, in {}\n    {}'.format(
                        stack_frame[1], stack_frame[2], stack_frame[3],
                        stack_frame[4][0] if stack_frame[4] else '')
                    warnings.warn(
                        ('Bound function {} was not called within a bind. '
                         'Stack trace:\n{}'.format(configurable, tb)))

    if scoped:
        return contextmanager(bind)
    else:
        return lambda **kwargs: bind(**kwargs).next()
    # TODO (RM): split context manager case and unscoped bind


def _stack_warn_summary(stack):
    return '{}:{}'.format(os.path.split(stack[-1][0])[1], stack[-1][1])


class BoundArgument(
        namedtuple('BoundArgument', ['value', 'scoped', 'stacks'])):
    def __str__(self):
        locs = map(_stack_warn_summary, self.stacks)
        return '{!r} ({})'.format(self.value, ', '.join(locs))

    def __repr__(self):
        locs = map(_stack_warn_summary, self.stacks)
        return 'BoundArgument(value={!r}, scoped={!r}, stacks=<{}>)'.format(
            self.value, self.scoped, ', '.join(locs))


ForcedArgument = namedtuple('ForcedArgument', ['value'])


def forced(value):
    """Force bind an argument, overriding higher-level binds.

    """
    return ForcedArgument(value)


def _update_bound_args(bound_args, updates, stacklevel):
    """Return updated bound arguments according to the precedence semantics.

    """
    bound_args = bound_args.copy()
    for param, new_value in updates.items():
        is_forced = isinstance(new_value.value, ForcedArgument)
        if is_forced:
            # strip the ForcedArgument wrapper
            new_value = BoundArgument(new_value.value.value, new_value.scoped,
                                      new_value.stacks)

        if param not in bound_args:
            bound_args[param] = new_value
        elif new_value.value != bound_args[param].value:
            bound_arg = BoundArgument(
                new_value.value, new_value.scoped,
                bound_args[param].stacks + new_value.stacks)
            # Higher-level binds take precedence over deeper binds
            verb = 'overridden by forced' if is_forced else 'shadows'
            warnings.warn(
                'multiple matches: higher-level {} {} {}'.format(
                    bound_args[param], verb, new_value),
                stacklevel=stacklevel + 1)
            if is_forced:
                # unless forced("value") is used
                bound_args[param] = bound_arg
    return bound_args


def _bound_parameters(configurable, stacklevel):
    """Return the parameters bound to configurable given the scope stacks."""
    bound_args = {}
    for updates in configurable._bound_args_stack:
        bound_args = _update_bound_args(
            bound_args, updates, stacklevel=stacklevel + 1)
    return bound_args


def bound_parameters(configurable):
    """Return the parameters bound to configurable in the current stack scope."""
    bound_args = _bound_parameters(configurable, stacklevel=2)
    return {k: v.value for k, v in bound_args.items()}


def _bound_substitute(configurable, scoped=True):
    def substitute(func):
        """Substitute the body of the bound configurable with `func`.

        After substitution, any call to the original configurable will be
        replaced with a call to `func`. Scoping is implemented as a context
        manager.

            >>> @configurable
            ... def echo(arg=123):
            ...     return arg
            ...
            >>> def replacement():
            ...     return 456
            ...
            >>> with echo.substitute(replacement):
            ...     print(echo())
            ...
            456

        Calling this on a configurable function that has already been
        substituted will raise a warning, and the original substitution will
        not be overridden.

        To further increase clarity, warnings are also raised if `bind` has
        already been called on the configurable before this method is invoked,
        and if `bind` is called after this method is invoked.

        Raises
        ------
            ValueError: The substitute function `func` is marked `@configurable`.
        """
        if _is_configurable(func):
            raise ValueError(
                "Substitute function should not be marked @configurable")

        if _has_bound_args(configurable):
            warnings.warn(
                "binds of {} will be hidden by substitution with {}".format(
                    configurable, func))

        # Do nothing if the function already has a substitute
        noop = _has_substitution(configurable)
        if noop:
            warnings.warn(
                "Function {0} already has a substitute {0._substitute}".format(
                    configurable))
        else:
            configurable._substitute = func
        yield
        if not noop:
            configurable._substitute = None

    return contextmanager(substitute)


def _configurable_wrapper(wrapped, _, args, kwargs):
    """Wrapper for methods marked `@configurable`."""
    if _has_substitution(wrapped):
        return wrapped._substitute(*args, **kwargs)

    if args:
        try:
            wrapped_args = inspect.getfullargspec(wrapped).args
        except AttributeError:
            wrapped_args = inspect.getargspec(wrapped).args
        if len(args) > len(wrapped_args):
            raise TypeError(
                'too many positional arguments given, expected <{}, gave {}'.
                format(len(wrapped_args), len(args)))
        named_args = dict(zip(wrapped_args, args))
        dupls = set(kwargs).intersection(named_args)
        if dupls:
            raise TypeError('{} got multiple values for {}'.format(
                wrapped, dupls))
        kwargs.update(named_args)

    direct_args = {
        k: BoundArgument(v, True, [extract_stack()[:-2]])
        for k, v in kwargs.items()
    }
    bound_args = _bound_parameters(wrapped, stacklevel=2)
    new_bound_args = _update_bound_args(bound_args, direct_args, stacklevel=2)
    kwargs = {k: v.value for k, v in new_bound_args.items()}

    # Prepare the debugging print-out
    current_frame = inspect.currentframe()
    caller_frame = inspect.getouterframes(current_frame, 2)[1]
    descriptors = []
    for pname in sorted(kwargs.keys()):
        # Show how we arrived at the value we're going to use
        if pname in kwargs:
            if pname in bound_args and kwargs[pname] == bound_args[pname].value:
                # Value was specified with `bind`
                ptype = 'bound'
            else:
                # Value was given at the call site
                ptype = 'given'
        else:
            # Default value is used
            ptype = 'default'
        d = '{} = {} ({})'.format(pname, kwargs[pname], ptype)
        descriptors.append(d)
    params = (
        '\n    ' + '\n    '.join(descriptors)) if descriptors else ' NONE'
    log('Calling @configurable `{func}` from {file}:{line} with non-default parameters:{params}'
        .format(
            func=wrapped.__name__,
            file=caller_frame[3],
            line=caller_frame[2],
            params=params))

    # Set the called flag so it can be used by `bind`
    wrapped._called = True

    return wrapped(**kwargs)


def configurable(wrapped=None):
    """Mark a function as configurable.

    The behaviour of a configurable function can be modified using the bind
    syntax:

        >>> @configurable
        ... def f(a=1):
        ...     return a
        ...
        >>> with f.bind(a=2):
        ...     f()
        ...
        2
        >>> f()
        1
    """
    if wrapped is None:
        # the function to be decorated hasn't been given yet
        # so we just collect the optional keyword arguments.
        return partial(configurable)

    wrapped._bound_args_stack = []
    wrapped.bind = _bound_bind(wrapped)
    wrapped.global_bind = _bound_bind(wrapped, scoped=False)

    wrapped._substitute = None
    wrapped.substitute = _bound_substitute(wrapped)

    return wrapt.FunctionWrapper(
        wrapped=wrapped, wrapper=_configurable_wrapper)


@contextmanager
def debug():
    """Context manager that enables debug messaging from tonic.

        >>> log('A message')  # no print-out
        >>> with debug():
        ...     log('A second message')
        ...
        A second message
    """
    global __debug
    __debug = True
    yield
    __debug = False


def log(msg):
    """Prints a message if the __debug flag is True."""
    if __debug:
        print(msg)
