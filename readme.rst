.. SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>
..
.. SPDX-License-Identifier: Apache-2.0

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

The documentation build process is stored in the ``Makefile``. Building docs
requires Python3 to be installed, and most steps will automatically create
virtualenv (``venv_docs``) which contains the required tools.

Running ``make html`` will generate HTML formatted documentation in
``_build/html``, which you can view with a web browser.

Before submitting the docs or to verify the docs in CI workflow, run ``make
test``, which will check lint, spelling, and that links inside the site are not
broken. If there are additional words that are correctly spelled but not in the
dictionary (acronyms, trademarks, etc.) please add them to the ``dict.txt``
file.   You may also need to install the ``enchant`` C library using your
system's package manager for the spelling checker to function properly.

Referencing other Documentation sites
-------------------------------------

Other Sphinx-built documentation, both ONF and non-ONF can be linked to using
:doc:`Intersphinx <sphinx:usage/extensions/intersphinx>`.

You can see all link targets available on a remote Sphinx's docs by running::

  python -msphinx.ext.intersphinx http://other_docs_site/objects.inv

See the this document for Intersphinx examples.


Adding Documentation from other Repos
-------------------------------------

Documentation written in other git repos can be included in the documentation
generated with this by performing the following steps:

1. Edit the space-separated list ``OTHER_REPO_DOCS`` in the ``Makefile`` to
   include the name of the other repo. These repos will be checked out into
   ``repos`` and then copied into the main directory with the repo name (this
   is required for the versioning process to work).

2. Add the name of the repo to the ``.gitignore`` file so it won't be checked
   in.

3. Add a line for the repo in ``git_refs`` with the repo name, path, and
   git ref (usually ``master``) to be used.

4. Add the paths to the documentation files in the other repo to the
   ``index.rst`` file.

5. Build the docs with ``make html`` and verify that there aren't any warnings
   and the docs have been added.  If you need to exclude specific files from
   the docs, you should add them to the ``exclude_patterns`` list in
   ``conf.py``.

Creating new versions of Docs
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

If you're adding documentation from other repos and you want to hold to a
specific version, run ``make freeze`` and put the output in the ``git_refs``
file - this will cause that specific commit hash of the other repo to be
checked out when building the docs for a specific version.

Adding Graphs and Diagrams
--------------------------

Multiple tools are available to render inline text-based graphs definitions and
diagrams within the documentation. This is preferred over images as it's easier
to change and see changes over time as a diff.

:doc:`Graphviz <sphinx:usage/extensions/graphviz>` supports many standard graph
types.

If you have hand-created charts, prefer to use `diagrams.net/draw.io
<https://diagrams.net>`_ in ``SVG`` format and embed the diagram source in the
image, which will allow it to be edited later.
