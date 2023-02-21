Documenting Allen
=================

This documentation is written in `reStructuredText`_ and built in to web pages by `Sphinx`_. The source can be found in the `doc`_ directory of the Allen project.


Building the documentation locally
----------------------------------

It is enough to run the following command to get the documentation in ``Allen/doc/_build/html``

.. code-block:: sh

  lb-run --nightly lhcb-head/latest Allen/HEAD make -C doc html
  lb-run --nightly lhcb-head/latest Allen/HEAD make -C doc linkcheck

.. _reStructuredText: https://docutils.sourceforge.io/rst.html
.. _Sphinx: https://www.sphinx-doc.org/en/master/
.. _doc: https://gitlab.cern.ch/lhcb/Allen/-/tree/master/doc
.. _example: https://www.sphinx-doc.org/en/master/usage/extensions/example_google.html#example-google
