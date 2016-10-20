# KubeNow documentation
This documentation is hosted by [Read The Docs](https://readthedocs.org/): http://kubenow.readthedocs.io/.

## Build locally
Every time there is a change in the documentation, [Read The Docs](https://readthedocs.org/) will automatically rebuild it and publish it. However, for testing purposes it's good to know how to built it locally.

### Prerequisites
To build the documentation locally you will need [Sphinx](http://www.sphinx-doc.org/), and the RDT theme:

```bash
pip install sphinx sphinx-autobuild
sudo pip install sphinx_rtd_theme
```

### Build via make
To build the documentation please run:

```bash
make html
```

If everithing goes well, the docs will be generated in the `_html` directory

### Build automatically while editing
It is convenient to dynamically build the documentation as changes are made. The following command will start a web server on port ```8000```, that you can use to see changes in the documentation while you are editing it.

```bash
sphinx-autobuild . _html
```

### Troubleshoot

- Sometimes, when building locally, the sidebar doesn't update properly. To fix this, remove manually the `_build` folder.
