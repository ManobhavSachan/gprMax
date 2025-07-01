****
FAQs
****

This section provides answers to frequently asked questions about gprMax and its uses. You should also check out our `YouTube channel <https://www.youtube.com/@Gprmax>`_ which contains screencasts and videos that explain how to install gprMax, demonstrate some of its key features, and give example models showing applications.

**What applications can gprMax simulate?**
gprMax is electromagnetic wave simulation software that is based on the Finite-Difference Time-Domain (FDTD) method. Many of its features have been designed to benefit simulating Ground Penetrating Radar (GPR), however, it can be used to simulate many other applications in areas such as engineering, geophysics, archaeology, and medicine.

**Why does gprMax not have a GUI?**
We considered developing a CAD-based graphical user interface (GUI) but, for now, decided against it. There were two guiding principals behind this design decision: firstly, users most often perform a series of related simulations with varying parameters to solve or optimize a particular problem; and secondly, we decided the limited resources we had were best concentrated on developing advanced modelling features for GPR within software that could easily be interfaced with other tools. Although a CAD-based GUI is useful for creating single simulations it becomes increasingly cumbersome for a series of simulations or where simulations contain heterogeneities, e.g. a model of a soil with stochastically varying electrical properties.

**How is gprMax licensed?**
gprMax is released under the `GNU General Public License v3 or higher <http://www.gnu.org/copyleft/gpl.html>`_. This means when distributing derived works, the source code of the work must be made available under the same license.

**Where does the name gprMax come from?**
The name gprMax comes from the joining of the acronym for Ground Penetrating Radar - **gpr** - and the name of the Scottish scientist who formulated the classical theory of electromagnetic radiation, `James Clerk Maxwell <https://en.wikipedia.org/wiki/James_Clerk_Maxwell>`_ - **Max**.

**Do I need to learn Python to use gprMax?**
No, you can use gprMax purely through commands in your input. However, gprMax also has a Python API which can be used to create more complex simulations and scripting.

**Can I still do all my pre/post-processing for gprMax in MATLAB?**
Yes, `MATLAB has built-in functions to read HDF5 files <http://uk.mathworks.com/help/matlab/high-level-functions.html>`_.

**Can I convert my output file to a text file, e.g. to import it into Microsoft Excel**
Yes, we recommend you download `HDFView <https://support.hdfgroup.org/products/java/hdfview/>`_ which is a free viewer for HDF files. You can then export any of the datasets in the output file to a text (ASCII) file that can be imported into Microsoft Excel. To do so right-click on the dataset in HDFView and choose Export Dataset -> Export Data to Text File.

**How do I choose a spatial resolution for my simulation?**
Spatial resolution should be chosen to mitigate numerical dispersion and to adequately resolve geometry in your simulation. :ref:`A 2D example of modelling a metal cylinder in a dielectric <example-2D-Ascan>` provides guidance on how to determine spatial resolution.

**I specified a certain piece of geometry but I don’t see it when I view my geometry file.**
gprMax builds objects in a model in the order the objects were specified in the input file, using a layered canvas approach. This means, for example, a cylinder object which comes after a box object in the input file will overwrite the properties of the box object at any locations where they overlap. This approach allows complex geometries to be created using basic object building blocks.

**Can I run gprMax on my HPC/cluster?**
Yes. gprMax has been parallelised using hybrid MPI + OpenMP and also features a task farm based on MPI. For more information read the :ref:`HPC <hpc>` section.
