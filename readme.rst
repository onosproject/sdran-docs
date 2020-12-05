Documentation Guide
===================

Writing Documentation
---------------------

Docs are generated using :doc:`Sphinx <sphinx:usage/index>`.

Documentation is written in :doc:`reStructuredText
<sphinx:usage/restructuredtext/basics>`, or in :doc:`MyST Markdown <myst:using/syntax>`.

In reStructuredText documents, to create the section hierarchy (mapped in HTML
to ``<h1>`` through ``<h5>``) use the underline characters in this order:
``=``, ``-`` ``"``, ``'``, ``^``.

Referencing other Documentation
-------------------------------

Other Sphinx-built documentation, both ONF and non-ONF can be linked to using
:doc:`Intersphinx <sphinx:usage/extensions/intersphinx>`.

You can see all link targets available on a remote Sphinx's docs by running::

  python -msphinx.ext.intersphinx http://other_docs_site/objects.inv

See this readme document for examples of using Intersphinx.

Building the Docs
------------------

The documentation build process is stored in the ``Makefile``. Building docs
requires Python3 to be installed, and most steps will automatically create
virtualenv (``venv_docs``) which contains the required tools.

Run ``make html`` to generate html documentation in ``_build/html``.

To check the formatting of documentation, run ``make lint``. This will be done
in Jenkins to validate the documentation, so please do this before you create a
patchset.

To check spelling, run ``make spelling``. If there are additional words that
are correctly spelled but not in the dictionary (acronyms, trademarks, etc.)
please add them to the ``dict.txt`` file.   You may also need to
install the ``enchant`` C library using your system's package manager for the
spelling checker to function properly.

Before submitting the docs or to verify the docs in CI workflow, run ``make
test``, which will check lint, spelling, and that links inside the site are not
broken.

Creating new Versions of Docs
-----------------------------

To change the version shown on the built site, change the contents of the
``VERSION`` file. As a part of committing the code in the CI process, the
``VERSION`` should be checked for uniqueness, and if it's a SemVer version,
turned into a git tag.

There is a ``make multiversion`` target which will build all git-tagged
versions and branches published on the remote to ``_build``. This will use a
fork of `sphinx-multiversion
<https://github.com/Holzhaus/sphinx-multiversion>`_ to build multiple versions
for the site.

Creating Graphs and Diagrams
----------------------------

Multiple tools are available to render inline text-based graphs definitions and
diagrams within the documentation. This is preferred over images as it's easier
to change and see changes over time as a diff.

:doc:`Graphviz <sphinx:usage/extensions/graphviz>` supports many standard graph
types.

If you have hand-created charts, prefer to use `diagrams.net/draw.io
<https://diagrams.net>`_ in ``SVG`` format and embed the diagram source in the
image, which will allow it to be edited later.
